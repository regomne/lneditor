.386
.model flat,stdcall
option casemap:none

include system4.inc
include prescan.asm

.code

assume fs:nothing
;
DllMain proc _hInstance,_dwReason,_dwReserved
	.if _dwReason==DLL_PROCESS_ATTACH
		push _hInstance
		pop hInstance
	.ENDIF
	mov eax,TRUE
	ret
DllMain endp

;ÅÐ¶ÏÎÄ¼þÍ·
Match proc uses esi edi _lpszName
	LOCAL @szMagic[10h]:byte
	invoke CreateFileW,_lpszName,GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _ErrMatch
	push eax
	lea ecx,@szMagic
	invoke ReadFile,eax,ecx,10h,offset dwTemp,0
	call CloseHandle
	lea esi,@szMagic
	mov edi,$CTA0("MajiroObjX1.000")
	mov ecx,10h
	repe cmpsb
	.if ZERO?
		mov eax,MR_YES
		ret
	.endif
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

;
PreProc proc _lpPreData
	mov ecx,_lpPreData
	assume ecx:ptr _PreData
	mov eax,[ecx].hGlobalHeap
	mov hHeap,eax
	assume ecx:nothing
	ret
PreProc endp

;
GetText proc uses edi ebx esi _lpFI,_lpRI
	ret
GetText endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	ret
ModifyLine endp

;
SaveText proc uses edi ebx esi _lpFI
SaveText endp

GetStr proc uses esi edi ebx _lpFI,_lppString,_lpBuff
GetStr endp

Release proc uses ebx _lpFI
Release endp

;
SetLine proc
	jmp _SetLine
SetLine endp

end DllMain