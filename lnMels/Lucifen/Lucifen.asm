.386
.model flat,stdcall
option casemap:none

include Lucifen.inc

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
	.if dword ptr [edx]==54002eh && dword ptr [edx+4]==042004fh
		invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		cmp eax,-1
		je _ErrMatch
		push eax
		lea esi,@szMagic
		invoke ReadFile,eax,esi,4,offset dwTemp,0
		call CloseHandle
		lodsd
		.if eax=='0BOT'
			mov eax,MR_YES
			RET
		.endif
	.endif
_NotMatch:
	mov eax,MR_NO
	ret
_ErrMatch:
	mov eax,MR_ERR
	ret
Match endp

LuciIsLineHalf proc _lpsz,_len,_code
	mov edx,_lpsz
	xor ecx,ecx
	.if _code==CS_SJIS
		.while ecx<_len
			mov al,[edx+ecx]
			.if al>=81h && al<=9eh || al>=0e0h && al<=0fch
				xor eax,eax
				ret
			.else
				inc ecx
			.endif
		.endw
	.else
		.while ecx<_len
			mov al,[edx+ecx]
			.if al>=81h
				xor eax,eax
				ret
			.else
				inc ecx
			.endif
		.endw
	.endif
	mov eax,1
	ret
LuciIsLineHalf endp

LuciGetLine proc uses ebx esi lpsz,nlen,code
	.if nlen!=0
		mov eax,nlen
		inc eax
		mov ebx,eax
		lea eax,[eax+eax]
		invoke HeapAlloc,hHeap,0,eax
		test eax,eax
		jz _Ex
		xchg eax,ebx
		invoke MultiByteToWideChar,code,0,lpsz,nlen,ebx,eax
		.if !eax
			invoke HeapFree,hHeap,0,ebx
			xor eax,eax
			jmp _Ex
		.endif
		mov word ptr [ebx+eax*2],0
		mov eax,ebx
	.else
		mov edx,lpsz
		xor ecx,ecx
		.if code==CS_SJIS
			.while 1
				mov al,[edx+ecx]
				.if al>=81h && al<=9eh || al>=0e0h && al<=0fch
					add ecx,2
					.continue
				.else
					.break .if al==5bh || !al
					inc ecx
				.endif
			.endw
		.else
			.while 1
				mov al,[edx+ecx]
				.if al>=81h
					add ecx,2
					.continue
				.else
					.break .if al==5bh || !al
					inc ecx
				.endif
			.endw
		.endif
;		lea esi,[edx+ecx]
		mov esi,ecx
		inc ecx
		mov ebx,ecx
		lea eax,[ecx+ecx]
		invoke HeapAlloc,hHeap,0,eax
		test eax,eax
		jz _Ex
		xchg eax,ebx
		lea ecx,[eax-1]
		invoke MultiByteToWideChar,code,0,lpsz,ecx,ebx,eax
		.if !eax
			invoke HeapFree,hHeap,0,ebx
			xor eax,eax
			jmp _Ex
		.endif
		mov word ptr [ebx+eax*2],0
		mov eax,ebx
		mov ecx,esi
	.endif
_Ex:
	ret
LuciGetLine endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd
	LOCAL @lpIndex,@nIndex
	LOCAL @lpContent
	LOCAL @pSIdx,@pTIdx
	LOCAL @lpOpLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStream
	
	mov eax,[esi]
	add esi,4
	.if eax!='0BOT'
		mov eax,E_WRONGFORMAT
		jmp _Ex
	.endif
	mov ecx,[esi]
	add esi,ecx
	mov eax,[esi]
	add eax,esi
	mov ecx,[esi+4]
	mov @lpContent,eax
	mov @nIndex,ecx
	add esi,8
	mov @lpIndex,eax
	
	shl ecx,3
	mov ebx,ecx
	lea ecx,[ecx+ecx*2]
	invoke VirtualAlloc,0,ecx,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpStreamIndex,eax
	mov @pSIdx,eax
	invoke VirtualAlloc,0,ebx,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpTextIndex,eax
	mov @pTIdx,eax
		
	mov ecx,[edi].lpStream
	add ecx,[edi].nStreamSize
	mov @pEnd,ecx
	
	mov esi,@lpContent
		.while esi<@pEnd
		mov al,[esi]
		.if al==5bh
			mov al,[esi+1]
			.if al==20h
				mov eax,[esi+2]
				add esi,6
				xor ecx,ecx
				mov cl,[esi]
				inc esi
				.if ecx==0
					mov ecx,[esi]
					add esi,4
					jmp ftype1
				.elseif ecx==1
				ftype1:
					mov edx,[esi]
					mov @lpOpLen,esi
					add esi,4
					.if ecx==0 && eax!=0 || ecx!=0 && eax==0
						lea esi,[esi+edx-4]
						.continue
					.endif
					xor ebx,ebx
					mov bl,[esi]
					inc esi
					test ebx,ebx
					jz _loop1e
					_loop1:
						mov al,[esi]
						inc esi
						.if al==1
							mov al,[esi]
							inc esi
							.if al==0
								add esi,4
							.elseif al==1
								xor eax,eax
								mov ax,[esi]
								add esi,2
								test eax,eax
								jz _loop1c
								push eax
								invoke LuciIsLineHalf,esi,eax,[edi].nCharSet
								pop ecx
								.if eax
									add esi,ecx
									jmp _loop1c
								.endif
								invoke LuciGetLine,esi,ecx,[edi].nCharSet
								test eax,eax
								jz _Nomem ;不准确
								mov ecx,@pTIdx
								mov [ecx],eax
								mov edx,@pSIdx
								lea ecx,[esi-2]
								mov _StreamEntry.lpStart[edx],ecx
								mov _StreamEntry.nStringLen[edx],-1
								mov eax,@lpOpLen
								mov _StreamEntry.lpInformation[edx],eax
								add @pSIdx,sizeof _StreamEntry
								add @pTIdx,4
								xor eax,eax
								mov ax,[esi-2]
								add esi,eax
							.elseif al==2
								add esi,8
							.elseif al==3
								int 3
							.else
								int 3
							.endif
						.elseif al==2
							add esi,4
						.elseif al!=0
							int 3
						.endif
						_loop1c:
						dec ebx
					jnz _loop1
					_loop1e:
				.elseif ecx==2
					mov eax,[esi]
					mov ecx,[esi+4]
					add esi,8
					jmp ftype1
				.elseif ecx==3
					int 3
				.else
					int 3
				.endif
				
			.elseif al==73h
				int 3
			.else
				int 3
			.endif
		.else
			.break .if !al
			invoke LuciGetLine,esi,0,[edi].nCharSet
			test eax,eax
			jz _Nomem ;不准确
			mov edx,@pSIdx
			mov _StreamEntry.lpStart[edx],esi
			mov _StreamEntry.nStringLen[edx],ecx
			add @pSIdx,sizeof _StreamEntry
			add esi,ecx
			mov ecx,@pTIdx
			mov [ecx],eax
			add @pTIdx,4
		.endif
	.endw
	
	mov eax,@pSIdx
	sub eax,[edi].lpStreamIndex
	shr eax,2
	mov ecx,0aaaaaaabh
	mul ecx
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

