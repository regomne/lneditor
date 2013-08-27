#include<Windows.h>

HANDLE g_hHeap;
#define OVERLOAD_NEW
#include "\masm32\lneditor\SDK\C++\plugin.h"

HINSTANCE g_hInstance;

#pragma pack(1)
struct ScwHeader{
	BYTE	magic[0x10];	//"Scw5.x"
	WORD	minor_version;
	WORD	major_version;	//仅支持5
	DWORD	is_compr;		//-1表示压缩
	DWORD	uncomprlen;
	DWORD	comprlen;
	DWORD	always_1;					//	1
	DWORD	instruction_table_entries;	//	脚本指令的个数
	DWORD	string_table_entries;		//	字符串的个数
	DWORD	unknown_table_entries;
	DWORD	instruction_data_length;	//	脚本数据总长度
	DWORD	string_data_length;			//	字符串数据总长度
	DWORD	unknown_data_length;
	DWORD	unknown1;
	DWORD	status_block_len;
	BYTE	pad[0x184];
};

struct ScwIndexEntry{
	DWORD	offset;
	DWORD	length;
};

#pragma pack()



struct ScwInfo{
	ScwIndexEntry*	pInstTable;
	DWORD			nInstCount;
	ScwIndexEntry*	pStrTable;
	DWORD			nStrCount;
	ScwIndexEntry*	pUnkTable;
	DWORD			nUnkCount;
	BYTE*			pInsts;
	char*			pStrs;
	BYTE*			pUnks;
	DWORD			nStrsLen;
	DWORD			nStrsMaxLen;
};

BOOL GsLzssUncompress(BYTE* Dest, DWORD* pDestLen, BYTE* Src, DWORD SrcLen)
{
	DWORD act_uncomprlen = 0;
	/* compr中的当前字节中的下一个扫描位的位置 */
	DWORD curbit = 0;
	/* compr中的当前扫描字节 */
	DWORD curbyte = 0;
	DWORD nCurWindowByte = 0xfee;
	DWORD win_size = 4096;
	BYTE win[4096];
	WORD flag = 0;

	memset(win, 0, nCurWindowByte);
	while (1) {
		flag >>= 1;
		if (!(flag & 0x0100))
			flag = Src[curbyte++] | 0xff00;

		if (flag & 1) {
			unsigned char data;

			data = Src[curbyte++];
			if (act_uncomprlen >= *pDestLen)
				break;
			win[nCurWindowByte++] = data;
			Dest[act_uncomprlen++] = data;
			/* 输出的1字节放入滑动窗口 */
			nCurWindowByte &= win_size - 1;
		} else {
			DWORD copy_bytes, win_offset;
			DWORD i;

			win_offset = Src[curbyte++];
			copy_bytes = Src[curbyte++];
			win_offset |= (copy_bytes & 0xf0) << 4;
			copy_bytes &= 0x0f;
			copy_bytes += 3;

			for (i = 0; i < copy_bytes; i++) {	
				unsigned char data;

				if (act_uncomprlen >= *pDestLen)
					return TRUE;
				data = win[(win_offset + i) & (win_size - 1)];				
				Dest[act_uncomprlen++] = data;
				/* 输出的1字节放入滑动窗口 */
				win[nCurWindowByte++] = data;
				nCurWindowByte &= win_size - 1;	
			}
		}
	}
	*pDestLen=act_uncomprlen;
	return TRUE;
}

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
	HANDLE hFile=CreateFile(lpszName,GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
	if(hFile==INVALID_HANDLE_VALUE)
		return MR_ERR;
	DWORD nRead;
	char magic[0x10];
	BOOL bRet=ReadFile(hFile,magic,0x10,&nRead,0);
	CloseHandle(hFile);
	if(!bRet)
		return MR_ERR;
	if(!stricmp(magic,"Scw5.x"))
		return MR_YES;
	return MR_NO;
}

