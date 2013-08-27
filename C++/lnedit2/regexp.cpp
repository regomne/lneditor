#include <windows.h>
#include "deelx.h"
#include "..\..\SDK\C++\plugin.h"

extern "C"
{
	MRESULT		WINAPI _RegInitA(CHAR* lpszPattern,int nFlag,CRegexpA** lpReg);
	MRESULT		WINAPI _RegReleaseA(CRegexpA* lpReg);
	MRESULT		WINAPI _RegReplaceA(CRegexpA* lpReg, CHAR* lpszStr, CHAR* lpszRpl, int nStart, CHAR** lpszRet);
	MRESULT		WINAPI _RegReleaseStringA(CHAR* lpszStr);
	MRESULT		WINAPI _RegMatchA(CRegexpA* lpReg, CHAR* lpszStr, int nStart, LPREGEXP_RESULT lprRslt);
	BOOL		WINAPI _IsRegMatchA(CHAR* lpszPatt,CHAR* lpszStr);

	MRESULT		WINAPI _RegInitW(WCHAR* lpszPattern,int nFlag,CRegexpW** lpReg);
	MRESULT		WINAPI _RegReleaseW(CRegexpW* lpReg);
	MRESULT		WINAPI _RegReplaceW(CRegexpW* lpReg, WCHAR* lpszStr, WCHAR* lpszRpl, int nStart, WCHAR** lpszRet);
	MRESULT		WINAPI _RegReleaseStringW(WCHAR* lpszStr);
	MRESULT		WINAPI _RegMatchW(CRegexpW* lpReg, WCHAR* lpszStr, int nStart, LPREGEXP_RESULT lprRslt);
	BOOL		WINAPI _IsRegMatchW(WCHAR* lpszPatt,WCHAR* lpszStr);
	
	MRESULT		WINAPI _RegCreateInstanceA(CRegexpA** lpReg);
	MRESULT		WINAPI _RegCreateInstanceW(CRegexpW** lpReg);
};

MRESULT WINAPI _RegCreateInstanceA(CRegexpA** lppReg)
{
	*lppReg=new CRegexpA();
	if(!*lppReg)
		return E_NOMEM;
	return E_SUCCESS;
}

MRESULT WINAPI _RegInitA(CHAR* lpszPattern,int nFlag,CRegexpA** lppReg)
{
	*lppReg=new CRegexpA(lpszPattern,nFlag);
	if(!*lppReg)
		return E_NOMEM;

	return E_SUCCESS;
}

MRESULT WINAPI _RegReleaseA(CRegexpA* lpReg)
{
	if(lpReg)
		delete lpReg;
	return E_SUCCESS;
}

MRESULT WINAPI _RegReplaceA(CRegexpA* lpReg, CHAR* lpszStr, CHAR* lpszRpl, int nStart, CHAR** lpszRet)
{
	*lpszRet=lpReg->Replace(lpszStr,lpszRpl,nStart,-1);
	return E_SUCCESS;
}

MRESULT WINAPI _RegReleaseStringA(CHAR* lpszStr)
{
	CRegexpA::ReleaseString(lpszStr);
	return E_SUCCESS;
}

BOOL WINAPI _IsRegMatchA(CHAR* lpszPatt,CHAR* lpszStr)
{
	CRegexpA Reg(lpszPatt);

	auto mr=Reg.Match(lpszStr);
	return mr.IsMatched();
}

MRESULT WINAPI _RegMatchA(CRegexpA* lpReg, CHAR* lpszStr, int nStart, LPREGEXP_RESULT lprRslt)
{
	auto mr=lpReg->Match(lpszStr,nStart);
	lprRslt->bIsMatched=mr.IsMatched();
	if(!lprRslt->bIsMatched)
		return E_SUCCESS;

	lprRslt->rBase.nLeft=mr.GetStart();
	lprRslt->rBase.nRight=mr.GetEnd();

	auto mx=REG_MAX_GROUPS>mr.MaxGroupNumber()?mr.MaxGroupNumber():REG_MAX_GROUPS;
	lprRslt->nGroups=mx;

	for(int i=0;i<=mx;i++)
	{
		lprRslt->rGroups[i].nLeft=mr.GetGroupStart(i+1);
		lprRslt->rGroups[i].nRight=mr.GetGroupEnd(i+1);
	}
	return E_SUCCESS;
}

MRESULT WINAPI _RegCreateInstanceW(CRegexpW** lppReg)
{
	*lppReg=new CRegexpW();
	if(!*lppReg)
		return E_NOMEM;
	return E_SUCCESS;
}

MRESULT WINAPI _RegInitW(WCHAR* lpszPattern,int nFlag,CRegexpW** lppReg)
{
	*lppReg=new CRegexpW(lpszPattern,nFlag);
	if(!*lppReg)
		return E_NOMEM;
	return E_SUCCESS;
}

MRESULT WINAPI _RegReleaseW(CRegexpW* lpReg)
{
	if(lpReg)
		delete lpReg;
	return E_SUCCESS;
}

MRESULT WINAPI _RegReplaceW(CRegexpW* lpReg, WCHAR* lpszStr, WCHAR* lpszRpl, int nStart, WCHAR** lpszRet)
{
	*lpszRet=lpReg->Replace(lpszStr,lpszRpl,nStart,-1);
	return E_SUCCESS;
}

MRESULT WINAPI _RegReleaseStringW(WCHAR* lpszStr)
{
	CRegexpW::ReleaseString(lpszStr);
	return E_SUCCESS;
}

BOOL WINAPI _IsRegMatchW(WCHAR* lpszPatt,WCHAR* lpszStr)
{
	CRegexpW Reg(lpszPatt);

	auto mr=Reg.Match(lpszStr);
	return mr.IsMatched();
}

MRESULT WINAPI _RegMatchW(CRegexpW* lpReg, WCHAR* lpszStr, int nStart, LPREGEXP_RESULT lprRslt)
{
	auto mr=lpReg->Match(lpszStr,nStart);
	lprRslt->bIsMatched=mr.IsMatched();
	if(!lprRslt->bIsMatched)
		return E_SUCCESS;

	lprRslt->rBase.nLeft=mr.GetStart();
	lprRslt->rBase.nRight=mr.GetEnd();

	auto mx=REG_MAX_GROUPS>mr.MaxGroupNumber()?mr.MaxGroupNumber():REG_MAX_GROUPS;
	lprRslt->nGroups=mx;

	for(int i=0;i<=mx;i++)
	{
		lprRslt->rGroups[i].nLeft=mr.GetGroupStart(i+1);
		lprRslt->rGroups[i].nRight=mr.GetGroupEnd(i+1);
	}
	return E_SUCCESS;
}
