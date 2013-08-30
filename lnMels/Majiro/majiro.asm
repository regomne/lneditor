.386
.model flat,stdcall
option casemap:none

include majiro.inc
include mjdec.asm

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

InitInfo proc _lpMelInfo2
	mov ecx,_lpMelInfo2
	mov _MelInfo2.nInterfaceVer[ecx],00030000h
	mov _MelInfo2.nCharacteristic[ecx],0
	ret
InitInfo endp

;判断文件头
Match proc uses esi edi _lpszName
	LOCAL @szMagic[10h]:byte
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
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
	invoke HeapAlloc,hHeap,0,256*4
	mov lpTable1,eax
	.if eax
		invoke _InitHashTable
	.endif
	ret
PreProc endp

;
GetText proc uses edi ebx esi _lpFI,_lpRI
	LOCAL @pEnd,@nLine,@nJump,@nJump2
	LOCAL @pCurJumpTable
	LOCAL @pLastString
	LOCAL @lpJump2
	.if !lpTable1
		invoke HeapAlloc,hHeap,0,1024
		or eax,eax
		je _NomemGT
		mov lpTable1,eax
		invoke _InitHashTable
	.endif
	mov ebx,_lpFI
	assume ebx:ptr _FileInfo
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,sizeof _MjoInfo
	or eax,eax
	je _NomemGT
	mov [ebx].Reserved,eax
	mov edi,eax
	mov esi,[ebx].lpStream
	assume edi:ptr _MjoInfo
	add esi,10h
	lodsd
	mov [edi].nDefaultEntry,eax
	lodsd
	mov [edi].unk1,eax
	lodsd
	mov [edi].nEntryCount,eax
	shl eax,3
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _NomemGT
	mov [edi].lpEntries,eax
	mov ecx,[edi].nEntryCount
	shl ecx,3
	invoke _memcpy2,eax,esi,ecx
	mov esi,eax
	lodsd
	mov ecx,eax
	add ecx,100h
	shl ecx,1
	mov [edi].nDataSize,eax
	invoke HeapAlloc,hHeap,0,ecx
	or eax,eax
	je _NomemGT
	mov [edi].lpData,eax
	invoke _memcpy2,eax,esi,[edi].nDataSize
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,[edi].nDataSize
	or eax,eax
	je _NomemGT
	mov [edi].lpJumpTable,eax
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,[edi].nDataSize
	or eax,eax
	je _NomemGT
	mov [edi].lpJumpTable2,eax
	
	;解密
	invoke _XorBlock,[edi].lpData,[edi].nDataSize
	
	;生成跳转表并计算行数
	mov edx,[edi].lpJumpTable
	mov eax,[edi].lpJumpTable2
	mov esi,[edi].lpData
	mov @lpJump2,eax
	mov ecx,esi
	add ecx,[edi].nDataSize
	mov @pEnd,ecx
	mov @pLastString,esi
	xor ecx,ecx
	mov @nLine,ecx
	mov @nJump,ecx
	mov @nJump2,ecx
	push edi
	assume edi:nothing
	mov edi,edx
	.while esi<@pEnd
		lodsw
		.continue .if ax<=1a9h
		.if ax<=320h
			add esi,8
			.continue
		.elseif ax==801h
			cmp byte ptr [esi+2],81h
			jb _IsNotDispStr2GT
			xor ecx,ecx
			mov cx,[esi]
			cmp dword ptr [esi+ecx+4],718ef651h
			je _IsNotDispStr2GT
			jmp _IsStr2GT
		.elseif ax>=800h && ax<=847h
			xor ecx,ecx
			mov cx,ax
;			sub ecx,800h
			xor eax,eax
			mov al,byte ptr [ecx+(Offset OpTable-800h)]
			test al,al
			jl _SpecialGT
				add esi,eax
				.continue
			_SpecialGT:
				.if al==-1
_IsNotDispStr2GT:
					xor eax,eax
					lodsw
					add esi,eax
					.continue
				.elseif al==-2