void GsDecrypt(BYTE* buff,DWORD nLen)
{
	for(DWORD i=0;i<nLen;i++)
		*buff++^=(BYTE)i;
}

BOOL GsProcessHeader(LPFILE_INFO lpFileInfo)
{
	ScwHeader* phdr=(ScwHeader*)lpFileInfo->lpStream;

	BYTE* p=(BYTE*)(phdr+1);	//指向header之后的第一个字节
	BYTE* pTemp;
	if(phdr->is_compr==-1)
	{
		GsDecrypt(p,phdr->comprlen);
		pTemp=new BYTE[phdr->uncomprlen];
		DWORD nDecLen=phdr->uncomprlen;
		GsLzssUncompress(pTemp,&nDecLen,p,phdr->comprlen);
		p=pTemp;
	}
	else
	{
		GsDecrypt(p,phdr->uncomprlen);
	}

	ScwInfo* pinfo=new ScwInfo;
	memset(pinfo,0,sizeof(ScwInfo));
	lpFileInfo->lpCustom=pinfo;

	//依次复制各个表到ScwInfo结构
	pinfo->nInstCount=phdr->instruction_table_entries;
	pinfo->pInstTable=new ScwIndexEntry[pinfo->nInstCount];
	memcpy(pinfo->pInstTable,p,pinfo->nInstCount*sizeof(ScwIndexEntry));
	p+=pinfo->nInstCount*sizeof(ScwIndexEntry);

	pinfo->nStrCount=phdr->string_table_entries;
	pinfo->pStrTable=new ScwIndexEntry[pinfo->nStrCount];
	memcpy(pinfo->pStrTable,p,pinfo->nStrCount*sizeof(ScwIndexEntry));
	p+=pinfo->nStrCount*sizeof(ScwIndexEntry);

	pinfo->nUnkCount=phdr->unknown_table_entries;
	pinfo->pUnkTable=new ScwIndexEntry[pinfo->nUnkCount];
	memcpy(pinfo->pUnkTable,p,pinfo->nUnkCount*sizeof(ScwIndexEntry));
	p+=pinfo->nUnkCount*sizeof(ScwIndexEntry);

	pinfo->pInsts=new BYTE[phdr->instruction_data_length];
	memcpy(pinfo->pInsts,p,phdr->instruction_data_length);
	p+=phdr->instruction_data_length;

	pinfo->nStrsLen=phdr->string_data_length;
	pinfo->nStrsMaxLen=phdr->string_data_length*3+0x100;
	pinfo->pStrs=new char[pinfo->nStrsMaxLen];
	memcpy(pinfo->pStrs,p,pinfo->nStrsLen);
	p+=phdr->string_data_length;

	pinfo->pUnks=new BYTE[phdr->unknown_data_length];
	memcpy(pinfo->pUnks,p,phdr->unknown_data_length);


	if(phdr->is_compr==-1)
		delete[] pTemp;

	return TRUE;
}

int GsReadStr(DWORD* &p,STREAM_ENTRY* lpse)
{
	//检查参数标识
	if(*(WORD*)p!=0xff00)
		return 0;
	DWORD count=*((WORD*)p+1);
	p++;
	DWORD strcount=0;
	//提取字符串，并存入StreamEntry结构
	for(DWORD i=0;i<count;i++)
	{
		DWORD type=*p++;
		DWORD value=*p++;
		if(type==0x10 || type==0x100)
		{
			lpse->lpStart=(LPVOID)value;
			lpse++;
			strcount++;
		}
	}
	return strcount;
}

void GsStepInt(BYTE* &p)
{
	if(*(WORD*)p!=0xff00)
		return;
	DWORD count=*((WORD*)p+1);
	p+=4;
	for(DWORD i=0;i<count;i++)
	{
		p+=8;
	}
}

