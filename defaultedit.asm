.code

comment ~
;
_GetText2 proc uses esi edi ebx _pFI,_lpRI
	LOCAL @pEndO,@pEndN,@lpCur,@bIsUnicode
	LOCAL @nCurLine
	mov ebx,_pFI
	assume ebx:ptr _FileInfo
	mov edi,[ebx].lpStream
	mov @lpCur,edi
	mov eax,edi
	add eax,[ebx].nStreamSize
	mov @pEndO,eax

	;计算行数
	.if word ptr [edi]==0feffh
		mov @bIsUnicode,1
		mov [ebx].nCharSet,CS_UNICODE
		add edi,2
_ForceUniGT:
		xor ecx,ecx
		.repeat
			.if word ptr [edi]==0dh
				inc ecx
			.endif
			add edi,2
		.until edi>=@pEndO || !word ptr [edi]
		inc ecx
	.elseif word ptr [edi]==0bbefh && byte ptr [edi+2]==0bfh
		mov [ebx].nCharSet,CS_UTF8
		add edi,3
		mov @bIsUnicode,0
		jmp _ForceMBCS
	.else
		.if [ebx].nCharSet==CS_UNICODE
			mov @bIsUnicode,1
			jmp _ForceUniGT		
		.endif
		mov @bIsUnicode,0
_ForceMBCS:
		xor ecx,ecx
		.repeat
			.if word ptr [edi]==0a0dh
				inc ecx
			.endif
			inc edi
		.until edi>=@pEndO || !byte ptr [edi]
		inc ecx
	.endif
	mov [ebx].nLine,ecx
	inc ecx
	shl ecx,2
	mov edi,ecx
	
	lea eax,[edi+edi*2] ;eax=nLine*sizeof _StreamEntry 
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _NomemGT2
	mov [ebx].lpStreamIndex,eax
	mov esi,eax
	assume esi:ptr _StreamEntry
	invoke VirtualAlloc,0,edi,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _NomemGT2
	mov [ebx].lpTextIndex,eax
	mov edi,eax
	
	mov eax,@lpCur
	.if @bIsUnicode && word ptr [eax]==0feffh
		add eax,2
		mov @lpCur,eax
	.endif
	xor eax,eax
	mov @nCurLine,eax
	.while eax<[ebx].nLine
		mov ecx,@lpCur
		mov [esi].lpStart,ecx
		add esi,sizeof _StreamEntry
		invoke _GetStringInTxt,edi,addr @lpCur,[ebx].nCharSet
		or eax,eax
		jne _NomemGT2
		add edi,4
		.if dbTxtFunc+_TxtFunc.IsLineAdding
			push [edi-4]
			call dbTxtFunc+_TxtFunc.IsLineAdding
			.if !eax
				sub edi,4
				sub esi,sizeof _StreamEntry
				jmp @F
			.endif
		.endif
		.if dbTxtFunc+_TxtFunc.TrimLineHead
			push [edi-4]
			call dbTxtFunc+_TxtFunc.TrimLineHead
			add dword ptr [esi-sizeof _StreamEntry],eax
		.endif
		@@:
		inc @nCurLine
		mov eax,@nCurLine
	.endw
	assume esi:nothing
	sub edi,[ebx].lpTextIndex
	shr edi,2
	mov [ebx].nLine,edi
	mov [ebx].nMemoryType,MT_EVERYSTRING
	mov ecx,_lpRI
	mov dword ptr [ecx],RI_SUC_LINEONLY
	xor eax,eax
	ret
_NomemGT2:
	mov ecx,_lpRI
	mov dword ptr [ecx],RI_FAIL_MEM
	or eax,E_ERROR
	ret
_GetText2 endp
commentend~
;
_GetText proc uses esi edi ebx _pFI,_lpRI
	LOCAL @pEndO,@pEndN,@lpCur,@bIsUnicode
	LOCAL @nCurLine,@nLine
	LOCAL @pFilterInfo
	mov ebx,_pFI
	assume ebx:ptr _FileInfo
	mov edi,[ebx].lpStream
	mov @lpCur,edi
	mov eax,edi
	add eax,[ebx].nStreamSize
	mov @pEndO,eax
	
	mov eax,nCurMef
	.if eax==-1
		mov @pFilterInfo,0
	.else
		mov ecx,sizeof _MefInfo
		mul ecx
		add eax,lpMefs
		mov @pFilterInfo,eax
	.endif

	;计算行数
	.if word ptr [edi]==0feffh
		mov @bIsUnicode,1
		mov [ebx].nCharSet,CS_UNICODE
		add edi,2
