#include <Windows.h>
#include <strsafe.h>
#include <stdio.h>
#include <locale.h>
#include <conio.h>

//#define _STL70_
//#include<string>
#include <vector>
//#include<algorithm>
using namespace std;

#include "lnedit.h"
#include "..\..\SDK\C++\plugin.h"

#pragma warning(disable:4995) //deprecated警告：wcscpy的安全性警告

//全局变量
LN_OPTIONS lpLnOptions;

void* operator new(size_t size)
{
	return (void*)HeapAlloc(hGlobalHeap,0,size);
}

void operator delete(void* p)
{
	HeapFree(hGlobalHeap,0,(LPVOID)p);
}

void myprintf(const wchar_t* ps)
{
	int len=wcslen(ps);
	DWORD nb;
	WriteConsole(hStdOutput,ps,len,&nb,0);
}

void TrimQuote(LPCMD_OPTIONS lpCmd)
{
	CMD_OPTION* pC=(CMD_OPTION*)lpCmd;
	for(int i=0;i<sizeof(CMD_OPTIONS)/sizeof(CMD_OPTION);i++)
	{
		wchar_t* p=pC[i].lpszValue;
		if(p)
		{
			int len=wcslen(p);
			if(p[0]==L'"' && p[len-1]==L'"')
			{
				RtlMoveMemory(p,&p[1],len-2);
				p[len-2]=L'\0';
			}
		}
	}
}

void PressExit()
{
	myprintf(L"\nPress any key to exit...");
	getch();
}

void PrintMels(DWORD* lpIdxes, DWORD nCount)
{
	wchar_t* lpszOut=new wchar_t[MAX_STRINGLEN/2];
	wchar_t* lpszTemp=new wchar_t[MAX_STRINGLEN/2];
	if(!lpIdxes)
	{
		for(int i=0;i<nMels;i++)
		{
			_GetMelInfo(&lpMels[i],lpszTemp,VT_PRODUCTNAME);
			wsprintf(lpszOut,L"%d. %s\n",i+1,lpszTemp);
			myprintf(lpszOut);
		}
	}
	else
	{
		for(int i=0;i<nCount;i++)
		{
			_GetMelInfo(&lpMels[lpIdxes[i]],lpszTemp,VT_PRODUCTNAME);
			wsprintf(lpszOut,L"%d. %s\n",i+1,lpszTemp);
			myprintf(lpszOut);
		}
	}
	delete[] lpszTemp;
	delete[] lpszOut;
}

void ParseOptionsToOpp(LPOPEN_PARAMETERS lpOpp,LPCMD_OPTIONS lpCmd)
{
	lpOpp->ScriptName=new wchar_t[wcslen(lpCmd->ScriptName.lpszValue)+10];
	wcscpy(lpOpp->ScriptName,lpCmd->ScriptName.lpszValue);
	if(lpCmd->Code1.lpszValue)
		lpOpp->Code1=_wtoi(lpCmd->Code1.lpszValue);
	if(lpCmd->Code2.lpszValue)
		lpOpp->Code2=_wtoi(lpCmd->Code2.lpszValue);
}
void ParseOptions(LPLN_OPTIONS lpOptions,LPCMD_OPTIONS lpCmd)
{
	lpOptions->ScriptName=new wchar_t[wcslen(lpCmd->ScriptName.lpszValue)+1];
	wcscpy(lpOptions->ScriptName,lpCmd->ScriptName.lpszValue);
	lpOptions->Code=_wtoi(lpCmd->Code1.lpszValue);
	lpOptions->ExportFile=new wchar_t[MAX_STRINGLEN/2];
}