MRESULT WINAPI GetText(LPFILE_INFO lpFileInfo, LPDWORD lpdwRInfo)
{
	GsProcessHeader(lpFileInfo);
	
	ScwInfo* pinfo=(ScwInfo*)lpFileInfo->lpCustom;
	
	lpFileInfo->lpStreamIndex=(LPSTREAM_ENTRY)VirtualAlloc(0,
		pinfo->nStrCount*sizeof(STREAM_ENTRY),MEM_COMMIT,PAGE_READWRITE);
	
	BYTE* p=pinfo->pInsts;
	DWORD nLine=0;
	for(DWORD i=0;i<pinfo->nInstCount;i++)
	{
		BYTE* pTemp=p;
		WORD op=*(WORD*)p;
		WORD op_len=*((WORD*)p+1);
		if(op_len<24)
			__asm int 3
		p+=24;

		int ret;
		switch(op)
		{
		case 0x1a8:
		case 0x1aa:
		case 0x1b8:
			ret=GsReadStr(*(DWORD**)&p,&lpFileInfo->lpStreamIndex[nLine]);
			nLine+=ret;
			if(op!=0x1b8)
			{
				ret=GsReadStr(*(DWORD**)&p,&lpFileInfo->lpStreamIndex[nLine]);
				nLine+=ret;
			}
			break;
		case 0x1a9:
			GsStepInt(p);
			ret=GsReadStr(*(DWORD**)&p,&lpFileInfo->lpStreamIndex[nLine]);
			nLine+=ret;
			break;
		case 0x1ce:
			ret=GsReadStr(*(DWORD**)&p,&lpFileInfo->lpStreamIndex[nLine]);
			nLine+=ret;
			break;
		}
		p=pTemp+op_len;
	}

	lpFileInfo->dwMemoryType=MT_POINTERONLY;
	lpFileInfo->dwStringType=ST_CUSTOM;
	lpFileInfo->nLine=nLine;
	*lpdwRInfo=RI_SUC_LINEONLY;

	return E_SUCCESS;
}

MRESULT WINAPI GetStr(LPFILE_INFO lpFileInfo,LPWSTR* lppStr,LPSTREAM_ENTRY lpStreamEntry)
{
	ScwInfo* pinfo=(ScwInfo*)lpFileInfo->lpCustom;
	ScwIndexEntry* pStrEntries=pinfo->pStrTable;

	DWORD i=(DWORD)lpStreamEntry->lpStart;
	char* ps=pinfo->pStrs+pinfo->pStrTable[i].offset;
	
	wchar_t* pTemp=new wchar_t[pinfo->pStrTable[i].length];
	int ret=MultiByteToWideChar(lpFileInfo->dwCharSet,0,ps,pinfo->pStrTable[i].length,
		pTemp,pinfo->pStrTable[i].length);
	*lppStr=_ReplaceCharsW(pTemp,RCH_ENTERS | RCH_TOESCAPE,0);
	delete[] pTemp;

	return E_SUCCESS;
}

MRESULT WINAPI ModifyLine(LPFILE_INFO lpFileInfo, DWORD nLine)
{
	wchar_t* pwstr=_GetStringInList(lpFileInfo,nLine);

	//替换\n转义符
	pwstr=_ReplaceCharsW(pwstr,RCH_ENTERS | RCH_FROMESCAPE,0);
	DWORD nlen=WideCharToMultiByte(lpFileInfo->dwCharSet,0,pwstr,-1,0,0,0,0);
	char* pnstr=new char[nlen];
	int ret=WideCharToMultiByte(lpFileInfo->dwCharSet,0,pwstr,-1,pnstr,nlen,0,0);
	delete[] pwstr;
	if(!ret || ret!=nlen)
	{
		delete[] pnstr;
		return E_CODEFAILED;
	}

	ScwInfo* pinfo=(ScwInfo*)lpFileInfo->lpCustom;
	DWORD idx=(DWORD)lpFileInfo->lpStreamIndex[nLine].lpStart;

	if(nlen<=pinfo->pStrTable[idx].length)
	{
		//若小于等于原始字符串长度，直接覆盖
		memcpy(pinfo->pStrs+pinfo->pStrTable[idx].offset,pnstr,nlen);
		pinfo->pStrTable[idx].length=nlen;
	}
	else
	{
		//若大于原始长度，附到最后面
		if(pinfo->nStrsLen+nlen>pinfo->nStrsMaxLen)
		{
			delete[] pnstr;
			return E_NOTENOUGHBUFF;
		}
		memcpy(pinfo->pStrs+pinfo->nStrsLen,pnstr,nlen);
		pinfo->pStrTable[idx].offset=pinfo->nStrsLen;
		pinfo->nStrsLen+=nlen;
		pinfo->pStrTable[idx].length=nlen;
	}
	delete[] pnstr;

	return E_SUCCESS;
}

