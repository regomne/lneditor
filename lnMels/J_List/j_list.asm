.386
.model flat,stdcall
option casemap:none

include j_list.inc

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
	lea ecx,[ecx+eax*2-8]
	lea edx,@sExtend
	mov eax,[ecx]
	mov [edx],eax
	mov eax,[ecx+4]
	mov [edx+4],eax
	and dword ptr [edx],0ffdfffffh
	and dword ptr [edx+4],0ffdfffdfh
	.if dword ptr [edx]==57002eh && dword ptr [edx+4]==0430053h
		mov eax,MR_MAYBE
		ret
	.endif
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

JlistDecrypt proc _lpBuff,_nLen
	mov edx,_lpBuff
	mov ecx,_nLen
	add ecx,edx
	.while edx<ecx
		mov al,[edx]
		ror al,2
		mov [edx],al
		inc edx
	.endw
	ret
JlistDecrypt endp

JlistEncrypt proc _lpBuff,_nLen
	mov edx,_lpBuff
	mov ecx,_nLen
	add ecx,edx
	.while edx<ecx
		mov al,[edx]
		rol al,2
		mov [edx],al
		inc edx
	.endw
	ret
JlistEncrypt endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd
	LOCAL @nDist,@nOffset
	LOCAL @nLine
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke JlistDecrypt,[edi].lpStream,[edi].nStreamSize
	
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,sizeof JlistIndexData
	or eax,eax
	je _Nomem
	mov [edi].lpCustom,eax
	
	mov eax,[edi].nStreamSize
	shr eax,1
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Nomem
	mov ecx,[edi].lpCustom
	mov JlistIndexData.lpDist[ecx],eax
	
	mov eax,[edi].nStreamSize
	shr eax,1
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Nomem
	mov ecx,[edi].lpCustom
	mov JlistIndexData.lpOffset[ecx],eax

	mov eax,[edi].nStreamSize
	shr eax,2
	lea eax,[eax+eax*2]
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpStreamIndex,eax
	
	mov esi,[edi].lpStream
	mov eax,esi
	add eax,[edi].nStreamSize
	xor ecx,ecx
	mov @nLine,ecx
	mov @nDist,ecx
	mov @nOffset,ecx
	mov @pEnd,eax
	.while esi<@pEnd
		xor eax,eax
		mov al,[esi]
		inc esi
		mov ebx,ddTable2[eax*4]
		.repeat
			cmp bl,0
			jge _Add
			.if bl==-1
				.while byte ptr [esi]
					.break .if esi>=@pEnd
					inc esi
				.endw
				inc esi
				jmp _Ctn
			.elseif bl==-2
				mov eax,[edi].lpStreamIndex
				mov ecx,@nLine
				lea ecx,[ecx+ecx*2]
				mov _StreamEntry.lpStart[eax+ecx*4],esi
				inc @nLine
				.while byte ptr [esi]
					.break .if esi>=@pEnd
					inc esi
				.endw
				inc esi
				jmp _Ctn
			.elseif bl==-3
				.if al==1
					mov ecx,[edi].lpCustom
					mov edx,JlistIndexData.lpDist[ecx]
					mov eax,@nDist
					lea ecx,[esi+5]
					mov [edx+eax*4],ecx
					inc @nDist
					add esi,10
					jmp _Ctn
				.elseif al==2
					push ebx
					movzx ebx,byte ptr [esi]
					add esi,2
					or ebx,ebx
					je _leave
					@@:
						add esi,2
						mov eax,[edi].lpStreamIndex
						mov ecx,@nLine
						lea ecx,[ecx+ecx*2]
						mov _StreamEntry.lpStart[eax+ecx*4],esi
						inc @nLine
						.while byte ptr [esi]
							.break .if esi>=@pEnd
							inc esi
						.endw
						inc esi
						add esi,3
						lodsb
						.if al==3
							add esi,7
						.elseif al==6
							mov ecx,[edi].lpCustom
							mov edx,JlistIndexData.lpOffset[ecx]
							mov eax,@nOffset
							mov [edx+eax*4],esi
							add esi,5
							inc @nOffset
						.elseif al==7
							.while byte ptr [esi]
								.break .if esi>=@pEnd
								inc esi
							.endw
							inc esi
						.endif
						dec ebx
						jnz @B
					_leave:
					pop ebx
					jmp _Ctn
				.elseif al==6
					mov ecx,[edi].lpCustom
					mov edx,JlistIndexData.lpOffset[ecx]
					mov eax,@nOffset
					mov [edx+eax*4],esi
					add esi,5
					inc @nOffset
					jmp _Ctn
				.endif
			.elseif bl==-4
				mov ecx,@pEnd
				sub ecx,esi
				.if al==0ffh && ecx<=10
					jmp _Break1
				.endif
				int 3
			.endif
			_Add:
				xor eax,eax
				mov al,bl
				add esi,eax
			_Ctn:
			shr ebx,8
		.until !bl
	.endw
	_Break1:
	
	mov eax,@nDist
	mov edx,[edi].lpCustom
	mov JlistIndexData.nDist[edx],eax
	mov ecx,@nOffset
	mov JlistIndexData.nOffset[edx],ecx
	
	mov eax,@nLine
	mov [edi].nLine,eax
	mov [edi].nMemoryType,MT_POINTERONLY
	mov [edi].nStringType,ST_ENDWITHZERO
	
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
JlistSetLine proc uses edi _lpStr,_nCS
	LOCAL @nChar,@pStr2,@pStr
	invoke lstrlenW,_lpStr
	mov @nChar,eax
	inc eax
	shl eax,1
	mov edi,eax
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Err
	mov @pStr,eax
	mov byte ptr [eax],0
	invoke WideCharToMultiByte,_nCS,0,_lpStr,-1,@pStr,edi,0,0
	mov ecx,eax
	mov eax,@pStr
	ret