DWORD TryMatch(LPCWSTR lpName)
{
	vector<DWORD> maybes;
	DWORD ret=TM_FAILED;
	for(int i=0;i<nMels;i++)
	{
		DWORD ret=lpMels[i].pMatch(lpName);
		if(ret==MR_YES)
			return i;
		else if(ret==MR_MAYBE)
			maybes.push_back(i);
	}
	if(maybes.size()==0)
	{
		//if(_SelfMatch(lpName)==MR_YES)
		//	ret=TM_TXTPLUGIN;
		//else
			ret=TM_FAILED;
	}
	else
	{
		PrintMels(&maybes[0],maybes.size());
		while(1)
		{
			myprintf(L"Please select the plugin(input the number, 0 to abort): ");
			wchar_t chars[4];
			ReadConsole(hStdInput,chars,4*2,&dwTemp,0);
			int i=_wtoi(chars);
			if(i>maybes.size())
			{
				myprintf(L"Input Error!\n");
				continue;
			}
			else
			{
				if(i==0)
					ret=TM_EXIT;
				else
					ret=maybes[i];
				break;
			}
		}
	}
	return ret;
}



void SingleFile()
{
	wchar_t szOutput[400];
	wchar_t szOutput2[400];
	OPEN_PARAMETERS opp;
	RtlZeroMemory(&opp,sizeof(opp));
	opp.Filter=-1;

	ParseOptionsToOpp(&opp,&coCmdOptions);

	if(coCmdOptions.Import.lpszValue && coCmdOptions.Export.lpszValue)
	{
		myprintf(L"Please do not use both /i and /e parameter!\n");
		return;
	}

	wchar_t* lpPath=new wchar_t[wcslen(opp.ScriptName)+1];
	wcscpy(lpPath,opp.ScriptName);
	_DirBackW(lpPath);
	SetCurrentDirectory(lpPath);
	delete[] lpPath;

	const wchar_t* lpNewFile;
	if(coCmdOptions.Import.lpszValue)
	{
		if((lpNewFile=_GetCmdOption(L"sa")) || (lpNewFile=_GetCmdOption(L"save")))
		{
			if(!CopyFile(opp.ScriptName,lpNewFile,FALSE))
			{
				myprintf(L"Can't create new file!\n");
				return;
			}
			delete[] opp.ScriptName;
			opp.ScriptName=new wchar_t[MAX_STRINGLEN/2];
			wcscpy(opp.ScriptName,lpNewFile);
		}
	}


	if(coCmdOptions.Plugin.lpszValue!=0 && coCmdOptions.Plugin.lpszValue[0]!=L'\0')
		opp.Plugin=0;
	else
	{
		int ret=TryMatch(opp.ScriptName);
		if(ret>=0)
		{
			opp.Plugin=ret;
			_GetMelInfo(&lpMels[opp.Plugin],szOutput2,VT_PRODUCTNAME);
			wsprintf(szOutput,L"Use plugin: %s.\n",szOutput2);
			myprintf(szOutput);
		}
		else if(ret==TM_FAILED)
		{
			myprintf(L"Plugin auto match failed!\n");
			return;
		}
		else
		{
			return;
		}
	}

	_GetSimpFunc(lpMels[opp.Plugin].hModule,&dbSimpFunc);
	PFPREPROC pPreProc=(PFPREPROC)GetProcAddress(lpMels[opp.Plugin].hModule,"PreProc");
	if(pPreProc!=NULL)
		pPreProc(lpPreData);

	MRESULT ret=_OpenSingleScript(&opp,&FileInfo1,TRUE);
	if(ret!=0)
	{
		//LPCWSTR lpStr=_GetGeneralErrorString(ret);
		//if(lpStr)
		//{
		//	myprintf(lpStr);
		//	myprintf(L"\n");
		//}
		myprintf(L"Error occurs when opening the script: ");
		_OutputMessage(ret,0,0,0);
		return;
	}

	if(coCmdOptions.Export.lpszValue)
	{
		int len=wcslen(coCmdOptions.Export.lpszValue);
		int explen=len;
		if(len==0)
			explen=wcslen(coCmdOptions.ScriptName.lpszValue);
		wchar_t* lpszExpName=new wchar_t[explen+9];
		if(len==0)
		{
			wcscpy(lpszExpName,coCmdOptions.ScriptName.lpszValue);
			wcscat(lpszExpName,L".txt");
		}
		else
		{
			wcscpy(lpszExpName,coCmdOptions.Export.lpszValue);
		}
		HANDLE hTxt=CreateFile(lpszExpName,GENERIC_WRITE,FILE_SHARE_READ,
			0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
		delete[] lpszExpName;
		if(hTxt==INVALID_HANDLE_VALUE)
		{
			myprintf(L"Can't create the txt file!\n");
			return;
		}
		MRESULT ret=_ExportSingleTxt(&FileInfo1,hTxt);
		CloseHandle(hTxt);
		if(ret!=0)
		{
			myprintf(L"Export failed: ");
			_OutputMessage(ret,0,0,0);
		}
		else
			myprintf(L"Export success!\n");

	}
	else if(coCmdOptions.Import.lpszValue)
	{
		int len=wcslen(coCmdOptions.Import.lpszValue);
		if(len==0)
		{
			myprintf(L"Must specify the txt file to import!\n");
			return;
		}
		HANDLE hTxt=CreateFile(coCmdOptions.Import.lpszValue,GENERIC_READ,FILE_SHARE_READ,
			0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
		if(hTxt==INVALID_HANDLE_VALUE)
		{
			myprintf(L"Can't open txt file.\n");
			return;
		}
		DWORD nFileSize=GetFileSize(hTxt,0);
		BYTE* lpTxt=new BYTE[nFileSize];
		ReadFile(hTxt,lpTxt,nFileSize,&dwTemp,0);
		CloseHandle(hTxt);
		if(dwTemp!=nFileSize)
		{
			myprintf(L"Error occurs while reading txt file.\n");
			delete[] lpTxt;
			return;
		}
		FileInfo1.bReadOnly=FALSE;
		MRESULT ret=_ImportSingleTxt(&FileInfo1,lpTxt,FALSE);
		delete[] lpTxt;
		if(ret!=0)
		{
			myprintf(L"Error occurs while import txt to table: \n");
			_OutputMessage(ret,0,0,0);
			return;
		}
		for(int i=0;i<FileInfo1.nLine;i++)
		{
			ret=dbSimpFunc.lpModifyLine(&FileInfo1,i);
			if(ret!=0)
			{
				wsprintf(szOutput,L"Line %d denied.\n",i);
				myprintf(szOutput);
			}
		}
		ret=dbSimpFunc.lpSaveText(&FileInfo1);
		if(ret!=0)
		{
			myprintf(L"Error occurs while saving file!\n");
			_OutputMessage(ret,0,0,0);
			return;
		}
		myprintf(L"Import Success!\n");
	}
	else
	{
		myprintf(L"Please specify whether import or export!\n");
	}
}

wchar_t* lprRootPathSc;
wchar_t* lprRootPathTxt;
wchar_t* lprRootPathNew;
BOOL isRecursive;
wchar_t* lprFilter;
typedef MRESULT (__stdcall *PFTRACCALLBACK)(LPCWSTR);
PFTRACCALLBACK pProcess;
void Traverse(LPCWSTR subdir)
{
	wchar_t* curdir=new wchar_t[MAX_STRINGLEN/2];
	wchar_t* newdir=new wchar_t[MAX_STRINGLEN/2];
	WIN32_FIND_DATA* pfd=new WIN32_FIND_DATA;

	wcscpy(curdir,subdir);
	if(curdir[0]==L'\0')
		wcscpy(curdir,L"*");
	else
		wcscat(curdir,L"\\*");

	HANDLE hFind=FindFirstFile(curdir,pfd);
	if(hFind!=INVALID_HANDLE_VALUE)
	{
		curdir[wcslen(curdir)-1]=L'\0';
		do
		{
			if(wcscmp(pfd->cFileName,L".")==0 || wcscmp(pfd->cFileName,L"..")==0)
				continue;
			if(pfd->dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY && isRecursive)
			{
				wcscpy(newdir,curdir);
				wcscat(newdir,pfd->cFileName);
				Traverse(newdir);
			}
			else
			{
//				if(!lprFilter || _WildCharMatchW(lprFilter,pfd->cFileName))
				{
					pProcess(pfd->cFileName);
				}
			}
		}while(FindNextFile(hFind,pfd)!=0);
		FindClose(hFind);
	}

	delete pfd;
	delete[] newdir;
	delete[] curdir;
}

void Folders()
{

}

extern "C" void WINAPI _CmdMain()
{
	BOOL ret=AttachConsole(ATTACH_PARENT_PROCESS);
	if(ret==0)
		AllocConsole();
	//AllocConsole();
	hStdOutput=GetStdHandle(STD_OUTPUT_HANDLE);
	hStdInput=GetStdHandle(STD_INPUT_HANDLE);
	_wfreopen(L"CONOUT$", L"w", stdout);
	_wfreopen(L"CONOUT$", L"w", stderr);
	_wfreopen(L"CONIN$", L"r", stdin);
	_wsetlocale(LC_ALL,L"");

	nUIStatus|=UIS_CONSOLE;
	TrimQuote(&coCmdOptions);
	if(_GetCmdOption(L"help")!=NULL)
	{
		myprintf(L"usage: \nOK, that is a test.");
		PressExit();
		return;
	}
	lpMels=(LPMEL_INFO)VirtualAlloc(0,MAX_MELCOUNT*sizeof(MEL_INFO),MEM_COMMIT,PAGE_READWRITE);
	if(!lpMels)
	{
		myprintf(L"Not enough memory!");
		PressExit();
		return;
	}
	if(coCmdOptions.Plugin.lpszValue)
	{
		if(wcslen(coCmdOptions.Plugin.lpszValue)>=SHORT_STRINGLEN/2)
		{
			myprintf(L"Invalid plugin name!\n");
			PressExit();
			return;
		}
		wchar_t* s1=new wchar_t[wcslen(lpszConfigFile)+39];
		wcscpy(s1,lpszConfigFile);
		_DirBackW(s1);
		wcscat(s1,L"\\mel\\");
		wcscat(s1,coCmdOptions.Plugin.lpszValue);
		wcslwr(s1);
		if(wcscmp(&s1[wcslen(s1)-4],L".mel"))
			wcscat(s1,L".mel");
		if(_LoadSingleMel(lpMels,s1)!=E_SUCCESS)
		{
			myprintf(L"Can't load plugin!\n");
			PressExit();
			return;
		}
		delete[] s1;
		myprintf(L"Loading plugin success.\n");
		nMels=1;
		nCurMel=0;
	}
	else
	{
		myprintf(L"Loading plugins...\n");
		_LoadMel(0);
	}
	lpPreData=new PRE_DATA;
	lpPreData->hGlobalHeap=hGlobalHeap;
	lpPreData->lpszConfigFileName=lpszConfigFile;
	lpPreData->lpConfigs=(LPVOID)&dbConf;
	lpPreData->lpHandles=0;
	lpPreData->lpMenuFuncs=0;
	lpPreData->lpSimpFunc=&dbSimpFunc;
	lpPreData->lpTxtFuncs=0;
	lpPreData->lpCmdOptions=&coCmdOptions;

	if(coCmdOptions.ScriptName.lpszValue)
		SingleFile();
	else if(coCmdOptions.ScriptDir.lpszValue)
		Folders();

	PressExit();
}

extern CRITICAL_SECTION RegLockA;
extern CRITICAL_SECTION RegLockW;

extern "C" void WINAPI _CppInitialize()
{
}