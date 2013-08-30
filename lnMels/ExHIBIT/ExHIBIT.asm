.386
.model flat,stdcall
option casemap:none

include exhibit.inc

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
Match proc uses esi _lpszName
	LOCAL @szMagic[14h]:byte
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
	.if dword ptr [edx]==52002eh && dword ptr [edx+4]==044004ch
		invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		cmp eax,-1
		je _ErrMatch
		push eax
		lea esi,@szMagic
		invoke ReadFile,eax,esi,14h,offset dwTemp,0
		call CloseHandle
		.if dword ptr [esi]==524c4400h && dword ptr [esi+10h]==0
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
	
	.if dword ptr [esi]!=524c4400h || dword ptr [esi+10h]!=0
		mov eax,E_WRONGFORMAT
		jmp _Ex
	.endif
	mov eax,[esi+0ch]
	mov @nInst,eax
	
	lea eax,[eax+eax*2]
	shl eax,3
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _Nomem
	mov [edi].lpStreamIndex,eax
	mov ebx,eax
	assume ebx:ptr _StreamEntry
	
	add esi,114h
	mov @nLine,0
	.while @nInst
		mov eax,[esi]
		add esi,4
		mov ecx,eax
		shr ecx,16
		and ecx,0ffh
		shl ecx,2
		add esi,ecx
		mov ecx,eax
		shr ecx,24
		and ecx,0fh
		.if ax==5
			shr eax,28
			.if eax==2 && ecx==1
				invoke lstrlenA,esi
				lea edx,[esi+eax]
				.while byte ptr [edx]!=','
					.break .if edx<=esi
					dec edx
				.endw
				.if edx!=esi && byte ptr [edx+1]!='*'
					lea ecx,[edx+1]
					mov [ebx].lpStart,ecx
					sub ecx,esi
					sub ecx,eax
					neg ecx
					mov [ebx].nStringLen,ecx
					add ebx,sizeof _StreamEntry
					inc @nLine
				.endif
				lea esi,[esi+eax+1]
				dec @nInst
				.continue
			.endif
			jmp _default
		.elseif ax==1ch
			cmp ecx,2
			jne _default
			.if word ptr [esi]=='*'
				add esi,2
			.else
				invoke lstrlenA,esi
				mov [ebx].lpStart,esi
				mov [ebx].nStringLen,eax
				add ebx,sizeof _StreamEntry
				inc @nLine
				lea esi,[esi+eax+1]
			.endif
			invoke lstrlenA,esi
			mov [ebx].lpStart,esi
			mov [ebx].nStringLen,eax
			add ebx,sizeof _StreamEntry
			inc @nLine
			lea esi,[esi+eax+1]
		.elseif ax==0ch
			cmp ecx,1
			jne _default
			invoke lstrlenA,esi
			mov [ebx].lpStart,esi
			mov [ebx].nStringLen,eax
			add ebx,sizeof _StreamEntry
			inc @nLine
			lea esi,[esi+eax+1]
		.else
		_default:
			push ebx
			mov ebx,ecx
			test ebx,ebx
			jz _exloop1
			_loop1:
				invoke lstrlenA,esi
				lea esi,[esi+eax+1]
				dec ebx
				jnz _loop1
			_exloop1:
			pop ebx
		.endif
		dec @nInst
	.endw
	assume ebx:nothing
	
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
GetText endp

ExhibitSetLine proc uses ebx _lpsz,_cs
	LOCAL @pStr
	invoke lstrlenW,_lpsz
	inc eax
	lea ebx,[eax*2]
	invoke HeapAlloc,hHeap,0,ebx
	test eax,eax
	jz _Err
	mov @pStr,eax
	invoke WideCharToMultiByte,_cs,0,_lpsz,-1,eax,ebx,0,0
	lea ecx,[eax-1]
	mov eax,@pStr
	ret
_Err:
	xor eax,eax
	ret
ExhibitSetLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo

	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	invoke ExhibitSetLine,ebx,[edi].nCharSet
	.if !eax
		mov eax,E_NOMEM
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
		mov edi,[esi].lpStart
		mov esi,@pNewStr
		mov ecx,eax
		rep movsb
	.else
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
		sub ebx,[esi].nStringLen
		
		mov ecx,[edi].lpStreamIndex
		mov eax,[edi].nLine
		lea eax,[eax+eax*2]
		lea ecx,[ecx+eax*4]
		add esi,sizeof _StreamEntry
		.while esi<ecx
			add [esi].lpStart,ebx
			add esi,sizeof _StreamEntry
		.endw
		
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
SaveText proc
	jmp _SaveText
SaveText endp

;
SetLine proc
	jmp _SetLine
SetLine endp

end DllMain