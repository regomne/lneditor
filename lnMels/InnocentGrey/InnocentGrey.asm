.386
.model flat,stdcall
option casemap:none

include InnocentGrey.inc

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

;判断文件头
Match proc uses esi _lpszName
	LOCAL @szMagic[5]:dword
	LOCAL @sExtend[2]:dword
	invoke lstrlenW,_lpszName
	mov ecx,_lpszName
	lea ecx,[ecx+eax*2-4]
	lea edx,@sExtend
	mov eax,[ecx]
	mov [edx],eax
	and dword ptr [edx],0ffdfffffh
	.if dword ptr [edx]==53002eh
		mov eax,MR_YES
		ret
	.endif
_NotMatch:
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

;
_Decode proc _buff,_size
	mov eax,_buff
	mov ecx,_size
	_lbl1:
	xor byte ptr [eax],0ffh
	inc eax
	dec ecx
	jnz _lbl1
	ret
_Decode endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd
	LOCAL @lpIndex,@nIndex,@nCount
	LOCAL @lpContent
	LOCAL @pJTbl
	LOCAL @nLine,@nJEntry
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStream
	
	invoke _Decode,esi,[edi].nStreamSize
	
	mov eax,[edi].nStreamSize
	shr eax,2
	lea eax,[eax+eax*2]
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpStreamIndex,eax
	
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,sizeof IGInfo
	or eax,eax
	je _Nomem
	mov [edi].lpCustom,eax
	mov eax,[edi].nStreamSize
	shr eax,2
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Nomem
	mov ecx,[edi].lpCustom
	mov IGInfo.lpJumpTable[ecx],eax
	mov @pJTbl,eax
	
	mov eax,[edi].lpStream
	mov esi,eax
	add eax,[edi].nStreamSize
	mov @pEnd,eax
	
	mov ebx,[edi].lpStreamIndex
	assume ebx:ptr _StreamEntry
	xor eax,eax
	mov @nLine,eax
	.while esi<@pEnd
		xor eax,eax
		mov al,[esi]
		.if eax>0bfh
			int 3
			mov eax,E_WRONGFORMAT
			jmp _Ex
		.endif
		mov al,[eax+OpTypeTable]
		.if al==-1
			int 3
		.endif
		jmp dword ptr [eax*4+_JmpTable1]
	_case0:	;其他
		mov al,[esi+1]
		add esi,eax
		jmp _caseOut
	_case1:	;字符串
		mov al,[esi]
		.if al==3fh || al==0
			mov al,[esi+1]
			lea edx,[esi+3]
			mov [ebx].lpInformation,edx
			add esi,eax
			mov [ebx].lpStart,esi
			mov al,[edx]
			mov [ebx].nStringLen,eax
			add esi,eax
			inc @nLine
			add ebx,sizeof _StreamEntry
		.else
			mov al,[esi+1]
			xor edx,edx
			mov dl,[esi+3]
			add eax,edx
			add esi,eax
		.endif
		jmp _caseOut
	_case2:	
		lea eax,[esi+0ch]
		jmp _lbl2
	_case3:
		lea eax,[esi+4]
		_lbl2:
		mov edx,@pJTbl
		mov [edx],eax
		add @pJTbl,4
		xor eax,eax
		mov al,[esi+1]
		add esi,eax
		jmp _caseOut
	_case4:
		mov al,[esi+1]
		xor ecx,ecx
		mov cl,[esi+7]
		add esi,eax
		add esi,ecx
		jmp _caseOut
	_case5:
		mov al,[esi+1]
		xor ecx,ecx
		mov cl,[esi+8]
		add esi,eax
		add esi,ecx
		jmp _caseOut
	_case6:	;选择支
		mov edx,@pJTbl
		lea ecx,[esi+4]
		mov [edx],ecx
		add @pJTbl,4
		mov al,[esi+1]
		xor ecx,ecx
		lea edx,[esi+2]
		mov cl,[edx]
		mov [ebx].lpInformation,edx
		mov [ebx].nStringLen,ecx
		add esi,eax
		mov [ebx].lpStart,esi
		inc @nLine
		add ebx,sizeof _StreamEntry
		add esi,ecx
		jmp _caseOut
	_case7:
		mov al,[esi]
		.if al==3eh
			int 3
			mov eax,E_WRONGFORMAT
			jmp _Ex
		.endif
		.if al==8dh
			xor ecx,ecx
			mov edx,@pJTbl
			.while ecx<12
				lea eax,[esi+ecx*4+4]
				.if dword ptr [eax]
					mov [edx],eax
					add edx,4
				.endif
				inc ecx
			.endw
			mov @pJTbl,edx
			xor eax,eax
			mov al,[esi+1]
			add esi,eax
		.elseif al==97h || al==0a1h
			xor ecx,ecx
			mov edx,@pJTbl
			.while ecx<20
				lea eax,[esi+ecx*4+4]
				.if dword ptr [eax]
					mov [edx],eax
					add edx,4
				.endif
				inc ecx
			.endw
			mov @pJTbl,edx
			xor eax,eax
			mov al,[esi+1]
			add esi,eax
		.else
			xor ecx,ecx
			xor eax,eax
			mov al,[esi+1]
			shr eax,2
			.if eax==0
				int 3
			.endif
			dec eax
			mov @nCount,eax
			mov edx,@pJTbl
			.while ecx<@nCount
				lea eax,[esi+ecx*4+4]
				.if dword ptr [eax]
					mov [edx],eax
					add edx,4
				.endif
				inc ecx
			.endw
			mov @pJTbl,edx
			xor eax,eax
			mov al,[esi+1]
			add esi,eax
		.endif
	_caseOut:
		
	.endw
	assume ebx:nothing
	mov eax,@pJTbl
	mov ecx,[edi].lpCustom
	sub eax,IGInfo.lpJumpTable[ecx]
	shr eax,2
	mov IGInfo.nEntries[ecx],eax
	
	mov eax,@nLine
	mov [edi].nLine,eax
	mov [edi].nMemoryType,MT_POINTERONLY
	mov [edi].nStringType,ST_SPECLEN
	
	assume edi:nothing
	mov ecx,_lpRI
	xor eax,eax
	mov dword ptr [ecx],RI_SUC_LINEONLY
