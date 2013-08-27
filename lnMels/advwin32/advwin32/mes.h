#pragma once

#include <windows.h>

struct MesHeader
{
	char scrName[0x10];
	DWORD unk1;
	ULONG fileSize;
	ULONG hdrSize;
	DWORD unk2;
};

struct JmpEntry
{
	LPBYTE addr;
	LPBYTE addrPtr;
};