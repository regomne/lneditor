#include<Windows.h>
#include <list>
#include <stack>

HANDLE g_hHeap;
#define OVERLOAD_NEW
#include "..\..\..\SDK\C++\plugin.h"

#include "mes.h"

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
	char scrName[0x10];

	HANDLE hFile=CreateFile(lpszName,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
	if(hFile==INVALID_HANDLE_VALUE)
		return MR_ERR;
	DWORD nRead;
	BOOL bRet=ReadFile(hFile,&scrName,0x10,&nRead,0);
	CloseHandle(hFile);
	if(!bRet)
		return MR_ERR;
	if(!memcmp(scrName,"ADVWin32 1.00  \0",0x10))
		return MR_YES;
	return MR_NO;
}

void GetBracket(BYTE* &p)
{
	for(BYTE op=*p++;op!=1;op=*p++)
	{
		if(op>=0xb0 && op<=0xd5)
			continue;
		switch(op)
		{
		case 0xe2:
			p++;
			break;
		case 0xe3:
			p+=2;
			break;
		case 0xe4:
			p+=4;
			break;
		case 0xe5:
			p+=strlen((char*)p)+1;
			break;
		case 0xe6:
		case 0xe7:
		case 0xe8:
			p+=2;
			break;
		default:
			__asm int 3;
		}
	}
}

int GetPara(BYTE* &p,BYTE op)
{
	ULONG rslt=0;
	switch(op)
	{
	case 4:
	case 5:
		return -1;
		rslt=-1;
		break;
	case 0x13:
	case 0x14:
	case 0xe1:
		GetBracket(p);
		break;
	case 0xe2:
		rslt=*p++;
		break;
	case 0xe3:
		rslt=*(WORD*)p;
		p+=2;
		break;
	case 0xe4:
		rslt=*(DWORD*)p;
		p+=4;
		break;
	case 0xe5:
		p+=strlen((char*)p)+1;
		break;
	case 0xe6:
	case 0xe7:
	case 0xe8:
		p+=2;
		break;
	default:
		__asm int 3;
	}
	return 0;
}

void ClearJmpTbl(
	std::stack<std::list<JmpEntry>::iterator>& toClean,
	std::list<JmpEntry>& jmpTbl,
	LPBYTE curp)
{
	std::list<JmpEntry>::iterator iter;

	while(!toClean.empty())
	{
		iter=toClean.top();
		if(iter->addrPtr <= curp)
			jmpTbl.erase(iter);
		toClean.pop();
	}
}

/*
-1	未知指令
0	正常寻找参数
1	直接返回，开始下一条指令
2	跳转
3	文本开始
4	0x12指令
5	括号指令
6	0x38
*/
BYTE OpTable[0x80]={
	-1,-1,1,2,2,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,3,4,5,5,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	//2
	0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	//5
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,-1,-1,-1,-1,
};

MRESULT WINAPI GetText(LPFILE_INFO lpFileInfo, LPDWORD lpdwRInfo)
{
	MesHeader* mesHdr=(MesHeader*)lpFileInfo->lpStream;

	if(memcmp(mesHdr->scrName,"ADVWin32 1.00  \0",0x10))
		return E_WRONGFORMAT;
	
	lpFileInfo->lpStreamIndex=(STREAM_ENTRY*)VirtualAlloc(
		0,(lpFileInfo->nStreamSize/8)*sizeof(STREAM_ENTRY),MEM_COMMIT,PAGE_READWRITE);
	if(!lpFileInfo->lpStreamIndex)
		return E_NOMEM;

	ULONG line=0;
	BYTE* p=((BYTE*)lpFileInfo->lpStream+mesHdr->hdrSize);

	std::list<JmpEntry>* jmpTbl=new std::list<JmpEntry>();
	if(!jmpTbl)
		return E_NOMEM;
	lpFileInfo->lpCustom=jmpTbl;
	std::stack<std::list<JmpEntry>::iterator> toClean;

	BYTE* pend=(BYTE*)lpFileInfo->lpStream+mesHdr->fileSize;
	JmpEntry jEntry;
	while(p<pend)
	{
		BYTE op,ope;
		if((op=*p++)>=0x80)
			__asm int 3;
		if((ope=OpTable[op])==-1)
			__asm int 3;
		switch(ope)
		{
		case 0:
			do
			{
				BYTE next=*p++;
				if(next<=3 || (next>=0x10 && next<=0x7b))
					break;
				if(GetPara(p,next)==-1)
					break;
			}while(1);
			p--;
			break;
		case 1:
			//nothing to do.
			break;
		case 2:
			if(*p++!=0xe4)
				__asm int 3;
			jEntry.addr=p;
			jEntry.addrPtr=p-1+*(DWORD*)p;
			p+=4;
			toClean.push(jmpTbl->insert(jmpTbl->end(),jEntry));
			break;
		case 3:
			p--;
			ClearJmpTbl(toClean,*jmpTbl,p);
			lpFileInfo->lpStreamIndex[line++].lpStart=p;
			do 
			{
				p++;
				p+=strlen((char*)p)+1;
			} while (*p==0x11);
			break;
		case 4:
			//nothing to do.
			break;
		case 5:
			GetBracket(p);
			break;
		case 6:
			//{
			//	BYTE paraop=*p++;
			//	BYTE val=GetPara(p,paraop);
			//	if(val==0)
			//		__asm int 3
			//	lpFileInfo->lpStreamIndex[line++].lpInformation=LPVOID(ope);
			//}
			if(*p++!=0xe8)
				__asm int 3
			lpFileInfo->lpStreamIndex[line++].lpInformation=LPVOID(*(WORD*)p);
			p+=2;
			break;
		}
	}
	ClearJmpTbl(toClean,*jmpTbl,pend);

	lpFileInfo->nLine=line;
	lpFileInfo->dwMemoryType=MT_POINTERONLY;
	lpFileInfo->dwStringType=ST_CUSTOM;
	*lpdwRInfo=RI_SUC_LINEONLY;

	return E_SUCCESS;
}

