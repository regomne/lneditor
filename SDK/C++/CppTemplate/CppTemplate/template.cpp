#include<Windows.h>

HANDLE g_hHeap;
#define OVERLOAD_NEW
#include "\masm32\lneditor\SDK\C++\plugin.h"

#include"xuse.h"

HINSTANCE g_hInstance;


void WINAPI InitInfo(LPMEL_INFO lpMelInfo)
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
	if(lstrcmpiW(lpszName+len-4,L".bin")==0)
	{
		HANDLE hFile=CreateFile(lpszName,GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
		if(hFile==INVALID_HANDLE_VALUE)
			return MR_ERR;
		DWORD dwMagic,nRead;
		BOOL bRet=ReadFile(hFile,&dwMagic,4,&nRead,0);
		CloseHandle(hFile);
		if(!bRet)
			return MR_ERR;
		if(dwMagic=='IRON')
			return MR_YES;
	}
	return MR_NO;
}

MRESULT WINAPI GetText(LPFILE_INFO lpFileInfo, LPDWORD lpdwRInfo)
{
	XuseHdr* hdr=(XuseHdr*)lpFileInfo->lpStream;
	WORD* lpCode=(WORD *)((BYTE*)lpFileInfo->lpStream+\
		sizeof(XuseHdr)+hdr->nFunc2len+hdr->nFunc1len+hdr->nFunc3len+8);
	BYTE* lpStrings=(BYTE*)lpCode+hdr->nCodeLen+2;

	lpFileInfo->lpTextIndex=(LPWSTR*)VirtualAlloc(0,hdr->nCodeLen/8*4,MEM_COMMIT,PAGE_READWRITE);
	if(!lpFileInfo->lpTextIndex)
		return E_NOMEM;

	lpFileInfo->lpStreamIndex=(LPSTREAM_ENTRY)VirtualAlloc(0,\
		hdr->nCodeLen/8*sizeof(STREAM_ENTRY),MEM_COMMIT,PAGE_READWRITE);
	if(!lpFileInfo->lpStreamIndex)
		return E_NOMEM;

	WORD* pc=lpCode;
	DWORD nLine=0;
	while((BYTE*)pc<(BYTE*)lpCode+hdr->nCodeLen)
	{
		if(*pc==5)
		{
			WORD len=*(pc+1);
			LPBYTE lpStr=lpStrings+*(DWORD*)(pc+2);
			char* s1=new char[len];
			memcpy(s1,lpStr,len);
			for(int i=0;i<len;i++)
				s1[i]^=0x53;
			WCHAR* s2=new WCHAR[len+1];
			MultiByteToWideChar(lpFileInfo->dwCharSet,0,s1,len,s2,len+1);
			delete[] s1;
			lpFileInfo->lpTextIndex[nLine]=s2;
			lpFileInfo->lpStreamIndex[nLine].lpStart=pc;
			nLine++;
		}
		pc+=4;
	}
	lpFileInfo->dwMemoryType=MT_EVERYSTRING;
	lpFileInfo->nLine=nLine;
	*lpdwRInfo=RI_SUC_LINEONLY;

	return E_SUCCESS;
}

MRESULT WINAPI ModifyLine(LPFILE_INFO lpFileInfo, DWORD nLine)
{
	return E_SUCCESS;
}

MRESULT WINAPI SaveText(LPFILE_INFO lpFileInfo)
{
	return _SaveText(lpFileInfo);
}

