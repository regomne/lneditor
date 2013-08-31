.386
.model flat,stdcall
option casemap:none

include Circus2.inc

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

;判断文件头
Match proc uses esi _lpszName
	LOCAL @szMagic[5]:dword
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
	.if dword ptr [edx]!=4d002eh || dword ptr [edx+4]!=0530045h
		mov eax,MR_NO
		ret
	.endif
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _ErrMatch
	push eax
	lea esi,@szMagic
	invoke ReadFile,eax,esi,20,offset dwTemp,0
	call CloseHandle
	lodsd
	.if eax<=4
		mov eax,MR_MAYBE
		RET
	.endif
	cmp eax,0ffffh
	ja _Maybe
	mov eax,[esi]
	cmp eax,3
	jne _Maybe
	mov eax,MR_YES
	ret
_Maybe:
	mov eax,MR_MAYBE
	ret
_NotMatch:
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

;
CircusGetLine proc uses esi edi _lpStr,_nCS
	LOCAL @nLen,@nChar
	LOCAL @pStr,@pStr2
	invoke lstrlenA,_lpStr
	mov @nLen,eax
	inc eax
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Ex
	mov @pStr2,eax
	mov edi,eax
	mov esi,_lpStr
	mov ecx,@nLen
	.if !ecx
		mov word ptr [edi],0
		mov @pStr,edi
		jmp _Ex2
	.endif
	mov @nChar,0
	@@:
		lodsb
		add al,20h
		.if al>80h && ecx
			stosb
			lodsb
			add al,20h
			stosb
			dec ecx
			inc @nChar
		.elseif al==0ah
			mov ax,6e5ch
			stosw
			add @nChar,2
		.else
			stosb
			inc @nChar
		.endif
	loop @B
	mov byte ptr [edi],0
	
	inc @nChar
	mov ecx,@nChar
	shl ecx,1
	invoke HeapAlloc,hHeap,0,ecx
	.if !eax
		invoke HeapFree,hHeap,0,@pStr2
		xor eax,eax
		jmp _Ex
	.endif
	mov @pStr,eax
	
	mov eax,@nChar
	invoke MultiByteToWideChar,_nCS,0,@pStr2,-1,@pStr,eax
	.if !eax
		invoke HeapFree,hHeap,0,@pStr
		invoke HeapFree,hHeap,0,@pStr2
		xor eax,eax
		jmp _Ex
	.endif
	invoke HeapFree,hHeap,0,@pStr2
_Ex2:
	mov eax,@pStr
_Ex:
	ret