LuciSetLine proc uses ebx _lpsz,_cs
	LOCAL @pstr
	invoke lstrlenW,_lpsz
	lea ebx,[eax*2+2]
	invoke HeapAlloc,hHeap,0,ebx
	test eax,eax
	jz _Ex
	mov @pstr,eax
	invoke WideCharToMultiByte,_cs,0,_lpsz,-1,eax,ebx,0,0
	mov ecx,eax
	.if ecx>=0ffffh
		xor eax,eax
		jmp _Ex
	.endif
	mov eax,@pstr
_Ex:
	ret
LuciSetLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	LOCAL @pCur
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	
	invoke LuciSetLine,ebx,[edi].nCharSet
	mov @pNewStr,eax
	mov @nNewLen,ecx
	
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	lea esi,[ecx+eax*4]
	assume esi:ptr _StreamEntry
	mov eax,[esi].nStringLen
	.if eax==-1
		mov ecx,[esi].lpStart
		xor eax,eax
		mov ax,[ecx]
	.else
		dec @nNewLen
	.endif
	mov @nOldLen,eax
	
	.if eax==@nNewLen
		mov edi,[esi].lpStart
		.if [esi].nStringLen==-1
			add edi,2
		.endif
		mov esi,@pNewStr
		mov ecx,eax
		rep movsb
	.else
		mov ecx,[edi].nStreamSize
		add ecx,[edi].lpStream
		mov eax,[esi].lpStart
		mov @pCur,eax
		.if [esi].nStringLen==-1
			add eax,2
		.endif
		sub ecx,eax
		sub ecx,@nOldLen
		invoke _ReplaceInMem,@pNewStr,@nNewLen,eax,@nOldLen,ecx
		.if eax
			mov ebx,eax
			invoke HeapFree,hHeap,0,@pNewStr
			mov eax,ebx
			jmp _Ex
		.endif
		
		mov ebx,@nNewLen
		sub ebx,@nOldLen
		
		.if [esi].nStringLen==-1
			;修正字符串和指令长度
			mov eax,@nNewLen
			mov ecx,[esi].lpStart
			mov [ecx],ax
			mov ecx,[esi].lpInformation
			add dword ptr [ecx],ebx
		.else
			mov eax,@nNewLen
			mov [esi].nStringLen,eax
		.endif
		
		mov ecx,[edi].lpStreamIndex
		mov eax,[edi].nLine
		lea eax,[eax+eax*2]
		lea edx,[ecx+eax*4]
		mov eax,[esi].lpStart
		add esi,sizeof _StreamEntry
		.while esi<edx
			add [esi].lpStart,ebx
			.if [esi].nStringLen==-1 && [esi].lpInformation>eax
				add [esi].lpInformation,ebx
			.endif
			add esi,sizeof _StreamEntry
		.endw
		
		assume esi:nothing
		mov esi,[edi].lpStream
		mov eax,[esi+4]
		lea esi,[esi+eax+4]
		mov eax,[esi]
		add eax,esi
		mov edx,@pCur
		sub edx,eax
		mov ecx,[esi+4]
		add esi,8
		
		test ecx,ecx
		jz _exloop1
		_loop1:
			.if edx<dword ptr [esi]
				add dword ptr [esi],ebx
			.endif
			add esi,4
			dec ecx
			jnz _loop1
		_exloop1:
		
		add [edi].nStreamSize,ebx
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