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
      
	include \masm32\lneditor\plugin.inc
	include \masm32\lneditor\export.inc
	include \masm32\lneditor\rsrc.inc
	include \masm32\lneditor\config.inc
	includelib \masm32\lneditor\lnedit.lib
	
IsmRelocTable struc
	lpOffsetTable		dd		?
	nOffsets			dd		?
	lpDistTable		dd		?
	nDists			dd		?
IsmRelocTable ends

.data?
	hInstance		dd		?
	hHeap		dd		?

	dwTemp		dd		?
.const
	szIsmMagic	db	'ISM SCRIPT',0,0
	
	align 4
				;	0	1	2	3	4	5	6	7	8	9	A	B	C	D	E	F
	IsmInstTable	db	-1,	-1,	-1,	-1,	-1,	0,	0,	-1,	-1,	-1,	-1,	0,	0,	0,	0,	-3
				db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
				db	-2,	-2,	-1,	4,	-2,	0,	-1,	-1,	0,	0,	0,	0,	0,	0,	0,	0	;2
				db	4,	4,	8,	-3,	-1,	0,	0,	0,	4,	5,	4,	5,	4,	5,	4,	5
				db	0,	0,	0,	0,	0,	-3,	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	0,	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1	;5
				db	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0	;8
				db	0,	0,	0,	0,	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	0,	0,	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1	;b
				db	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	0,	-1,	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1
				db	0,	0,	0,	0,	0,	0,	0,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1,	-1	;e
				db	0,	0,	0,	1,	0,	0,	0,	0,	0,	-1,	0,	0,	0,	0,	0,	0
					