_ForceUniGT:
		xor ecx,ecx
		.repeat
			.if word ptr [edi]==0dh
				inc ecx
			.endif
			add edi,2
		.until edi>=@pEndO || !word ptr [edi]
		inc ecx
	.elseif word ptr [edi]==0bbefh && byte ptr [edi+2]==0bfh
		mov [ebx].nCharSet,CS_UTF8
		add edi,3
		mov @bIsUnicode,0
		jmp _ForceMBCS
	.else
		.if [ebx].nCharSet==CS_UNICODE
			mov @bIsUnicode,1
			jmp _ForceUniGT		
		.endif
		mov @bIsUnicode,0
_ForceMBCS:
		xor ecx,ecx
		.repeat
			.if word ptr [edi]==0a0dh
				inc ecx
			.endif
			inc edi
		.until edi>=@pEndO || !byte ptr [edi]
		inc ecx
	.endif
	mov [ebx].nLine,ecx
	inc ecx
	shl ecx,2
	mov edi,ecx
	
	lea eax,[edi+edi*2] ;eax=nLine*sizeof _StreamEntry 
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _NomemGT2
	mov [ebx].lpStreamIndex,eax
	mov esi,eax
	assume esi:ptr _StreamEntry
	
	mov eax,@lpCur
	.if @bIsUnicode && word ptr [eax]==0feffh
		add eax,2
		mov @lpCur,eax
	.elseif word ptr [eax]==0bbefh && byte ptr [eax+2]==0bfh
		add eax,3
		mov @lpCur,eax
	.endif
	xor eax,eax
	mov @nCurLine,eax
	mov @nLine,eax
	mov edi,@pFilterInfo
	assume edi:ptr _MefInfo
	.while eax<[ebx].nLine
		mov ecx,@lpCur
		invoke _GetStringInTxt,esi,addr @lpCur,[ebx].nCharSet
		or eax,eax
		jne _NomemGT2
		.if edi
			push [ebx].nCharSet
			push esi
			call [edi].ProcessLine
			cmp eax,E_LINEDENIED
			jne _AddLineGT
		.else
		_AddLineGT:
			add esi,sizeof _StreamEntry
			inc @nLine
		.endif
		inc @nCurLine
		mov eax,@nCurLine
	.endw
	assume edi:nothing
	assume esi:nothing
	mov eax,@nLine
	mov [ebx].nLine,eax
	mov [ebx].nMemoryType,MT_POINTERONLY
	mov [ebx].nStringType,ST_SPECLEN
	mov ecx,_lpRI
	mov dword ptr [ecx],RI_SUC_LINEONLY
	xor eax,eax
	ret
_NomemGT2:
	mov ecx,_lpRI
	mov dword ptr [ecx],RI_FAIL_MEM
	or eax,E_ERROR
	ret
_GetText endp

;
_SaveText proc uses edi _pFI
	mov edi,_pFI
	assume edi:ptr _FileInfo
	invoke SetFilePointer,[edi].hFile,0,0,FILE_BEGIN
	invoke WriteFile,[edi].hFile,[edi].lpStream,[edi].nStreamSize,offset dwTemp,0
	or eax,eax
	je _ErrST
	invoke SetEndOfFile,[edi].hFile
	or eax,eax
	je _ErrST
	assume edi:nothing
	xor eax,eax
	ret
_ErrST:
	mov eax,E_FILEACCESSERROR
	ret
_SaveText endp

