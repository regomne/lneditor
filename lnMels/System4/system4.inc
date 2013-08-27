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
	

ModifyLine proto :dword,:dword
SaveText proto :dword
Release proto :dword
_memcpy2 proto :dword,:dword,:dword

_Segment struct
	lpAddr		dd		?
	nSize		dd		?
_Segment ends

_AinSegs struct
	Version		_Segment		<>
	Code		_Segment		<>
	Function		_Segment		<>
	GlobalVar	_Segment		<>
	GlobalSet	_Segment		<>
	Structs		_Segment		<>
	Message0	_Segment		<>
	Main		_Segment		<>
	MessageFunc	_Segment		<>
	HLL			_Segment		<>
	SwitchData	_Segment		<>
	GameVersion	_Segment		<>
	SLBL			_Segment		<>
	Strings		_Segment		<>
	FileName		_Segment		<>
	Onjump		_Segment		<>
	FuctionType	_Segment		<>
	KeyC		_Segment		<>
_AinSegs ends

.data?
	hInstance		dd		?
	hHeap		dd		?

	dwTemp		dd		?
	
.const
	
	
	
		