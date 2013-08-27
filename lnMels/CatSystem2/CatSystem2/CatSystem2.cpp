#include<Windows.h>
#include<string>
using namespace std;
HANDLE g_hHeap;
#define OVERLOAD_NEW
#include "\masm32\lneditor\SDK\C++\plugin.h"

#include "cs.h"

HINSTANCE g_hInstance;


void WINAPI InitInfo(LPMEL_INFO2 lpMelInfo)
{
	lpMelInfo->dwInterfaceVersion=INTERFACE_VERSION;
	lpMelInfo->dwCharacteristic=0;
}

void WINAPI PreProc(LPPRE_DATA lpPreData)
{
	g_hHeap=lpPreData->hGlobalHeap;
}

int WINAPI Match(LPCWSTR lpszName)
{
	int len=lstrlenW(lpszName);
	if(lstrcmpiW(lpszName+len-4,L".cst")==0)
	{
		HANDLE hFile=CreateFile(lpszName,GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
		if(hFile==INVALID_HANDLE_VALUE)
			return MR_ERR;
		DWORD dwMagic[2],nRead;
		BOOL bRet=ReadFile(hFile,dwMagic,8,&nRead,0);
		CloseHandle(hFile);
		if(!bRet)
			return MR_ERR;
		if(memcmp(dwMagic,"CatScene",8)==0)
			return MR_YES;
	}
	return MR_NO;
}

MRESULT WINAPI GetText(LPFILE_INFO lpFileInfo, LPDWORD lpdwRInfo)
{
	LPCS_ORIG_HDR origHdr=(LPCS_ORIG_HDR)lpFileInfo->lpStream;
	if(memcmp(origHdr->dwMagic,"CatScene",8)!=0)
		return E_WRONGFORMAT;
	BYTE* uncomprScene=new BYTE[origHdr->uncomprLen*3];
	if(!uncomprScene)
		return E_NOMEM;
	lpFileInfo->lpCustom=uncomprScene;

	DWORD uncLen=origHdr->uncomprLen;
	int ret=_ZlibUncompress(uncomprScene,&uncLen,origHdr+1,origHdr->comprLen);
	if(ret)
		return E_WRONGFORMAT;

	LPCS_HDR csHdr=(LPCS_HDR)uncomprScene;
	uncomprScene+=sizeof(CS_HDR);
	int strCount=(csHdr->rsrcOffset-csHdr->offTableOffset)/4;
	LPSTREAM_ENTRY pStream=(LPSTREAM_ENTRY)VirtualAlloc(0,strCount*sizeof(STREAM_ENTRY),MEM_COMMIT,PAGE_READWRITE);
	if(!pStream)
		return E_NOMEM;
	lpFileInfo->lpStreamIndex=pStream;

	DWORD* poff=(DWORD*)(uncomprScene+csHdr->offTableOffset);
	BYTE* pres=(uncomprScene+csHdr->rsrcOffset);

	int nLine=0;
	for(int i=0;i<strCount;i++)
	{
		BYTE* p=pres+poff[i];
		if(*p++!=1)
			__asm int 3
		BYTE type=*p++;
		switch(type)
		{
		case 2:
			break;
		case 0x20:
		case 0x21:
			pStream->lpStart=p;
			pStream++;
			nLine++;
			break;
		case 0x30:
			if(memcmp(p,"select",6)==0 || memcmp(p,"fselect",7)==0)
			{
				while(TRUE)
				{
					if(i+1>=strCount)
						break;
					p=pres+poff[i+1];
					if(*p!=1 || *(p+1)!=0x30 || (*(p+2)<'0' || *(p+2)>'9'))
						break;

					//选项的id与tag跳过
					//while(*p++!=' ')
					//	if(*p==0) __asm int 3;
					//while(*p++!=' ')
					//	if(*p==0) __asm int 3;

					pStream->lpStart=p+2;
					pStream++;
					nLine++;
					i++;
				}
			}
			break;
		default:
			__asm int 3
		}
	}

	lpFileInfo->dwMemoryType=MT_POINTERONLY;
	lpFileInfo->dwStringType=ST_ENDWITHZERO;
	lpFileInfo->nLine=nLine;
	*lpdwRInfo=RI_SUC_LINEONLY;

	return E_SUCCESS;
}

MRESULT WINAPI ModifyLine(LPFILE_INFO lpFileInfo, DWORD nLine)
{
	LPCS_HDR csHdr=(LPCS_HDR)lpFileInfo->lpCustom;
	BYTE* uncomprScene=(BYTE*)(csHdr+1);

	wchar_t* newStr2=lpFileInfo->lpTextIndex[nLine];
	DWORD newLen=WideCharToMultiByte(lpFileInfo->dwCharSet,0,newStr2,-1,0,0,0,0);
	char* newStr=new char[newLen];
	if(!newStr)
		return E_NOMEM;

	WideCharToMultiByte(lpFileInfo->dwCharSet,0,newStr2,-1,newStr,newLen,0,0);

	char* oldStr=(char*)lpFileInfo->lpStreamIndex[nLine].lpStart;
	DWORD oldLen=lstrlenA(oldStr)+1;

	if(newLen<=oldLen)
	{
		memcpy(oldStr,newStr,newLen);
	}
	else
	{
		DWORD* poff=(DWORD*)(uncomprScene+csHdr->offTableOffset);
		BYTE* pres=uncomprScene+csHdr->rsrcOffset;
		BYTE* presend=uncomprScene+csHdr->sceneLen;
		*(WORD*)presend=*(WORD*)(oldStr-2);
		memcpy(presend+2,newStr,newLen);
		poff[nLine]=presend-pres;
		csHdr->sceneLen+=newLen+2;

	}
	delete[] newStr;

	return E_SUCCESS;
}

MRESULT WINAPI SaveText(LPFILE_INFO lpFileInfo)
{
	CS_ORIG_HDR origHdr;
	LPCS_HDR csHdr=(LPCS_HDR)lpFileInfo->lpCustom;
	memcpy(origHdr.dwMagic,"CatScene",8);
	origHdr.comprLen=origHdr.uncomprLen=csHdr->sceneLen+sizeof(CS_HDR);
	BYTE* buff=new BYTE[origHdr.uncomprLen];
	if(!buff)
		return E_NOMEM;
	int ret=_ZlibCompress(buff,&origHdr.comprLen,csHdr,origHdr.uncomprLen);
	if(ret)
		return E_ERROR;

	DWORD nRead;
	SetFilePointer(lpFileInfo->hFile,0,0,FILE_BEGIN);
	ret=WriteFile(lpFileInfo->hFile,&origHdr,sizeof(origHdr),&nRead,0);
	ret&=WriteFile(lpFileInfo->hFile,buff,origHdr.comprLen,&nRead,0);
	delete[] buff;
	if(!ret)
		return E_FILEWRITEERROR;
	return E_SUCCESS;
}

MRESULT WINAPI Release(LPFILE_INFO lpFileInfo)
{
	if(lpFileInfo->lpCustom)
		delete[] lpFileInfo->lpCustom;
	return E_SUCCESS;
}