;
_ModifyLineA proc uses esi edi ebx _pFI,_nLine
	LOCAL @pTemp,@pNewStr,@pNewLen
	mov edi,_pFI
	assume edi:ptr _FileInfo
	invoke _GetStringInList,_pFI,_nLine
	.if !eax
		mov eax,E_LINENOTEXIST
		jmp _ExMLA
	.endif
	mov ebx,eax
	invoke lstrlenW,ebx
	shl eax,2
	mov @pNewLen,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	.if !eax
		mov eax,E_NOMEM
		jmp _ExMLA
	.endif
	mov @pNewStr,eax
	mov esi,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2] ;sizeof _StreamEntry
	lea esi,[esi+eax*4]
	assume esi:ptr _StreamEntry
	
	invoke WideCharToMultiByte,[edi].nCharSet,0,ebx,-1,@pNewStr,@pNewLen,0,0
	.if !eax
		invoke HeapFree,hGlobalHeap,0,@pNewStr
		mov eax,E_NOTENOUGHBUFF
		jmp _ExMLA
	.endif
	dec eax
	mov @pNewLen,eax
	
	mov ecx,[edi].nStreamSize
	add ecx,[edi].lpStream
	sub ecx,[esi].lpStart
	sub ecx,[esi].nStringLen
	invoke _ReplaceInMem,@pNewStr,@pNewLen,[esi].lpStart,[esi].nStringLen,ecx
	mov ebx,eax
	invoke HeapFree,hGlobalHeap,0,@pNewStr
	or ebx,ebx
	jne _ExMLA
	
	mov eax,@pNewLen
	mov ecx,[esi].nStringLen
	mov [esi].nStringLen,eax
	sub eax,ecx
	add esi,sizeof _StreamEntry
	.if eax
		.while dword ptr [esi]
			add [esi].lpStart,eax
			add esi,sizeof _StreamEntry
		.endw
		add [edi].nStreamSize,eax
	.endif
	mov eax,[edi].lpStream
	add eax,[edi].nStreamSize
	mov word ptr [eax],0
	assume edi:nothing
	assume esi:nothing
	
	xor eax,eax
_ExMLA:
	ret
_ModifyLineA endp

_ModifyLineW proc uses esi edi ebx _pFI,_nLine
	LOCAL @pTemp,@pNewStr,@pNewLen
	mov edi,_pFI
	assume edi:ptr _FileInfo
	invoke _GetStringInList,_pFI,_nLine
	.if !eax
		mov eax,E_LINENOTEXIST
		jmp _ExMLW
	.endif
	mov ebx,eax
	invoke lstrlenW,ebx
	shl eax,1
	mov @pNewLen,eax
	mov esi,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	lea esi,[esi+eax*4]
	
	assume esi:ptr _StreamEntry
	mov eax,[edi].nStreamSize
	add eax,[edi].lpStream
	sub eax,[esi].lpStart
	sub eax,[esi].nStringLen
	invoke _ReplaceInMem,ebx,@pNewLen,[esi].lpStart,[esi].nStringLen,eax
	or eax,eax
	jne _ExMLW
	
	mov eax,@pNewLen
	mov ecx,[esi].nStringLen
	mov [esi].nStringLen,eax
	sub eax,ecx
	add esi,sizeof _StreamEntry
	.if eax
		.while dword ptr [esi]
			add [esi].lpStart,eax
			add esi,sizeof _StreamEntry
		.endw
		add [edi].nStreamSize,eax
	.endif
	mov eax,[edi].lpStream
	add eax,[edi].nStreamSize
	mov word ptr [eax],0
	assume edi:nothing
	assume esi:nothing
	
	xor eax,eax
_ExMLW:
	ret
_ModifyLineW endp

_ModifyLine proc uses esi edi ebx _pFI,_nLine
	mov eax,_pFI
	.if dword ptr [eax+_FileInfo.nCharSet]==CS_UNICODE
		invoke _ModifyLineW,_pFI,_nLine
	.else
		invoke _ModifyLineA,_pFI,_nLine
	.endif
	ret
_ModifyLine endp

;
_GetStringInTxt proc uses esi edi _lpStreamEntry,_lppBuff,_nCharSet
	LOCAL @nStrLen,@lpTmpBuff
	mov eax,_lppBuff
	mov eax,[eax]
	mov esi,_lpStreamEntry
	assume esi:ptr _StreamEntry
	mov [esi].lpStart,eax
	mov ecx,_nCharSet
	push offset _HandlerGSFM	;防止lpbuff内存越界访问
	push fs:[0]
	mov fs:[0],esp
	mov edx,_nCharSet
	mov edi,[esi].lpStart
	.if edx==CS_UNICODE
		xor ecx,ecx
		.while word ptr [edi]!=0dh
			.break .if !word ptr [edi]
			add edi,2
			add ecx,2
		.endw
		mov [esi].nStringLen,ecx
		lea edi,[edi+4]
		mov ecx,_lppBuff
		mov [ecx],edi
		pop fs:[0]
		add esp,4
	.else
		xor ecx,ecx
		.while word ptr [edi]!=0a0dh
			.break .if !byte ptr [edi]
			inc edi
			inc ecx
		.endw
		mov [esi].nStringLen,ecx
		lea eax,[edi+2]
		mov ecx,_lppBuff
		mov [ecx],eax
		pop fs:[0]
		add esp,4
	.endif
	assume esi:nothing
	xor eax,eax