_IsStr2GT:
					xor eax,eax
					lodsw
					add esi,eax
					mov @pLastString,esi
					inc @nLine
					.continue
				.elseif al==-3
					pop edi
					jmp _OpErrGT
				.elseif al==-4
					lodsd
					inc @nJump
					lea ecx,[esi-4]
					test eax,eax
					jl _Back
						mov eax,ecx
						stosd
						.continue
					_Back:
						lea edx,[esi+eax]
						.if edx<@pLastString
							mov eax,ecx
							stosd
						.endif
						.continue
				.endif
		.elseif ax==850h
			push edi
			mov edi,@lpJump2
			xor eax,eax
			lodsw
			stosd
			mov ecx,eax
			mov eax,esi
			stosd
			lea esi,[esi+ecx*4]
			add @lpJump2,8
			inc @nJump2
			pop edi
		.else
			pop edi
			jmp _OpErrGT
		.endif
	.endw
	pop edi
	assume edi:ptr _MjoInfo
	
	mov ecx,@nJump
	add ecx,3
	shl ecx,2
	invoke HeapReAlloc,hHeap,HEAP_REALLOC_IN_PLACE_ONLY,[edi].lpJumpTable,ecx
	or eax,eax
	je _NomemGT
	mov [edi].lpJumpTable,eax
	.if !@nJump2
		inc @nJump2
	.endif
	mov eax,@nJump2
	add eax,3
	shl eax,3
	invoke HeapReAlloc,hHeap,HEAP_REALLOC_IN_PLACE_ONLY,[edi].lpJumpTable2,eax
	or eax,eax
	je _NomemGT
	mov [edi].lpJumpTable2,eax
	
	;分配FileInfo中的内存
	mov eax,@nLine
	.if eax
		shl eax,2
		lea eax,[eax+eax*2]
		invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
		or eax,eax
		je _NomemGT
		mov [ebx].lpStreamIndex,eax
	.endif
	
	;开始处理字节码
	mov [ebx].nMemoryType,MT_POINTERONLY
	mov [ebx].nStringType,ST_PASCAL2
	
	.if [ebx].nCharSet==CS_UNICODE
		invoke Release,_lpFI
		mov ecx,_lpRI
		xor eax,eax
		mov dword ptr [ecx],RI_FAIL_ERRORCS
		ret
	.endif
	mov esi,[edi].lpData
	mov @nLine,0
	.while esi<@pEnd
		lodsw
		.continue .if ax<=1a9h
		.if ax<=320h
			add esi,8
			.continue
		.elseif ax==801h
			cmp byte ptr [esi+2],81h
			jb _IsNotDispStrGT
			xor ecx,ecx
			mov cx,[esi]
			cmp dword ptr [esi+ecx+4],718ef651h
			je _IsNotDispStrGT
			jmp _IsStrGT
		.elseif ax>=800h && ax<=847h
			xor ecx,ecx
			mov cx,ax
;			sub ecx,800h
			xor eax,eax
			mov al,byte ptr [ecx+(Offset OpTable-800h)]
			test al,al
			jl _SpecialGT2
				add esi,eax
				.continue
			_SpecialGT2:
				.if al==-1
_IsNotDispStrGT:
					xor eax,eax
					lodsw
					add esi,eax
					.continue
				.elseif al==-2
_IsStrGT:
					xor eax,eax
					lodsw
					movzx ecx,ax
					mov eax,@nLine
					mov edx,[ebx].lpStreamIndex
					lea eax,[eax+eax*2]
					mov _StreamEntry.lpStart[edx+eax*4],esi
					sub _StreamEntry.lpStart[edx+eax*4],2
					inc @nLine
					add esi,ecx
					.if word ptr [esi]==83ah && word ptr [esi+4]==840h
						add esi,6
						xor eax,eax
						mov ax,[esi]
						lea esi,[esi+eax+2]
					.endif
					.while byte ptr [esi+6]==6eh && dword ptr [esi]==08420841h && word ptr [esi+0ch]==840h
						add esi,0eh
						xor eax,eax
						mov ax,[esi]
						lea esi,[esi+eax+2]
					.endw
					.continue
				.elseif al==-3
					jmp _OpErrGT
				.elseif al==-4
					add esi,4
					.continue
				.endif
		.elseif ax==850h
			xor eax,eax
			lodsw
			lea esi,[esi+eax*4]
			.continue
		.else
			jmp _OpErrGT
		.endif
	.endw
	mov eax,@nLine
	mov ecx,_lpRI
	mov [ebx].nLine,eax
	xor eax,eax
	mov dword ptr [ecx],RI_SUC_LINEONLY
	assume edi:nothing
	assume ebx:nothing
	ret
_OpErrGT:
	invoke Release,_lpFI
	mov ecx,_lpRI
	or eax,E_ERROR
	mov dword ptr [ecx],RI_FAIL_FORMAT
	ret
