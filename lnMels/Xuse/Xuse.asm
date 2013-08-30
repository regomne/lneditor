.386
.model flat,stdcall
option casemap:none

include Xuse.inc

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

;
InitInfo proc _lpMelInfo2
	mov ecx,_lpMelInfo2
	mov _MelInfo2.nInterfaceVer[ecx],00030000h
	mov _MelInfo2.nCharacteristic[ecx],MIC_NOHALFANGLE or MIC_CUSTOMCONFIG
	ret
InitInfo endp

;
PreProc proc _lpPreData
	mov ecx,_lpPreData
	assume ecx:ptr _PreData
	mov eax,[ecx].hGlobalHeap
	mov hHeap,eax
	assume ecx:nothing
	ret
PreProc endp

;ÅÐ¶ÏÎÄ¼þÍ·
Match proc uses esi _lpszName
	LOCAL @szMagic[8]:byte
	LOCAL @sExtend[8]:byte
	invoke lstrlenW,_lpszName
	mov ecx,_lpszName
	lea ecx,[ecx+eax*2-8]
	lea edx,@sExtend
	mov eax,[ecx]
	mov [edx],eax
	mov eax,[ecx+4]
	mov [edx+4],eax
	and dword ptr [edx],0ffdfffffh
	and dword ptr [edx+4],0ffdfffdfh
	.if dword ptr [edx]==42002eh && dword ptr [edx+4]==04e0049h
		invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		cmp eax,-1
		je _ErrMatch
		push eax
		lea esi,@szMagic
		invoke ReadFile,eax,esi,8,offset dwTemp,0
		call CloseHandle
		.if dword ptr [esi]=='IRON' && dword ptr [esi+4]==10000h
			mov eax,MR_YES
			ret
		.endif
	.endif
_NotMatch:
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

XorDecode proc _lpBuff,_len
	mov edx,_lpBuff
	mov eax,_len
	xor ecx,ecx
	.while ecx<eax
		xor byte ptr [edx+ecx],53h
		inc ecx
	.endw
	ret
XorDecode endp

;
XuseGetLine proc uses esi edi ebx _lpStr,_nLen,_nCS
	LOCAL @pStr,@pStr2
	mov eax,_nLen
	inc eax
	shl eax,1
	mov ebx,eax
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Ex
	mov @pStr,eax
	invoke HeapAlloc,hHeap,0,ebx
	.if !eax
		invoke HeapFree,hHeap,0,@pStr
		jmp _Ex
	.endif
	mov @pStr2,eax
	mov esi,_lpStr
	mov edi,eax
	mov ecx,_nLen
	rep movsb
	invoke XorDecode,@pStr2,_nLen
	mov eax,ebx
	shr eax,1
	invoke MultiByteToWideChar,_nCS,0,@pStr2,_nLen,@pStr,eax
	mov ecx,@pStr
	mov word ptr [ecx+eax*2],0
	invoke HeapFree,hHeap,0,@pStr2
	mov eax,@pStr
_Ex:
	ret
