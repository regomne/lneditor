#include<Windows.h>

struct XuseHdr {
	DWORD dwMagic;
	DWORD nVer;
	DWORD nFunc1;
	DWORD nFunc1len;
	DWORD nFunc2;
	DWORD nFunc2len;
	DWORD nFunc3;
	DWORD nFunc3len;
	DWORD nCodeLen;
	DWORD nStringLen;
};