_NomemGT:
	invoke Release,_lpFI
	mov ecx,_lpRI
	or eax,E_ERROR
	mov dword ptr [ecx],RI_FAIL_MEM
	ret
GetText endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @nOldLen,@nNewLen,@nLeftLen
	LOCAL @nLineNumber
	LOCAL @pNewBuff,@pNewStr
	mov ebx,_lpFI
	assume ebx:ptr _FileInfo
	mov edx,[ebx].lpStreamIndex
	mov ecx,_nLine
	lea ecx,[ecx+ecx*2]
	mov edx,_StreamEntry.lpStart[edx+ecx*4]
	.if word ptr [edx-6]==83ah
		xor eax,eax
		mov ax,[edx-4]
		inc eax
		mov @nLineNumber,eax
	.endif
	mov esi,edx
	xor eax,eax
	lodsw
	add esi,eax
	.if word ptr [esi]==83ah && word ptr [esi+4]==840h
		add esi,6
		xor eax,eax
		lodsw
		add esi,eax
	.endif
	.while byte ptr [esi+6]==6eh && dword ptr [esi]==08420841h && word ptr [esi+0ch]==840h
		add esi,0eh
		xor eax,eax
		lodsw
		add esi,eax
	.endw
	sub esi,edx
	mov @nOldLen,esi
	
	invoke HeapAlloc,hHeap,0,DEFAULT_STRLEN*2
	.if !eax
		mov eax,E_NOMEM
		jmp _ExML
	.endif
	mov @pNewBuff,eax
	mov @nLeftLen,DEFAULT_STRLEN*2
	mov edi,eax
	invoke _GetStringInList,ebx,_nLine
	mov esi,eax
	mov @pNewStr,eax
	invoke lstrlenW,esi
	mov edx,esi
	.while word ptr [esi]!='@'
		add esi,2
		dec eax
		.break .if !eax
	.endw
	.if word ptr [esi]=='@'
		mov word ptr [esi],0
		add edi,2
		invoke WideCharToMultiByte,[ebx].nCharSet,0,edx,-1,edi,@nLeftLen,0,0
		mov word ptr [esi],'@'
		sub @nLeftLen,eax
		mov [edi-2],ax
		add edi,eax
		mov ax,83ah
		stosw
		mov eax,@nLineNumber
		inc @nLineNumber
		stosw
		mov ax,840h
		stosw
		lea edx,[esi+2]
	.endif
	_EnterML:
	mov esi,edx
	.while dword ptr [esi]!=6e005ch
		.break .if !word ptr [esi]
		add esi,2
	.endw
	.if dword ptr [esi]==6e005ch
		mov word ptr [esi],0
		add edi,2
		invoke WideCharToMultiByte,[ebx].nCharSet,0,edx,-1,edi,@nLeftLen,0,0
		mov word ptr [esi],5ch
		sub @nLeftLen,eax
		mov [edi-2],ax
		add edi,eax
		mov eax,08420841h
		stosd
		mov eax,6e0002h
		stosd
		mov ax,83ah
		stosw
		mov eax,@nLineNumber
		inc @nLineNumber
		stosw
		mov ax,840h
		stosw
		lea edx,[esi+4]
		jmp _EnterML
	.else
		add edi,2
		invoke WideCharToMultiByte,[ebx].nCharSet,0,edx,-1,edi,@nLeftLen,0,0
		mov [edi-2],ax
		add edi,eax
	.endif
	
	sub edi,@pNewBuff
	mov @nNewLen,edi
	
	mov esi,[ebx].Reserved
	assume esi:ptr _MjoInfo
	mov eax,[esi].lpData
	add eax,[esi].nDataSize
	mov edi,[ebx].lpStreamIndex
	mov ecx,_nLine
	lea ecx,[ecx+ecx*2]
	mov edx,_StreamEntry.lpStart[edi+ecx*4]
	sub eax,edx
	sub eax,@nOldLen
	invoke _ReplaceInMem,@pNewBuff,@nNewLen,edx,@nOldLen,eax
	mov edi,eax
	invoke HeapFree,hHeap,0,@pNewBuff
	or edi,edi
	jne _ExML
	
	mov eax,@nNewLen
	sub eax,@nOldLen
	jz _ExML
	
	mov edi,[ebx].lpStreamIndex
	mov ecx,_nLine
	inc ecx
	.while ecx<[ebx].nLine
		lea edx,[ecx+ecx*2]
		add _StreamEntry.lpStart[edi+edx*4],eax
		inc ecx
	.endw
	
	mov edi,[esi].lpEntries
	mov ecx,_nLine
	mov edx,[ebx].lpStreamIndex
	lea ecx,[ecx+ecx*2]
	mov edx,_StreamEntry.lpStart[edx+ecx*4]
	sub edx,[esi].lpData
	xor ecx,ecx
	.while ecx<[esi].nEntryCount
		.if dword ptr [edi+ecx*8+4]>edx
			add dword ptr [edi+ecx*8+4],eax
		.endif
		inc ecx
	.endw
	
	.if [esi].nDefaultEntry>edx
		add [esi].nDefaultEntry,eax
	.endif
	
	mov edi,[esi].lpJumpTable
	mov ecx,_nLine
	mov edx,[ebx].lpStreamIndex
	lea ecx,[ecx+ecx*2]
	mov edx,_StreamEntry.lpStart[edx+ecx*4]
	mov ecx,[edi]
	.while ecx
		.if ecx>edx
			add dword ptr [edi],eax
		.endif
		add edi,4
		mov ecx,[edi]
	.endw
	
	mov edi,[esi].lpJumpTable2
	mov ecx,[edi+4]
	.while ecx
		.if ecx>edx
			add dword ptr [edi+4],eax
		.endif
		add edi,8
		mov ecx,[edi+4]
	.endw
	
	assume ebx:nothing
	mov edi,[esi].lpJumpTable
	mov ecx,[edi]
	push ebp
	.while ecx
		mov ebp,[ecx]
		lea ebx,[ebp+ecx+4]
		.if ebx<=edx && ecx>edx || ebx>edx && ecx<edx
			test ebp,ebp
			jl _neg1
				add dword ptr [ecx],eax
				jmp _neg10
			_neg1:
				sub dword ptr [ecx],eax
			_neg10:
		.endif
		add edi,4
		mov ecx,[edi]
	.endw
	
	mov edi,[esi].lpJumpTable2
	mov ebx,[edi+4]
	.while ebx
		mov ecx,[edi]
		@@:
			push ecx
			mov ecx,[edi]
			shl ecx,2
			add ecx,dword ptr [edi+4]
			mov ebp,[ebx]
			add ecx,ebp
			.if ebx<edx && ecx>edx || ebx>edx && ecx<=edx
				test ebp,ebp
				jl _neg2
					add dword ptr [ebx],eax
					jmp _neg20
				_neg2:
					sub dword ptr [ebx],eax
				_neg20:
			.endif
			add ebx,4
			pop ecx
		dec ecx
		jnz @B
		add edi,8
		mov ebx,[edi+4]
	.endw
	pop ebp
	
	add [esi].nDataSize,eax
	mov ebx,_lpFI
	add dword ptr [ebx+_FileInfo.nStreamSize],eax
	
	assume ebx:nothing
	assume esi:nothing
	xor eax,eax
