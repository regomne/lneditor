#ifndef _LN_LNEDIT_H
#define _LN_LNEDIT_H

#include <windows.h>
#include "..\..\SDK\C++\plugin.h"

#define MAX_MELCOUNT	50
#define MAX_STRINGLEN	2048
#define	SHORT_STRINGLEN	64

#define VT_PRODUCTNAME	1

#define TM_FAILED		-2
#define TM_EXIT			-3

typedef DWORD (__stdcall *PFMATCH)(LPCWSTR);
typedef void (__stdcall *PFPREPROC)(LPPRE_DATA);

typedef struct _MEL_INFO {
	WCHAR			lpszName[SHORT_STRINGLEN/2];
	HMODULE			hModule;
	PFMATCH			pMatch;
	LPMEL_INFO2		lpMelInfo2;
} MEL_INFO, *LPMEL_INFO;

typedef struct _LN_OPTIONS {
	LPWSTR			ScriptName;
	DWORD			Code;
	DWORD			Plugin;
	LPWSTR			ImportFile;
	LPWSTR			ExportFile;

	LPWSTR			SourceDir;
	LPWSTR			TxtDir;
	LPWSTR			NewDir;
	LPWSTR			NameFilter;
	BOOL			IsRecursive;
} LN_OPTIONS, *LPLN_OPTIONS;

extern "C" {
	extern	HANDLE			hGlobalHeap;
	extern	HANDLE			hStdOutput;
	extern	HANDLE			hStdInput;
	extern	DWORD			nUIStatus;

	extern	LPPRE_DATA		lpPreData;
	extern	DWORD			dbConf;

	extern	FILE_INFO		FileInfo1;

	extern	LPMEL_INFO		lpMels;
	extern	DWORD			nMels;
	extern	DWORD			nCurMel;

	extern	SIMPFUNC_TABLE	dbSimpFunc;

	extern	CMD_OPTIONS		coCmdOptions;
	extern	LPCWSTR			lpszConfigFile;

	extern	DWORD			dwTemp;

	LPCWSTR		__stdcall	_GetCmdOption(LPCWSTR lpszName);
	MRESULT		__stdcall	_OpenSingleScript(LPOPEN_PARAMETERS para, LPFILE_INFO fi, BOOL isLeft);

	MRESULT		__stdcall	_LoadSingleMel(LPMEL_INFO lpMelInfo, LPCWSTR lpszPluginName);
	void		__stdcall	_LoadMel(DWORD reserved);
	DWORD		__stdcall	_FindPlugin(LPCWSTR name, DWORD type);
	void		__stdcall	_GetMelInfo(LPMEL_INFO mi, LPWSTR lpszOut, DWORD type);

	void		__stdcall	_GetSimpFunc(HANDLE hModule, LPSIMPFUNC_TABLE st);

	MRESULT		__stdcall	_ExportSingleTxt(LPFILE_INFO lpFI, HANDLE ht);
	MRESULT		__stdcall	_ImportSingleTxt(LPFILE_INFO lpFI, LPVOID lpTxt, BOOL bFilterOn);

	void		__stdcall	_DirBackW(LPWSTR lpStr);
	void		__stdcall	_DirModifyExtendName(LPWSTR lpStr, LPCWSTR lpExt);

	LPCWSTR		__stdcall	_GetGeneralErrorString(DWORD type);
}

#endif