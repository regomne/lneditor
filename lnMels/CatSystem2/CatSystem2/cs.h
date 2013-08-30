#pragma once
#include <windows.h>

typedef struct _CS_ORIG_HDR{
	char dwMagic[8];
	DWORD comprLen;
	DWORD uncomprLen;
} CS_ORIG_HDR,*LPCS_ORIG_HDR;

typedef struct _CS_HDR{
	DWORD sceneLen;
	DWORD instCnt;
	DWORD offTableOffset;
	DWORD rsrcOffset;
} CS_HDR, *LPCS_HDR;