MRESULT WINAPI GetStr(LPFILE_INFO lpFileInfo,LPWSTR* pPos,LPSTREAM_ENTRY lpStreamEntry)
{
	if(lpStreamEntry->lpInformation)
	{
		*pPos=new wchar_t[10];
		if(!*pPos)
			return E_NOMEM;
		wsprintf(*pPos,L"N%d",lpStreamEntry->lpInformation);
	}
	else
	{
		ULONG i=0,len=0,tlen;
		char* p=(char*)lpStreamEntry->lpStart;
		do 
		{
			i++;
			tlen=strlen(++p);
			len+=tlen;
			p+=tlen+1;
		} while (*p==0x11);
		lpStreamEntry->nStringLen=i;
		len+=i*2+1;
		*pPos=new wchar_t[len];
		if(!*pPos)
			return E_NOMEM;

		p=(char*)lpStreamEntry->lpStart;
		wchar_t* wp=*pPos;
		while(i--)
		{
			p++;
			int cch=MultiByteToWideChar(lpFileInfo->dwCharSet,0,p,-1,wp,len);
			if(wp[cch-2]==L'\n')
				cch--;
			if(i)
			{
				wp[cch-1]=L'\n';
				cch++;
			}
			p+=strlen(p)+1;
			wp+=cch-1;
			len-=cch-1;
		}

		wp=*pPos;
		*pPos=_ReplaceCharsW(wp,RCH_ENTERS|RCH_TOESCAPE,0);
		delete[] wp;
		if(!*pPos)
			return E_NOMEM;
	}
	return E_SUCCESS;
}

void CorrectJumpOffset(std::list<JmpEntry>& jmpTbl,int dist,LPBYTE curp)
{
	std::list<JmpEntry>::iterator iter;
	for(iter=jmpTbl.begin();iter!=jmpTbl.end();iter++)
	{
		if(iter->addr>curp)
		{
			iter->addr+=dist;
			iter->addrPtr+=dist;
		}
		else if(iter->addrPtr>curp)
		{
			*(DWORD*)(iter->addr)+=dist;
			iter->addrPtr+=dist;
		}
	}
}

MRESULT WINAPI ModifyLine(LPFILE_INFO lpFileInfo, DWORD nLine)
{
	STREAM_ENTRY* sEntry=&lpFileInfo->lpStreamIndex[nLine];
	if(sEntry->lpInformation)
		return E_SUCCESS;
	int i=sEntry->nStringLen;
	char* p=(char*)sEntry->lpStart;
	if(*p!=0x11)
		return E_WRONGFORMAT;
	do 
	{
		p+=strlen(++p)+1;
	} while (*p==0x11);
	ULONG oldLen=p-(char*)sEntry->lpStart;

	wchar_t* newStr=lpFileInfo->lpTextIndex[nLine];
	newStr=_ReplaceCharsW(newStr,RCH_ENTERS|RCH_FROMESCAPE,0);
	if(!newStr)
		return E_NOMEM;

	ULONG newLen=WideCharToMultiByte(lpFileInfo->dwCharSet,0,newStr,-1,0,0,0,0);
	char* newStrA=new char[newLen+1];
	if(!newStrA)
	{
		delete[] newStr;
		return E_NOMEM;
	}
	*newStrA=0x11;
	newLen=WideCharToMultiByte(lpFileInfo->dwCharSet,0,newStr,-1,newStrA+1,newLen,0,0);
	newLen++;
	delete[] newStr;

	ULONG leftLen=(char*)lpFileInfo->lpStream+lpFileInfo->nStreamSize-sEntry->lpStart-oldLen;
	MRESULT rslt=_ReplaceInMem(newStrA,newLen,sEntry->lpStart,oldLen,leftLen);
	delete[] newStrA;
	if(rslt)
		return rslt;

	int dist=newLen-oldLen;
	if(dist)
	{
		lpFileInfo->nStreamSize+=dist;
		CorrectJumpOffset(*(std::list<JmpEntry>*)lpFileInfo->lpCustom,dist,(LPBYTE)sEntry->lpStart);

		STREAM_ENTRY* sEnd=&lpFileInfo->lpStreamIndex[lpFileInfo->nLine];
		while(++sEntry<sEnd)
		{
			sEntry->lpStart=(char*)sEntry->lpStart+dist;
		}
	}
	return E_SUCCESS;
}


MRESULT WINAPI SaveText(LPFILE_INFO lpFileInfo)
{
	MesHeader* mHdr=(MesHeader*)lpFileInfo->lpStream;
	mHdr->fileSize=lpFileInfo->nStreamSize;
	return _SaveText(lpFileInfo);
}

MRESULT WINAPI Release(LPFILE_INFO lpFileInfo)
{
	if(lpFileInfo->lpCustom)
	{
		delete (std::list<JmpEntry>*)lpFileInfo->lpCustom;
	}
	return E_SUCCESS;
}

MRESULT WINAPI SetLine(LPCWSTR lpStr,LPSEL_RANGE lpRange)
{
	return _SetLine(lpStr,lpRange);
}
