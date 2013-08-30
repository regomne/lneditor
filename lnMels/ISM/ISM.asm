.386
.model flat,stdcall
option casemap:none

include ism.inc

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
Match proc uses esi edi _lpszName
	LOCAL @szMagic[12]:byte
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _ErrMatch
	push eax
	lea ecx,@szMagic
	invoke ReadFile,eax,ecx,12,offset dwTemp,0
	call CloseHandle
	lea esi,@szMagic
	lea edi,szIsmMagic
	mov ecx,3
	repe cmpsd
	jne _NotMatch
	mov eax,MR_YES
	ret
	
_NotMatch:
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

;
IsmGetLine proc uses ebx esi edi _lpStr,_nCS,_nKey
	LOCAL @nLen,@nChar
	LOCAL @pStr,@pStr2
	
	mov esi,_lpStr
	xor eax,eax
	lodsb
	.if al==0ffh
		lodsd
	.endif
	.if !eax
		inc eax
		jmp _Ex
	.endif
	mov ebx,eax
	shl eax,2
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Ex
	mov @pStr2,eax
	mov edi,eax
	mov ecx,ebx
	mov dl,byte ptr _nKey
	.if dl==0ffh
		xor dl,dl
	.endif
	.while ecx
		lodsb
		not al
;		xor al,dl 这一步需要由外部程序做
		stosb
		dec ecx
	.endw
	mov byte ptr [edi],0
	
	mov eax,@pStr2
	.if byte ptr [eax]<80h && byte ptr [eax+1]<80h
			invoke HeapFree,hHeap,0,@pStr2
			mov eax,1
			jmp _Ex
	.endif
	invoke lstrlenA,@pStr2
	mov ebx,eax
	.if eax>=4
		mov ecx,@pStr2
		lea esi,[ecx+eax-4]
		invoke lstrcmp,esi,$CTA0(".png")
		.if !eax
		_NotMatch:
			invoke HeapFree,hHeap,0,@pStr2
			mov eax,1
			jmp _Ex
		.endif
		invoke lstrcmp,esi,$CTA0(".ogg")
		or eax,eax
		je _NotMatch
		invoke lstrcmp,esi,$CTA0(".isv")
		or eax,eax
		je _NotMatch
	.endif
	inc ebx
	shl ebx,1
	invoke HeapAlloc,hHeap,0,ebx
	.if !eax
		invoke HeapFree,hHeap,0,@pStr2
		xor eax,eax
		jmp _Ex
	.endif
	mov @pStr,eax
	mov word ptr [eax],0
	shr ebx,1
	invoke MultiByteToWideChar,_nCS,0,@pStr2,-1,@pStr,ebx
;	.if !eax
;		invoke HeapFree,hHeap,0,@pStr
;		invoke HeapFree,hHeap,0,@pStr2
;		xor eax,eax
;		jmp _Ex
;	.endif
	invoke HeapFree,hHeap,0,@pStr2
	mov eax,@pStr
;	.if dword ptr [eax]==0ff11ff10h && dword ptr [eax+4]==0ff13ff12h
;		invoke HeapFree,hHeap,0,@pStr
;	.endif
_Ex:
	ret
IsmGetLine endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd,@pCSEnd
	LOCAL @pOT,@pDT
	LOCAL @lpCS
	LOCAL @nLine
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,sizeof IsmRelocTable
	or eax,eax
	je _Nomem
	mov [edi].lpCustom,eax
	mov esi,eax
	mov ebx,[edi].nStreamSize
	shr ebx,1
	invoke HeapAlloc,hHeap,0,ebx
	or eax,eax
	je _Nomem
	mov IsmRelocTable.lpOffsetTable[esi],eax
	mov @pOT,eax
	invoke HeapAlloc,hHeap,0,ebx
	or eax,eax
	je _Nomem
	mov IsmRelocTable.lpDistTable[esi],eax
	mov @pDT,eax
	
	mov esi,[edi].lpStream
	mov eax,[esi+10h]
	add eax,esi
	mov @lpCS,eax
	mov ebx,[edi].lpCustom
	assume ebx:ptr IsmRelocTable
	mov edx,[ebx].lpOffsetTable
	mov ecx,[esi+1ch]
	add esi,20h
	.while ecx
		mov [edx],esi
		add edx,4
		add esi,0ch
		dec ecx
	.endw
	mov @pOT,edx
	mov ecx,[esi-0ch]
	mov edx,[edi].lpStream
	mov eax,[edx+10h]
	add ecx,eax
	add ecx,edx
	.if byte ptr [ecx]!=24h