XuseGetLine endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd
	LOCAL @nLine
	LOCAL @lpString,@nStringLen
	LOCAL @lpCode,@nCodeLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStream
	
	assume esi:ptr XuseHeader
	mov eax,esi
	add eax,[esi].nFunc1Len
	add eax,[esi].nFunc2Len
	add eax,[esi].nFunc3Len
	lea ecx,[eax+sizeof XuseHeader+4*2]
	mov @lpCode,ecx
	mov edx,[esi].nCodeLen
	mov @nCodeLen,edx
	add eax,edx
	add eax,sizeof XuseHeader+5*2
	mov @lpString,eax
	mov ecx,[esi].nStringLen
	mov @nStringLen,ecx
	assume esi:nothing
	
	shr edx,1
	mov ebx,edx
	lea eax,[edx+edx*2]
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpStreamIndex,eax
	invoke VirtualAlloc,0,ebx,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpTextIndex,eax
	
	xor ebx,ebx
	mov esi,@lpCode
	mov eax,esi
	add eax,@nCodeLen
	mov @pEnd,eax
	.while esi<@pEnd
		mov ax,[esi]
		.if ax==5
			movzx eax,word ptr [esi+2]
			or eax,eax
			je _Ctn
			mov ecx,[esi+4]
			add ecx,@lpString
			invoke XuseGetLine,ecx,eax,[edi].nCharSet
			or eax,eax
			je _Nomem
			mov ecx,[edi].lpTextIndex
			mov [ecx+ebx*4],eax
			mov edx,[edi].lpStreamIndex
			lea eax,[ebx+ebx*2]
			mov [edx+eax*4],esi
			inc ebx
		.endif
	_Ctn:
		add esi,8
	.endw
	
	mov [edi].nLine,ebx
	mov [edi].nMemoryType,MT_EVERYSTRING
	
	assume edi:nothing
	mov ecx,_lpRI
	xor eax,eax
	mov dword ptr [ecx],RI_SUC_LINEONLY
_Ex:
	ret
_Nomem:
	mov eax,E_NOMEM
	ret
GetText endp

;
XuseSetLine proc uses ebx _lpStr,_nCS
	LOCAL @nChar,@pStr2,@pStr
	invoke lstrlenW,_lpStr
	mov @nChar,eax
	
	inc eax
	shl eax,1
	mov ebx,eax
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Err
	mov @pStr,eax
	invoke WideCharToMultiByte,_nCS,0,_lpStr,-1,@pStr,ebx,0,0
	.if eax
		lea ebx,[eax-1]
		invoke XorDecode,@pStr,ebx
		mov ecx,ebx
	.else
		xor ecx,ecx
	.endif
	mov eax,@pStr
	ret
_Err:
	xor eax,eax
	ret
XuseSetLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	LOCAL @lpString,@nStringLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	invoke XuseSetLine,ebx,[edi].nCharSet
	.if !eax
		mov eax,E_NOMEM
		jmp _Ex
	.endif
	mov @pNewStr,eax
	mov @nNewLen,ecx
	.if ecx>0ffffh
		mov eax,E_LINEDENIED
		jmp _Ex
	.endif
	
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	mov esi,_StreamEntry.lpStart[ecx+eax*4]
	movzx ecx,word ptr [esi+2]
	mov @nOldLen,ecx
	mov ebx,esi
	
	mov esi,[edi].lpStream
	assume esi:ptr XuseHeader
	mov eax,esi
	add eax,[esi].nFunc1Len
	add eax,[esi].nFunc2Len
	add eax,[esi].nFunc3Len
	add eax,[esi].nCodeLen
	add eax,sizeof XuseHeader+5*2
	mov @lpString,eax
	mov ecx,[esi].nStringLen
	mov @nStringLen,ecx
	assume esi:nothing
	
	mov ecx,@nOldLen
	.if ecx>=@nNewLen
		mov edi,[ebx+4]
		add edi,@lpString
		mov esi,@pNewStr
		mov ecx,@nNewLen
		mov word ptr [ebx+2],cx
		rep movsb
	.else
		mov edi,@nStringLen
		mov [ebx+4],edi
		add edi,@lpString
		mov esi,@pNewStr
		mov ecx,@nNewLen
		mov word ptr [ebx+2],cx
		rep movsb
		
		mov edi,_lpFI
		mov esi,[edi].lpStream
		mov eax,@nNewLen
		add XuseHeader.nStringLen[esi],eax
		add [edi].nStreamSize,eax
	.endif
	
	assume edi:nothing
_Success:
	invoke HeapFree,hHeap,0,@pNewStr
	xor eax,eax
_Ex:
	ret
ModifyLine endp

;
SaveText proc
	jmp _SaveText
SaveText endp

;
SetLine proc
	jmp _SetLine
SetLine endp

end DllMain