_ExML:
	ret
_NobufML:
	invoke HeapFree,hHeap,0,@pNewBuff
	mov eax,E_NOTENOUGHBUFF
	ret
ModifyLine endp

;
SaveText proc uses edi ebx esi _lpFI
	LOCAL @lpfnBak
	mov ebx,_lpFI
	assume ebx:ptr _FileInfo
	mov esi,[ebx].Reserved
	assume esi:ptr _MjoInfo
	invoke lstrlenW,ebx
	add eax,5
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	mov @lpfnBak,eax
	.if eax
		invoke lstrcpyW,eax,ebx
		invoke lstrcatW,@lpfnBak,$CTW0(".bak")
		invoke CopyFileW,ebx,@lpfnBak,FALSE
	.endif
	
	mov edi,1
	invoke SetFilePointer,[ebx].hFile,10h,0,FILE_BEGIN
	invoke WriteFile,[ebx].hFile,esi,12,offset dwTemp,0
	and edi,eax
	mov ecx,[esi].nEntryCount
	shl ecx,3
	invoke WriteFile,[ebx].hFile,[esi].lpEntries,ecx,offset dwTemp,0
	and edi,eax
	invoke WriteFile,[ebx].hFile,addr [esi].nDataSize,4,offset dwTemp,0
	and edi,eax
	invoke _XorBlock,[esi].lpData,[esi].nDataSize
	invoke WriteFile,[ebx].hFile,[esi].lpData,[esi].nDataSize,offset dwTemp,0
	and edi,eax
	invoke _XorBlock,[esi].lpData,[esi].nDataSize
	invoke SetEndOfFile,[ebx].hFile
	and edi,eax
	
	.if !edi
		.if @lpfnBak
			invoke CopyFileW,@lpfnBak,ebx,FALSE
			invoke DeleteFileW,@lpfnBak
			invoke HeapFree,hHeap,0,@lpfnBak
		.endif
		mov eax,E_FILEACCESSERROR
		ret
	.endif
	.if @lpfnBak
		invoke DeleteFileW,@lpfnBak
		invoke HeapFree,hHeap,0,@lpfnBak
	.endif
	assume ebx:nothing
	assume esi:nothing
	xor eax,eax
	ret
