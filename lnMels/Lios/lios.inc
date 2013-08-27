      include \masm32\include\windows.inc
      include \masm32\include\masm32.inc      
      include \masm32\include\gdi32.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \masm32\include\Comctl32.inc
      include \masm32\include\comdlg32.inc
      include \masm32\include\shell32.inc
      include \masm32\include\oleaut32.inc
      include \masm32\include\msvcrt.inc
      include \masm32\include\shlwapi.inc
      include \masm32\macros\macros.asm
      include \masm32\macros\strings.mac

      includelib \masm32\lib\masm32.lib
      includelib \masm32\lib\gdi32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \masm32\lib\Comctl32.lib
      includelib \masm32\lib\comdlg32.lib
      includelib \masm32\lib\shell32.lib
      includelib \masm32\lib\oleaut32.lib
      includelib \masm32\lib\shlwapi.lib
      includelib \masm32\lib\msvcrt.lib
      
	include \masm32\lneditor\export.inc
	include \masm32\lneditor\rsrc.inc
	include \masm32\lneditor\plugin.inc
	include \masm32\lneditor\config.inc
	includelib \masm32\lneditor\lnedit.lib
	
	INCLUDE rsrc.inc

MAX_LINELENGTH		EQU		22
CT_ADD				equ		1
CT_DEL				equ		1

_GscHeader struct
	nFileSize dd ?
	nHeaderSize dd ?	;目前发现24h和1ch两种，使用不同的指令。
	nControlStreamSize dd ?
	nIndexSize dd ?
	nTextSize dd ?
	nExtra	dd	8	dup(?)
_GscHeader ends

_GscInfo struct
	sHeader _GscHeader <?> 
	lpControlStream dd ?
	lpIndex dd ?;相对地址
	lpText dd ?
	lpExtraData dd ?
	lpRelocTable dd ?;里面是相对地址，指向相对地址
	lpIndexCS dd ?;里面相对地址
	nTotalInst	dd		?
_GscInfo ends

ModifyLine proto :dword,:dword
SaveText proto :dword
Release proto :dword
_memcpy proto
_MakeFromStream proto :dword,:dword
_ProcControlStream proto :dword,:dword
_ReleaseHeap proto :dword
_GetTextByIdx proto :dword,:dword
_AddString proto :dword,:dword,:dword
_CorrectRTCS proto :dword,:dword,:dword,:dword
_Relocate proto :dword,:dword,:dword,:dword

.data?
	hInstance		dd		?
	hWinMain	dd		?
	hHeap		dd		?
	dwTemp		dd		?
	
	bIsSilent		dd		?
	nLine		dd		?

.const
;						0,	1,	2,	3,	4,	5,	6,	7,	8,	9,	A,	B,	C,	D,	E,	F
	dtParamSize1 db	-1,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	4
	
;					0,	1,	2,	3,	4,	5,	6,	7,	8,	9,	A,	B,	C,	D,	E,	F
	;紫影のソナーニル & 漆黑 & 腐姬
	dtParamSize20 db 	-1,	-1,	-1,	4,	4,	4,	-1,	-1,	0,	4,	0,	0,	8,	4,	58,	30h;Modified
				db	4,	0,	8,	4,	8,	4,	16,	16,	8,	8,	0,	0,	12,	8,	24,	-1
				db	24,	20,	20,	8,	8,	8,	16,	12,	8,	8,	8,	8,	4,	8,	4,	8	;2
				db	12,	8,	0,	0,	0,	4,	-1,	0,	20,	0,	0,	16,	12,	8,	4,	12
				db	4,	4,	16,	4,	0,	0,	16,	16,	4,	12,	4,	20,	-1,	16,	-1,	-1
				db	4,	28,	24,	4,	8,	-1,	-1,	-1,	-1,	-1,	12,	20,	8,	8,	4,	8	;5
				db	8,	8,	8,	12,	12,	8,	4,	8,	16,	-1,	20,	-1,	-1,	-1,	12,	12
				db	4,	8,	8,	8,	8,	8,	-1,	-1,	8,	8,	-1,	-1,	-1,	-1,	-1,	-1
				db	-1,	-1,	16,	20,	8,	-1,	12,	20,	12,	-1,	-1,	-1,	8,	8,	8,	-1
				db	-1,	-1,	-1,	-1,	-1,	-1,	8,	8,	8,	8,	8,	8,	12,	20,	8,	8	;9
				db	16 dup (-1)
				db	16 dup (-1)
				db	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	44,	20,	12,	-1,	-1,	-1,	-1,	-1	;c
				db	-1,	-1,	8,	16,	4,	12,	-1,	-1,	-1,	-1,	-1,	-1,	12,	8,	0,	8
				db	-1,	20,	-1,	-1,	-1,	-1,	4,	4,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	15 dup (-1),20

	;Forest
	dtParamSize21 db 	-1,	-1,	-1,	4,	4,	4,	-1,	-1,	0,	2,	0,	0,	4,	4,	58,	4
				db	4,	0,	8,	4,	8,	0,	16,	8,	8,	4,	0,	0,	12,	8,	24,	-1
				db	24,	20,	20,	8,	8,	8,	12,	12,	8,	8,	8,	8,	4,	8,	4,	8
				db	8,	8,	4,	0,	0,	4,	-1,	0,	20,	0,	0,	16,	8,	4,	4,	12
				db	4,	4,	16,	4,	0,	0,	16,	16,	4,	8,	4,	16,	-1,	16,	-1,	-1
				db	4,	28,	24,	4,	-1,	-1,	-1,	-1,	-1,	-1,	12,	20,	8,	8,	4,	8
				db	8,	8,	8,	12,	12,	8,	4,	8,	16,	-1,	-1,	-1,	-1,	-1,	12,	12
				db	4,	8,	8,	-1,	-1,	-1,	-1,	-1,	8,	8,	-1,	-1,	-1,	-1,	-1,	-1
				db	-1,	-1,	16,	20,	8,	-1,	12,	20,	12,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	-1,	-1,	-1,	-1,	-1,	-1,	8,	8,	8,	8,	8,	8,	-1,	-1,	-1,	-1	
				db	16 dup(-1)
				db	16 dup(-1)
				db	16 dup(-1)
				db	16 dup(-1)
				db	16 dup(-1)
				db	16 dup(-1)
	
		