;		int 3
		mov eax,E_ANALYSISFAILED
		jmp _Ex
	.endif
	add ecx,dword ptr [ecx+1]
	mov @pCSEnd,ecx
	
	mov edx,@pOT
	mov ecx,[esi]
	add esi,0ch
	.while ecx
		cmp dword ptr [esi],0
		jle @F
		mov [edx],esi
		add edx,4
		@@:
		add esi,0ch
		movzx eax,byte ptr [esi]
		lea esi,[esi+eax+2]
		dec ecx
	.endw
	mov @pOT,edx
	assume ebx:nothing
	
	mov @nLine,0
	mov esi,[edi].lpStream
	add esi,dword ptr [esi+10h]
	.while esi<@pCSEnd
		xor eax,eax
		lodsb
		movsx eax,byte ptr [eax+offset IsmInstTable]
		cmp eax,0
		jnl _NextInst
		.if eax==-1
;			int 3
			mov eax,E_ANALYSISFAILED
			jmp _Ex
		.endif
		.if eax==-2
			lea ecx,[esi-1]
			mov edx,@pDT
			mov [edx],ecx
			mov [edx+4],esi
			add @pDT,8
			add esi,4
			.continue
		.endif
		mov al,[esi-1]
		.if al==0fh
			mov edx,@pOT
			mov [edx],esi
			add @pOT,4
			lodsd
			mov ecx,[edi].lpStream
			add eax,dword ptr [ecx+10h]
			lea ebx,[eax+ecx]
			.if dword ptr [ebx]==0ff000000h
				mov ecx,[esi]
				lea eax,[esi-5]
				mov edx,@pDT
				mov [edx],eax
				add ebx,4
				mov [edx+4],ebx
				add edx,8
				add ebx,8
				.while ecx
					mov [edx],eax
					mov [edx+4],ebx
					add edx,8
					add ebx,4
					dec ecx
				.endw
				mov @pDT,edx
			.elseif dword ptr [ebx]==0fe000000h
				mov ecx,[esi]
				lea eax,[esi-5]
				mov edx,@pDT
				mov [edx],eax
				add ebx,4
				mov [edx+4],ebx
				add edx,8
				add ebx,8
				dec ecx
				.while ecx
					mov [edx],eax
					mov [edx+4],ebx
					add edx,8
					add ebx,8
					dec ecx
				.endw
				mov @pDT,edx
			.else
				mov eax,E_ANALYSISFAILED
				jmp _Ex
			.endif
			add esi,4
			.continue
		.endif
		.if al==33h
			inc @nLine
			xor eax,eax
			lodsb
			.if al==0ffh
				lodsd
			.endif
			add esi,eax
			.continue
		.endif
		.if al==45h
			inc @nLine
			mov edx,@pOT
			mov [edx],esi
			add @pOT,4
			add esi,4
			.continue
		.endif
	_NextInst:
		add esi,eax
	.endw
	
	mov eax,@pOT
	mov ebx,[edi].lpCustom
	assume ebx:ptr IsmRelocTable
	sub eax,[ebx].lpOffsetTable
	shr eax,2
	mov [ebx].nOffsets,eax
	mov eax,@pDT
	sub eax,[ebx].lpDistTable
	shr eax,3
	mov [ebx].nDists,eax
	
	mov ecx,[ebx].nOffsets
	shl ecx,2
	invoke HeapReAlloc,hHeap,0,[ebx].lpOffsetTable,ecx
	or eax,eax
	je _Nomem
	mov [ebx].lpOffsetTable,eax
	mov ecx,[ebx].nDists
	shl ecx,3
	invoke HeapReAlloc,hHeap,0,[ebx].lpDistTable,ecx
	or eax,eax
	je _Nomem
	mov [ebx].lpDistTable,eax
	assume ebx:nothing
	
	mov ebx,@nLine
	shl ebx,2
	invoke VirtualAlloc,0,ebx,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpTextIndex,eax
	lea eax,[ebx+ebx*2]
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpStreamIndex,eax
	
	xor ebx,ebx
	mov esi,[edi].lpStream
	add esi,dword ptr [esi+10h]
	.while esi<@pCSEnd
		xor eax,eax
		lodsb
		movsx eax,byte ptr [eax+offset IsmInstTable]
		cmp eax,0
		jnl _NextLine2
		.if eax==-1