SaveText endp

GetStr proc uses esi edi ebx _lpFI,_lppString,_lpStreamEntry
	LOCAL @nCharSet,@pStr,@nLeftBuff
	mov ecx,_lpFI
	mov eax,dword ptr [ecx+_FileInfo.nCharSet]
	mov @nCharSet,eax
	
	invoke HeapAlloc,hHeap,0,DEFAULT_STRLEN
	.if !eax
		MOV EAX,E_NOMEM
		jmp _ExGS
	.endif
	mov @nLeftBuff,DEFAULT_STRLEN/2
	mov @pStr,eax
	mov ecx,_lppString
	mov [ecx],eax
	
	mov eax,_lpStreamEntry
	mov esi,_StreamEntry.lpStart[eax]
	xor ebx,ebx
	mov bx,[esi]
	add esi,2
	cmp ebx,@nLeftBuff
	ja _NobuffGS
	invoke MultiByteToWideChar,@nCharSet,0,esi,ebx,@pStr,@nLeftBuff
	add esi,ebx
	sub @nLeftBuff,eax
	.if word ptr [esi]==83ah && word ptr [esi+4]==840h
		mov edi,@pStr
		lea edx,[edi+eax*2]
		mov word ptr [edx-2],'@'
		mov @pStr,edx
		add esi,6
		lodsw
		movzx ebx,ax
		cmp ebx,@nLeftBuff
		ja _NobuffGS
		invoke MultiByteToWideChar,@nCharSet,0,esi,ebx,@pStr,@nLeftBuff
		add esi,ebx
		sub @nLeftBuff,eax
	.endif
	
	.while byte ptr [esi+6]==6eh && dword ptr [esi]==08420841h && word ptr [esi+0ch]==840h
		sub eax,1
		adc eax,0
		mov ecx,@pStr
		mov dword ptr [ecx+eax*2],6e005ch
		lea ecx,[ecx+eax*2+4]
		mov @pStr,ecx
		dec @nLeftBuff
		add esi,0eh
		lodsw
		movzx ebx,ax
		cmp ebx,@nLeftBuff
		ja _NobuffGS
		invoke MultiByteToWideChar,@nCharSet,0,esi,ebx,@pStr,@nLeftBuff
		add esi,ebx
		sub @nLeftBuff,eax
	.endw
	
	xor eax,eax
_ExGS:
	ret
_NobuffGS:
	mov ecx,_lppString
	invoke HeapFree,hHeap,0,[ecx]
	mov eax,E_NOTENOUGHBUFF
	ret
GetStr endp

Release proc uses ebx _lpFI
	mov eax,_lpFI
	mov ebx,dword ptr [eax+_FileInfo.Reserved]
	assume ebx:ptr _MjoInfo
	.if ebx
		mov eax,[ebx].lpEntries
		.if eax
			invoke HeapFree,hHeap,0,eax
		.endif
		mov ecx,[ebx].lpData
		.if ecx
			invoke HeapFree,hHeap,0,ecx
		.endif
		mov eax,[ebx].lpJumpTable
		.if eax
			invoke HeapFree,hHeap,0,eax
		.endif
		mov eax,[ebx].lpJumpTable2
		.if eax
			invoke HeapFree,hHeap,0,eax
		.endif
		invoke HeapFree,hHeap,0,ebx
		mov eax,_lpFI
		mov dword ptr [eax+_FileInfo.Reserved],0
	.endif
	assume ebx:nothing
	ret
Release endp

;
SetLine proc
	jmp _SetLine
SetLine endp

_memcpy2 proc _dest,_src,_len
	push esi
	mov esi,_src
	mov ecx,_len
	mov eax,ecx
	shr ecx,2
	push edi
	mov edi,_dest
	rep movsd
	mov ecx,eax
	and ecx,3
	rep movsb
	mov eax,esi
	pop edi
	pop esi
	ret
_memcpy2 endp

end DllMain