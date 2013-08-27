.386
.model flat,stdcall
option casemap:none

include Stuff.inc

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
	mov _MelInfo2.nCharacteristic[ecx],0
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
Match proc _lpszName
	LOCAL @szMagic[4]:byte
	LOCAL @sExtend[2]:dword
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
	.if dword ptr [edx]==4d002eh && dword ptr [edx+4]==0430053h
		invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		cmp eax,-1
		je _ErrMatch
		push eax
		lea ecx,@szMagic
		invoke ReadFile,eax,ecx,2,offset dwTemp,0
		call CloseHandle
		lea eax,@szMagic
		mov cx,[eax]
		.if cx==0 || cx==8888h
			mov eax,MR_YES
			ret
		.endif
	.endif
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

_XorBlock proc _buff,_size
	mov ecx,_size
	mov eax,_buff
	@@:
	xor byte ptr [eax],88h
	inc eax
	loop @B
	ret
_XorBlock endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStream
	.if word ptr [esi]==0
		mov [edi].lpCustom,0
	.elseif word ptr [esi]==8888h
		mov [edi].lpCustom,1
		invoke _XorBlock,[edi].lpStream,[edi].nStreamSize
	.else
		mov eax,E_WRONGFORMAT
		jmp _Ex
	.endif
	
	mov ecx,[edi].nStreamSize
	shr ecx,2
	lea ecx,[ecx+ecx*2]
	invoke VirtualAlloc,0,ecx,MEM_COMMIT,PAGE_READWRITE
	.if !eax
		mov eax,E_NOMEM
		jmp _Ex
	.endif
	mov [edi].lpStreamIndex,eax
	
	mov [edi].nMemoryType,MT_POINTERONLY
	mov [edi].nStringType,ST_PASCAL4
	
	mov ecx,esi
	add esi,dword ptr [esi+2]
	add ecx,[edi].nStreamSize
	mov @pEnd,ecx
	mov ebx,[edi].lpStreamIndex
	.while esi<@pEnd
		xor eax,eax
		lodsw
		movzx ecx,al
		shr eax,6
		.if ecx>6 || eax>0dch
			mov eax,E_WRONGFORMAT
			jmp _Ex
		.endif
		shl ecx,8
		add eax,ecx
		mov edx,[eax+offset ddTable]
		.while edx
			movzx eax,dl
			.if eax<0f0h
				add esi,eax
			.elseif eax==0ffh
				lodsd
				add esi,eax
			.elseif eax==0feh
				lodsd
				or eax,eax
				je @F
				lea ecx,[esi-4]
				mov _StreamEntry.lpStart[ebx],ecx
				add ebx,sizeof _StreamEntry
				add esi,eax
			.endif
			@@:
			shr edx,8
		.endw
	.endw
	sub ebx,[edi].lpStreamIndex
	mov eax,ebx
	xor edx,edx
	mov ecx,12
	div ecx
	mov [edi].nLine,eax
	
	assume edi:nothing
	mov ecx,_lpRI
	xor eax,eax
	mov dword ptr [ecx],RI_SUC_LINEONLY
_Ex:
	ret
GetText endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	LOCAL @lpOffset2
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	mov esi,[ecx+eax*4]
	invoke _GetStringInList,_lpFI,_nLine
	mov ebx,eax
	invoke lstrlenW,eax
	inc eax
	shl eax,1
	mov @nNewLen,eax
	invoke HeapAlloc,hHeap,0,eax
	.if !eax
		mov eax,E_NOMEM
		Jmp _Ex
	.endif
	mov @pNewStr,eax
	invoke WideCharToMultiByte,[edi].nCharSet,0,ebx,-1,@pNewStr,@nNewLen,0,0
	.if !eax
		invoke HeapFree,hHeap,0,@pNewStr
		mov eax,E_CODEFAILED
		JMP _Ex
	.endif
	dec eax
	mov @nNewLen,eax
	lodsd
	.if eax==@nNewLen
		mov edi,esi
		mov esi,@pNewStr
		mov ecx,eax
		rep movsb
	.else
		mov @nOldLen,eax
		mov ecx,[edi].nStreamSize
		add ecx,[edi].lpStream
		sub ecx,esi
		sub ecx,@nOldLen
		invoke _ReplaceInMem,@pNewStr,@nNewLen,esi,@nOldLen,ecx
		.if eax
			mov ebx,eax
			invoke HeapFree,hHeap,0,@pNewStr
			mov eax,ebx
			jmp _Ex
		.endif
		mov ecx,@nNewLen
		mov [esi-4],ecx
		
		sub ecx,@nOldLen
		add [edi].nStreamSize,ecx
		mov ebx,ecx
		
		mov ecx,[edi].lpStreamIndex
		mov eax,_nLine
		inc eax
		.while eax<[edi].nLine
			lea edx,[eax+eax*2]
			add _StreamEntry.lpStart[ecx+edx*4],ebx
			inc eax
		.endw
		
		mov eax,esi
		mov esi,[edi].lpStream
		assume edi:nothing
		mov edi,eax
		sub edi,esi
		mov eax,[esi+6]
		sub edi,dword ptr [esi+2]
		lea edx,[esi+eax+0ah]
		mov @lpOffset2,edx
		mov ecx,38e38e39h
		mul ecx
		shr edx,1
		test edx,edx
		jz _Cr2
		add esi,0ah+5
		.while edx
			.if dword ptr [esi]>edi
				add dword ptr [esi],ebx
			.endif
			add esi,09
			dec edx
		.endw
		
	_Cr2:
		mov esi,@lpOffset2
		mov eax,[esi]
		add esi,9
		mov ecx,38e38e39h
		mul ecx
		shr edx,1
		test edx,edx
		jz _Success
		.while edx
			.if dword ptr [esi]>edi
				add dword ptr [esi],ebx
			.endif
			add esi,09
			dec edx
		.endw
		
	.endif
	
	assume edi:nothing
_Success:
	invoke HeapFree,hHeap,0,@pNewStr
	xor eax,eax
_Ex:
	ret
ModifyLine endp

;
SaveText proc _lpFI
	mov ecx,_lpFI
	.if _FileInfo.lpCustom[ecx]
		invoke _XorBlock,_FileInfo.lpStream[ecx],_FileInfo.nStreamSize[ecx]
		invoke _SaveText,_lpFI
		push eax		
		mov ecx,_lpFI
		invoke _XorBlock,_FileInfo.lpStream[ecx],_FileInfo.nStreamSize[ecx]
		pop eax
		ret
	.endif
	invoke _SaveText,_lpFI
	ret
SaveText endp

;
SetLine proc
	jmp _SetLine
SetLine endp

end DllMain