;			int 3
			mov eax,E_ANALYSISFAILED
			jmp _Ex
		.endif
		.if eax==-2
			add esi,4
			.continue
		.endif
		mov al,[esi-1]
		.if al==0fh
			add esi,8
			.continue
		.endif
		.if al==33h
			lea ecx,[esi-1]
			sub ecx,@lpCS
			invoke IsmGetLine,esi,[edi].nCharSet,ecx
			.if eax==1
				lodsb
				.if al==0ffh
					lodsd
				.endif
				add esi,eax
				.continue
			.endif
			.if !eax
;				int 3
				mov eax,E_NOMEM
				jmp _Ex
			.endif
			mov ecx,[edi].lpTextIndex
			mov [ecx+ebx*4],eax
			mov ecx,[edi].lpStreamIndex
			lea eax,[esi-1]
			lea edx,[ebx+ebx*2]
			mov _StreamEntry.lpStart[ecx+edx*4],eax
			inc ebx
			
			xor eax,eax
			lodsb
			.if al==0ffh
				lodsd
			.endif
			add esi,eax
			.continue
		.endif
		.if al==45h
			lodsd
			mov ecx,eax
			add eax,@lpCS
			.if byte ptr [eax]!=033h
				int 3
			.endif
			inc eax
			invoke IsmGetLine,eax,[edi].nCharSet,ecx
			.continue .if eax==1
			.if !eax
				int 3
			.endif
			mov ecx,[edi].lpTextIndex
			mov [ecx+ebx*4],eax
			mov ecx,[edi].lpStreamIndex
			lea eax,[esi-5]
			lea edx,[ebx+ebx*2]
			mov _StreamEntry.lpStart[ecx+edx*4],eax
			inc ebx
			.continue
		.endif
	_NextLine2:
		add esi,eax
	.endw
	
	mov [edi].nMemoryType,MT_EVERYSTRING
	mov [edi].nLine,ebx
	
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
ISMSetLine proc uses edi _lpStr,_nCS
	LOCAL @nChar,@pStr2,@pStr
	invoke lstrlenW,_lpStr
	mov @nChar,eax
	add eax,5
	shl eax,1
	lea edi,[eax-6]
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Err
	mov @pStr2,eax
	mov byte ptr [eax],0
	invoke WideCharToMultiByte,_nCS,0,_lpStr,-1,0,0,0,0
	dec eax
	mov ecx,@pStr2
	mov edx,edi
	.if eax>0feh
		mov word ptr [ecx],0ff33h
		mov [ecx+2],eax
		add ecx,6
	.else
		mov byte ptr [ecx],33h
		mov [ecx+1],al
		add ecx,2
	.endif
	mov edi,ecx
	invoke WideCharToMultiByte,_nCS,0,_lpStr,-1,ecx,edx,0,0
;	.if !eax
;		invoke HeapFree,hHeap,0,@pStr2
;		invoke HeapFree,hHeap,0,@pStr
;		jmp _Err
;	.endif
	xor ecx,ecx
	dec eax
	.while ecx<eax
		xor byte ptr [edi+ecx],0ffh
		inc ecx
	.endw
	
	lea ecx,[edi+eax]
	sub ecx,@pStr2
	mov eax,@pStr2
	ret
_Err:
	xor eax,eax
	ret
ISMSetLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @lpCS
	LOCAL @pNewStr,@nNewLen,@nOldLen
	LOCAL @lpRcv,@dwRcv
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	mov eax,[edi].lpStream
	add eax,dword ptr [eax+10h]
	mov @lpCS,eax
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	invoke ISMSetLine,ebx,[edi].nCharSet
	.if !eax
		mov eax,E_NOMEM
		jmp _Ex
	.endif
	mov @pNewStr,eax
	mov @nNewLen,ecx
	
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	mov esi,_StreamEntry.lpStart[ecx+eax*4]
	mov @lpRcv,0
	.if byte ptr [esi]==45h
		push edi
		push esi
		mov esi,[esi+1]
		add esi,@lpCS
		mov ecx,@nNewLen
		mov edi,@pNewStr
		repe cmpsb
		.if !ZERO?
	_GotoRep:
			mov @nOldLen,5
			pop esi
			pop edi
			mov ebx,[edi].lpCustom
			assume ebx:ptr IsmRelocTable
			mov edx,[ebx].lpOffsetTable
			mov ecx,[ebx].nOffsets
			inc esi
			.while ecx
				mov eax,[edx]
				.if eax==esi
					mov @lpRcv,edx
					mov @dwRcv,esi
					mov dword ptr [edx],0
					.break
				.endif
				add edx,4
				dec ecx
			.endw
			dec esi
			assume ebx:nothing
			jmp _Replace
		.endif
		add esp,8
		jmp _Success
	.else
		mov edx,esi
		inc esi
		xor eax,eax
		lodsb
		.if al==0ffh
			lodsd
		.endif
		add esi,eax
		sub esi,edx
		mov @nOldLen,esi
		mov esi,edx
	.endif
	
_Replace:
	mov eax,@nOldLen
	.if eax==@nNewLen
		mov edi,esi
		mov esi,@pNewStr
		mov ecx,eax
		rep movsb
	.else
		mov ecx,[edi].nStreamSize
		add ecx,[edi].lpStream
		sub ecx,esi
		sub ecx,@nOldLen
		invoke _ReplaceInMem,@pNewStr,@nNewLen,esi,@nOldLen,ecx
		.if eax
			mov ebx,eax
			mov ecx,@lpRcv
			mov eax,@dwRcv
			mov [ecx],eax
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
		mov edi,[edi].lpCustom
		assume edi:ptr IsmRelocTable
		mov edx,[edi].lpOffsetTable
		mov ecx,[edi].nOffsets
;		or ecx,ecx
;		je _Next
;		@@:
;			.if dword ptr [edx]>esi
;				add dword ptr [edx],ebx
;			.endif
;			add edx,4
;			dec ecx
;			jnz @B
;		_Next1:
		.if ecx
			.repeat
				.if dword ptr [edx]>esi
					add dword ptr [edx],ebx
				.endif
				add edx,4
				dec ecx
			.until ZERO?
		.endif
		mov edx,[edi].lpDistTable
		mov ecx,[edi].nDists
		shl ecx,1
		.while ecx
			.if dword ptr [edx]>esi
				add dword ptr [edx],ebx
			.endif
			add edx,4
			dec ecx
		.endw
		
		mov edx,[edi].lpOffsetTable
		sub esi,@lpCS
		mov ecx,[edi].nOffsets
		.while ecx
			mov eax,[edx]
			.if eax && [eax]>esi
				add dword ptr [eax],ebx
			.endif
			add edx,4
			dec ecx
		.endw
		mov edx,[edi].lpDistTable
		mov ecx,[edi].nDists
		assume edi:nothing
		.while ecx
			mov eax,[edx]
			sub eax,@lpCS
			mov edi,[edx+4]
			push ecx
			mov ecx,[edi]
			add ecx,eax
			.if eax<=esi && ecx>esi
				add dword ptr [edi],ebx
			.elseif eax>esi && ecx<=esi
				sub dword ptr [edi],ebx
			.endif
			add edx,8
			pop ecx
			dec ecx
		.endw
	.endif
	
_Success:
	invoke HeapFree,hHeap,0,@pNewStr
	xor eax,eax
_Ex:
	ret
ModifyLine endp

;
SaveText proc _lpFI
	mov ecx,_lpFI
	mov eax,_FileInfo.nStreamSize[ecx]
	mov edx,_FileInfo.lpStream[ecx]
	mov [edx+0ch],eax
	invoke _SaveText,_lpFI
	ret
SaveText endp

;
SetLine proc
	jmp _SetLine
SetLine endp

;
Release proc uses ebx _lpFI
	mov ecx,_lpFI
	mov ebx,_FileInfo.lpCustom[ecx]
	assume ebx:ptr IsmRelocTable
	.if ebx
		.if [ebx].lpOffsetTable
			invoke HeapFree,hHeap,0,[ebx].lpOffsetTable
		.endif
		.if [ebx].lpDistTable
			invoke HeapFree,hHeap,0,[ebx].lpDistTable
		.endif
		invoke HeapFree,hHeap,0,ebx
		mov ecx,_lpFI
		mov _FileInfo.lpCustom[ecx],0
	.endif
	assume ebx:nothing
	ret
Release endp

end DllMain