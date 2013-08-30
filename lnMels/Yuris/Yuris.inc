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

SegInfo1 struct
	nCount		dd		?
	nCodeSize		dd		?
	nArgSize		dd		?
	nResSize		dd		?
	nOffSize		dd		?
	dwResvd		dd		?
SegInfo1 ends
SegInfo2 struct
	nInstSize	dd		?
	nResSize	dd		?
	nResOff		dd		?
	dwResvd		dd		3	dup(?)
SegInfo2 ends
SegInfo union
	s1	SegInfo1	<>
	s2	SegInfo2	<>
SegInfo ends

YurisHdr struct
	sMagic		dd		?
	nVersion		dd		?
	segInfo		SegInfo		<>
YurisHdr ends

YurisHdr2 struct
	sMagic		dd		?
	nVersion	dd		?
	nInstSize	dd		?
	nResSize	dd		?
	nResOff		dd		?
	dwResvd		dd		3	dup(?)
YurisHdr2 ends

YurisArg struct
	value		dw		?
	type1		dw		?
	len1			dd		?
	offset1		dd		?
YurisArg ends

YurisVerInfo struct
	nVerMin		dd		?
	nVerMax		dd		?
	opMsg		dw		?
	opCall		dw		?
YurisVerInfo ends

FUNC_SEL		EQU		1
FUNC_MARKSET	EQU		2
FUNC_CHARNAME	EQU		3
FUNC_INPUTSTR	EQU		4
FUNC_TIPS		EQU		5
FUNC_TIPSTX		EQU		6

.data?
	hInstance		dd		?
	hHeap		dd		?

	dwTemp		dd		?
.const
	dbFSel			db		'"es.sel.set"'
align 4
	dbFMarkSet		db		'"es.char.name.mark.set"'
align 4
	dbFCharName	db		'"es.char.name"'
align 4
	dbFInputStr		db		'"es.input.str.set"'
align 4
	dbFTipsStr	db		'"es.tips.def.set"'
align 4
	dbFTipsTxStr	db	'"es.tips.tx.def.set"'
	
	
	VerTable\
				YurisVerInfo		<124h,124h,0154h,19h>
				YurisVerInfo		<12ch,19ch,015ah,1dh>
				YurisVerInfo		<1f4h,1f4h,015ah,1dh>
				YurisVerInfo		<1c2h,1d8h,015bh,1dh>
				YurisVerInfo		<1d9h,1d9h,015ah,1dh>
				YurisVerInfo		<226h,226h,015ch,1eh>
                YurisVerInfo		<227h,227h,015ah,1dh>
	nVerInfos	dd		(offset nVerInfos-offset VerTable)/sizeof(YurisVerInfo)
		