_Ex:
	ret
_Nomem:
	mov eax,E_NOMEM
	ret
align 4
_JmpTable1\
	dd	offset _case0
	dd	offset _case1
	dd	offset _case2
	dd	offset _case3
	dd	offset _case4
	dd	offset _case5
	dd	offset _case6
	dd	offset _case7
GetText endp

;
IGSetLine proc uses ebx _lpStr,_nCS
	LOCAL @pStr
	invoke lstrlenW,_lpStr
	;inc eax
	shl eax,1
	mov ebx,eax
	invoke HeapAlloc,hHeap,0,ebx
	test eax,eax
	jz _Err
	mov @pStr,eax
	mov ecx,ebx
	shr ecx,1
	invoke WideCharToMultiByte,_nCS,0,_lpStr,ecx,@pStr,ebx,0,0
	.if eax>255
		invoke HeapFree,hHeap,0,@pStr
		jmp _Err
	.endif
	mov ecx,eax
	mov eax,@pStr
	ret
_Err:
	xor eax,eax
	ret
IGSetLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	invoke IGSetLine,ebx,[edi].nCharSet
	.if !eax
		mov eax,E_LINEDENIED
		jmp _Ex
	.endif
	mov @pNewStr,eax
	mov @nNewLen,ecx
	
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	lea esi,[ecx+eax*4]
	assume esi:ptr _StreamEntry
	
	mov eax,[esi].nStringLen
	.if eax==@nNewLen
;		mov edi,[esi].lpStart
;		mov ecx,eax
;		xor al,al
;		rep stosb
		
		mov edi,[esi].lpStart
		mov esi,@pNewStr
		mov ecx,@nNewLen
		rep movsb
	.else
		mov @nOldLen,eax
		mov ecx,[edi].nStreamSize
		add ecx,[edi].lpStream
		sub ecx,[esi].lpStart
		sub ecx,[esi].nStringLen
		invoke _ReplaceInMem,@pNewStr,@nNewLen,[esi].lpStart,[esi].nStringLen,ecx
		.if eax
			mov ebx,eax
			invoke HeapFree,hHeap,0,@pNewStr
			mov eax,ebx
			jmp _Ex
		.endif
		
		mov ebx,@nNewLen
		mov [esi].nStringLen,ebx
		mov ecx,[esi].lpInformation
		mov [ecx],bl
		sub ebx,@nOldLen
		
		mov ecx,[edi].lpStreamIndex
		mov eax,[edi].nLine
		lea eax,[eax+eax*2]
		lea edx,[ecx+eax*4]
		mov eax,[esi].lpStart
		push esi
		add esi,sizeof _StreamEntry
		.while esi<edx
			add [esi].lpStart,ebx
			add [esi].lpInformation,ebx
			add esi,sizeof _StreamEntry
		.endw
		pop esi
		
		mov eax,[edi].lpCustom
		mov edx,IGInfo.lpJumpTable[eax]
		mov ecx,IGInfo.nEntries[eax]
		mov eax,[esi].lpStart
		test ecx,ecx
		jz _exloop2
		_loop2:
			.if [edx]>eax
				add dword ptr [edx],ebx
			.endif
			add edx,4
			dec ecx
			jnz _loop2
		_exloop2:
		
		mov eax,[edi].lpCustom
		mov edx,IGInfo.lpJumpTable[eax]
		mov ecx,IGInfo.nEntries[eax]
		mov eax,[esi].lpStart
		sub eax,[edi].lpStream
		test ecx,ecx
		jz _exloop1
		push edi
		_loop1:
			mov edi,[edx]
			.if dword ptr [edi]>eax
				add dword ptr [edi],ebx
			.endif
			add edx,4
			dec ecx
			jnz _loop1
		pop edi
	_exloop1:
		add [edi].nStreamSize,ebx
	.endif
	assume esi:nothing
	assume edi:nothing
_Success:
	invoke HeapFree,hHeap,0,@pNewStr
	xor eax,eax
_Ex:
	ret
ModifyLine endp

;
SaveText proc _lpFI
	mov eax,_lpFI
	invoke _Decode,_FileInfo.lpStream[eax],_FileInfo.nStreamSize[eax]
	invoke _SaveText,_lpFI
	push eax
	mov eax,_lpFI
	invoke _Decode,_FileInfo.lpStream[eax],_FileInfo.nStreamSize[eax]
	pop eax
	ret
SaveText endp

;
SetLine proc
	jmp _SetLine
SetLine endp

RetLine proc
	xor eax,eax
	ret
RetLine endp

Release proc uses ebx _lpFI
	mov ecx,_lpFI
	mov ebx,_FileInfo.lpCustom[ecx]
	.if ebx
		mov ecx,IGInfo.lpJumpTable[ebx]
		.if ecx
			invoke HeapFree,hHeap,0,ecx
		.endif
		invoke HeapFree,hHeap,0,ebx
	.endif
	ret
Release endp

end DllMain