CircusGetLine endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd
	LOCAL @lpIndex,@nIndex
	LOCAL @lpContent
	LOCAL @nInst
	LOCAL @nLine
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStream
	
	lodsd
	mov @nIndex,eax
	mov @lpIndex,esi
	lea eax,[eax+eax*2]
	add eax,eax
	add esi,eax
	mov @lpContent,esi
	
	shl eax,1
	mov ebx,eax
	lea eax,[eax+eax*2]
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpStreamIndex,eax
	invoke VirtualAlloc,0,ebx,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpTextIndex,eax
	
	xor ebx,ebx
	mov @nLine,ebx
	mov @nInst,ebx
	;mov byte ptr [@nInst+1],37h
	.while ebx<@nIndex
		mov ecx,@lpIndex
		mov esi,[ecx+ebx*4]
		and esi,7fffffffh
		add esi,@lpContent
	_Cntline:
		lodsb
		.if al==4fh || al==50h
			mov byte ptr @nInst,al
			invoke CircusGetLine,esi,[edi].nCharSet
			or eax,eax
			je _Nextline
			mov ecx,[edi].lpTextIndex
			mov edx,@nLine
			mov [ecx+edx*4],eax
			mov ecx,[edi].lpStreamIndex
			lea edx,[edx+edx*2]
			mov _StreamEntry.lpStart[ecx+edx*4],esi
			inc @nLine
			
			invoke lstrlenA,esi
			lea esi,[esi+eax+1]
			lodsb
			mov cl,byte ptr [@nInst+1]
			inc cl
			.if al==38h || al==37h
				invoke lstrlenA,esi
				lea esi,[esi+eax+1]
				lodsb
			.endif
			mov cl,byte ptr @nInst
			inc cl
			.if al==cl
				invoke CircusGetLine,esi,[edi].nCharSet
				or eax,eax
				je _Nextline
				mov edx,@nLine
				mov ecx,[edi].lpTextIndex
				mov [ecx+edx*4],eax
				mov ecx,[edi].lpStreamIndex
				lea edx,[edx+edx*2]
				mov _StreamEntry.lpStart[ecx+edx*4],esi
				inc @nLine
			.endif
		.elseif al==38h || al==37h
			mov byte ptr [@nInst+1],al
			invoke lstrlenA,esi
			lea esi,[esi+eax+1]
			mov al,byte ptr [@nInst+1]
			inc al
			.if byte ptr [esi]==38h
				invoke lstrlenA,esi
				lea esi,[esi+eax+1]
				mov byte ptr [@nInst+1],0
			.endif
			jmp _Cntline
		.elseif al==8
			add esi,2
			lodsb
			.while al>=44h && al<=60h
				invoke lstrlenA,esi
				lea esi,[esi+eax+2]
				invoke CircusGetLine,esi,[edi].nCharSet
				or eax,eax
				je _Nextline
				mov edx,@nLine
				mov ecx,[edi].lpTextIndex
				mov [ecx+edx*4],eax
				mov ecx,[edi].lpStreamIndex
				lea edx,[edx+edx*2]
				mov _StreamEntry.lpStart[ecx+edx*4],esi
				inc @nLine
				invoke lstrlenA,esi
				lea esi,[esi+eax+1]
				lodsb
			.endw
		.endif
	_Nextline:
		inc ebx
	.endw
	mov eax,@nLine
	mov [edi].nLine,eax
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
CircusSetLine proc uses esi edi _lpStr,_nCS
	LOCAL @nChar,@pStr2,@pStr
	invoke lstrlenW,_lpStr
	mov @nChar,eax
	inc eax
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Err
	mov @pStr2,eax
	mov esi,_lpStr
	mov edi,eax
	mov ecx,@nChar
	@@:
		lodsw
		.if ax=='\' && word ptr [esi]=='n'
			add esi,2
			mov ax,0ah
		.endif
		stosw
	loop @B
	mov word ptr [edi],0
	sub edi,@pStr2
	inc edi
	invoke HeapAlloc,hHeap,0,edi
	.if !eax
		invoke HeapFree,hHeap,0,@pStr2
		jmp _Err
	.endif
	mov @pStr,eax
	invoke WideCharToMultiByte,_nCS,0,@pStr2,-1,@pStr,edi,0,0
	.if !eax
		invoke HeapFree,hHeap,0,@pStr2
		invoke HeapFree,hHeap,0,@pStr
		jmp _Err
	.endif
	mov esi,@pStr
	lea edx,[eax+esi-1]
	.while esi<edx
		sub byte ptr [esi],20h
		inc esi
	.endw
	invoke HeapFree,hHeap,0,@pStr2
	mov eax,@pStr
	ret
_Err:
	xor eax,eax
	ret
CircusSetLine endp

CircusCheckLine proc _lpStr
	mov esi,_lpStr
	cmp word ptr [esi],0
	je _Err
	.repeat
		lodsw
		.break .if !ax
		.if ax=='\' && word ptr [esi]=='n'
			add esi,2
			.continue
		.endif
		.if ax=='$' && word ptr [esi]=='n'
			add esi,2
			.continue
		.endif
		.if ax=='@' && word ptr [esi]=='K'
			add esi,2
			.continue
		.endif
;		.if ax<80h
;			int 3
;		.endif
		cmp ax,80h
		jbe _Err
	.until 0
	mov eax,1
	ret
_Err:
	xor eax,eax
	ret
CircusCheckLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
;	invoke CircusCheckLine,ebx
;	.if !eax
;		mov eax,E_LINEDENIED
;		jmp _Ex
;	.endif
	invoke CircusSetLine,ebx,[edi].nCharSet
	.if !eax
		mov eax,E_LINEDENIED
		jmp _Ex
	.endif
	mov @pNewStr,eax
	invoke lstrlenA,eax
	mov @nNewLen,eax
	
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	lea esi,[ecx+eax*4]
	assume esi:ptr _StreamEntry
	invoke lstrlenA,[esi].lpStart
	
	.if eax==@nNewLen
		mov edi,[esi].lpStart
		mov esi,@pNewStr
		mov ecx,eax
		rep movsb
	.else
		mov @nOldLen,eax
		mov ecx,[edi].nStreamSize
		add ecx,[edi].lpStream
		sub ecx,[esi].lpStart
		sub ecx,@nOldLen
		invoke _ReplaceInMem,@pNewStr,@nNewLen,[esi].lpStart,@nOldLen,ecx
		.if eax
			mov ebx,eax
			invoke HeapFree,hHeap,0,@pNewStr
			mov eax,ebx
			jmp _Ex
		.endif
		
		mov ecx,@nNewLen
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
		
		mov edx,[esi].lpStart
		mov esi,[edi].lpStream
		lodsd
		mov ecx,eax
		shl eax,2
		;应对DC3RX
		lea eax,[eax+ecx*2]
		add eax,esi
		sub edx,eax
		@@:
			mov eax,dword ptr [esi]
			and eax,7fffffffh
			.if eax>edx
				add dword ptr [esi],ebx
			.endif
			add esi,4
		loop @B
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