_ExGSFM:
	ret
_ErrOverMemGSFM:
	pop fs:[0]
	pop ecx
	mov eax,E_OVERMEM
	jmp _ExGSFM
_HandlerGSFM:
	mov eax,[esp+0ch]
	mov [eax+0b8h],offset _ErrOverMemGSFM
	xor eax,eax
	ret
_GetStringInTxt endp

;
_ReplaceInMem proc uses esi edi _lpNew,_nNewLen,_lpOriPos,_nOriLen,_nLeftLen
	mov eax,_nNewLen
	.if eax==_nOriLen || !_nLeftLen
		mov esi,_lpNew
		mov edi,_lpOriPos
		mov ecx,eax
		rep movsb
		xor eax,eax
	.elseif eax>_nOriLen
	@@:
		invoke HeapAlloc,hGlobalHeap,0,_nLeftLen
		.if !eax
			mov eax,E_NOMEM
			jmp _ExRIM
		.endif
		push eax
		mov ecx,_nLeftLen
		mov esi,_lpOriPos
		add esi,_nOriLen
		mov edi,eax
		invoke _memcpy
		mov esi,_lpNew
		mov ecx,_nNewLen
		mov edi,_lpOriPos
		rep movsb
		mov esi,[esp]
		mov ecx,_nLeftLen
		invoke _memcpy
		push 0
		push hGlobalHeap
		call HeapFree
		xor eax,eax
	.else
		mov ecx,_nOriLen
		sub ecx,eax
		cmp ecx,4
		jb @B
		mov esi,_lpNew
		mov ecx,_nNewLen
		mov edi,_lpOriPos
		rep movsb
		mov esi,_lpOriPos
		add esi,_nOriLen
		mov ecx,_nLeftLen
		invoke _memcpy
		xor eax,eax
	.endif
_ExRIM:
	ret
_ReplaceInMem endp

;
_SetLine2 proc uses esi ebx _lpsz,_lpRange
	cmp _lpRange,0
	je _ExSL
	mov esi,_lpsz
	invoke lstrlenW,esi
	mov ebx,eax
	.if word ptr [esi]==3000h
		mov eax,_lpRange
		mov dword ptr [eax],1
	.endif
	
	xor ecx,ecx
	.while ecx<ebx
		lodsw
		.if ax==300ch || ax==300eh
			mov eax,_lpRange
			inc ecx
			mov [eax],ecx
			.break
		.endif
		inc ecx
	.endw
	
	mov esi,_lpsz
	lea esi,[esi+ebx*2]
	.while ebx
		dec ebx
		sub esi,2
		mov ax,[esi]
		.if ax==300dh || ax==300fh
			mov eax,_lpRange
			mov [eax+4],ebx
			.break
		.endif
	.endw

_ExSL:
	ret
_SetLine2 endp

_SetLine proc uses esi ebx _lpsz,_lpRange
	LOCAL @mr:_RegexpResult
	cmp _lpRange,0
	je _ExSL
	.if hRegSelText==-1
		invoke _RegInitW,offset szPatQuotes,0,offset hRegSelText
	.endif
	mov @mr.bIsMatched,FALSE
	invoke _RegMatchW,hRegSelText,_lpsz,0,addr @mr
	.if @mr.bIsMatched
		mov ecx,_lpRange
		mov eax,dword ptr @mr.rGroups[0]
		mov [ecx],eax
		mov eax,dword ptr @mr.rGroups[4]
		mov [ecx+4],eax
	.endif
_ExSL:
	ret
_SetLine endp

_RetLine proc _lpsz
	mov edx,_lpsz
	.while word ptr [edx]!=0
		.if word ptr [edx]==0ah || word ptr [edx]==0dh
			mov eax,E_LINEDENIED
			jmp _ExRL
		.endif
		add edx,2
	.endw
	xor eax,eax
_ExRL:
	ret
_RetLine endp