_Err:
	xor eax,eax
	ret
JlistSetLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	invoke JlistSetLine,ebx,[edi].nCharSet
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
	invoke lstrlenA,esi
	inc eax
	
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
		
		;修正文件大小
		mov ebx,@nNewLen
		sub ebx,@nOldLen
		add [edi].nStreamSize,ebx
		
		;修正StreamIndex
		mov ecx,[edi].lpStreamIndex
		mov eax,_nLine
		inc eax
		.while eax<[edi].nLine
			lea edx,[eax+eax*2]
			add _StreamEntry.lpStart[ecx+edx*4],ebx
			inc eax
		.endw
		
		;修正Dist和Offset Table
		mov ecx,[edi].lpCustom
		mov edx,JlistIndexData.nOffset[ecx]
		mov ecx,JlistIndexData.lpOffset[ecx]
		xor eax,eax
		.while eax<edx
			.if dword ptr [ecx+eax*4]>esi
				add dword ptr [ecx+eax*4],ebx
			.endif
			inc eax
		.endw
		mov ecx,[edi].lpCustom
		mov edx,JlistIndexData.nDist[ecx]
		mov ecx,JlistIndexData.lpDist[ecx]
		xor eax,eax
		.while eax<edx
			.if dword ptr [ecx+eax*4]>esi
				add dword ptr [ecx+eax*4],ebx
			.endif
			inc eax
		.endw
		
		;修正Dist
		push ebp
		push edi
		xor eax,eax
		.while eax<edx
			mov ebp,[ecx+eax*4]
			cmp dword ptr [ebp],0
			jl _Nega
			mov edi,[ebp]
			lea edi,[edi+ebp+5]
			.if edi>esi && ebp<esi
				add dword ptr [ebp],ebx
			.endif
			jmp _Next
		_Nega:
			mov edi,[ebp]
			lea edi,[edi+ebp+5]
			.if edi<esi && ebp>esi
				sub dword ptr [ebp],ebx
			.endif
		_Next:
			inc eax
		.endw
		pop edi
		
		;修正Offset
		mov ecx,[edi].lpCustom
		mov edx,JlistIndexData.nOffset[ecx]
		mov ecx,JlistIndexData.lpOffset[ecx]
		sub esi,[edi].lpStream
		xor eax,eax
		.while eax<edx
			mov ebp,[ecx+eax*4]
			.if [ebp]>esi
				add dword ptr [ebp],ebx
			.endif
			inc eax
		.endw
		pop ebp
	.endif
	
	assume edi:nothing
_Success:
	invoke HeapFree,hHeap,0,@pNewStr
	xor eax,eax
_Ex:
	ret
ModifyLine endp

;
Release proc uses ebx _lpFI
	mov edx,_lpFI
	mov ebx,_FileInfo.lpCustom[edx]
	.if ebx
		.if JlistIndexData.lpDist[ebx]
			invoke HeapFree,hHeap,0,JlistIndexData.lpDist[ebx]
		.endif
		.if JlistIndexData.lpOffset[ebx]
			invoke HeapFree,hHeap,0,JlistIndexData.lpOffset[ebx]
		.endif
		invoke HeapFree,hHeap,0,ebx
	.endif
	ret
Release endp

;
SaveText proc _lpFI
	mov ecx,_lpFI
	invoke JlistEncrypt,_FileInfo.lpStream[ecx],_FileInfo.nStreamSize[ecx]
	invoke _SaveText,_lpFI
	push eax
	mov ecx,_lpFI
	invoke JlistDecrypt,_FileInfo.lpStream[ecx],_FileInfo.nStreamSize[ecx]
	pop eax
	ret
SaveText endp

;
SetLine proc uses esi ebx _lpsz,_lpRange
	cmp _lpRange,0
	je _ExSL
	invoke lstrlenW,_lpsz
	.if eax<=4
		ret
	.endif
	mov esi,_lpsz
	lea esi,[esi+eax*2]
	.if dword ptr [esi-4]==500025h && dword ptr [esi-8]==4b0025h
		mov ecx,_lpRange
		sub eax,4
		mov [ecx+4],eax
	.endif
	invoke _SetLine,_lpsz,_lpRange
_ExSL:
	ret
SetLine endp

end DllMain