MRESULT WINAPI SaveText(LPFILE_INFO lpFileInfo)
{
	ScwInfo* pinfo=(ScwInfo*)lpFileInfo->lpCustom;
	DWORD nWritten;
	SetFilePointer(lpFileInfo->hFile,0,0,FILE_BEGIN);
	ScwHeader hdr;
	memcpy(&hdr,lpFileInfo->lpStream,sizeof(ScwHeader));
	//保存时不再压缩
	hdr.is_compr=0;
	hdr.string_data_length=pinfo->nStrsLen;
	//计算新的长度
	hdr.uncomprlen=(hdr.instruction_table_entries+
					hdr.string_table_entries+
					hdr.unknown_table_entries)*sizeof(ScwIndexEntry)+
					hdr.instruction_data_length+
					hdr.string_data_length+
					hdr.unknown_data_length;
	hdr.comprlen=hdr.uncomprlen;
	WriteFile(lpFileInfo->hFile,&hdr,sizeof(hdr),&nWritten,0);

	//重构文件
	BYTE* finalbf=new BYTE[hdr.uncomprlen];
	BYTE* p=finalbf;
	memcpy(p,pinfo->pInstTable,pinfo->nInstCount*sizeof(ScwIndexEntry));
	p+=pinfo->nInstCount*sizeof(ScwIndexEntry);
	memcpy(p,pinfo->pStrTable,pinfo->nStrCount*sizeof(ScwIndexEntry));
	p+=pinfo->nStrCount*sizeof(ScwIndexEntry);
	memcpy(p,pinfo->pUnkTable,pinfo->nUnkCount*sizeof(ScwIndexEntry));
	p+=pinfo->nUnkCount*sizeof(ScwIndexEntry);
	memcpy(p,pinfo->pInsts,hdr.instruction_data_length);
	p+=hdr.instruction_data_length;
	memcpy(p,pinfo->pStrs,hdr.string_data_length);
	p+=hdr.string_data_length;
	memcpy(p,pinfo->pUnks,hdr.unknown_data_length);

	GsDecrypt(finalbf,hdr.uncomprlen);

	WriteFile(lpFileInfo->hFile,finalbf,hdr.uncomprlen,&nWritten,0);
	delete[] finalbf;
	if(nWritten!=hdr.uncomprlen)
		return E_FILEWRITEERROR;
	SetEndOfFile(lpFileInfo->hFile);
	return E_SUCCESS;
}

MRESULT WINAPI Release(LPFILE_INFO lpFileInfo)
{
	if(lpFileInfo->lpCustom)
	{
		ScwInfo* pinfo=(ScwInfo*)lpFileInfo->lpCustom;
		if(pinfo->pInstTable)
			delete[] pinfo->pInstTable;
		if(pinfo->pStrTable)
			delete[] pinfo->pStrTable;
		if(pinfo->pUnkTable)
			delete[] pinfo->pUnkTable;
		if(pinfo->pInsts)
			delete[] pinfo->pInsts;
		if(pinfo->pStrs)
			delete[] pinfo->pStrs;
		if(pinfo->pUnks)
			delete[] pinfo->pUnks;
		delete pinfo;
	}
	return E_SUCCESS;
}