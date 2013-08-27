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
	

ModifyLine proto :dword,:dword

.data?
	hInstance		dd		?
	hHeap		dd		?

	dwTemp		dd		?
	bIsCrypted	dd		?
.const

	ddTable\ ;00
			dd 0bh,11h,5,5,0,6,0,1,0ffh,0,1,0,0,0,0,0
			dd 5,5,0,0,0,0,1,5,0,0,0,0,0,0bh,0,0
			dd 0ch,15 dup (0)
			dd 0,0,0,5,5,0,1,0bh,8 dup (0)
			;01
			dd 0feh,0ff01h,5,0fffefeh,0ff01h,0ah,0ah,0ah,23h,01fefefeh,0ah,0fe0ah,6,0fefe05h,15h,5
			dd 10h,5,23h,19h,5,0ff01h,0,0ffffh,0feh,0,2,6,0bh,0bh,0ffffh,0
			dd 16 dup (0)
			dd 16 dup (0)
			;02
			dd 0ff05h,0fh,6,19h,0ah,0fh,0ah,0ah,14h,1eh,0fh,14h,15h,0ah,0ah,0ah
			dd 0fh,0fh,0fe19h,0ah,10ff05h,14h,14ff05h,6,8 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
			;03
			dd 06ff05h,0bh,5,01ffh,12 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
			;04
			dd 0bh,6,6,0ah,0ah,11 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
			;05
			dd 0fe05h,28h,23h,0ah,0ah,1,0,2,8 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
			;06
			dd 06ffh,5,0ffh,0,0ff05h,6,5,0,5,5,0ffh,0bh,14h,0,0,0
			dd 16 dup (0)
			dd 16 dup (0)
			dd 16 dup (0)
	
	
		