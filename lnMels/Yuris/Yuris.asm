.386
.model flat,stdcall
option casemap:none

include Yuris.inc

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
	.if dword ptr [edx]==59002eh && dword ptr [edx+4]==04E0042h
		invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		cmp eax,-1
		je _ErrMatch
		push eax
		lea esi,@szMagic
		invoke ReadFile,eax,esi,8,offset dwTemp,0
		call CloseHandle
		cmp dword ptr [esi],'BTSY'
		jne _NotMatch
		xor ecx,ecx
		mov eax,[esi+4]
		lea esi,VerTable
		assume esi:ptr YurisVerInfo
		.while ecx<nVerInfos
			.if eax>=[esi].nVerMin && eax<=[esi].nVerMax
				mov eax,MR_YES
				RET
			.endif
			add esi,sizeof YurisVerInfo
			inc ecx
		.endw
		assume esi:nothing
		mov eax,MR_NO
		ret
		_Match:
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
YurisGetLine proc _lpStr,_nLen,_nCS
	LOCAL @pStr
	
	mov ecx,_nLen
	inc eax
	shl ecx,1
	invoke HeapAlloc,hHeap,0,ecx
	or eax,eax
	je _Ex
	push eax
	
	mov ecx,_nLen
	inc ecx
;	.if _bTrimQuote
;		mov edx,_lpStr
;		.if byte ptr [edx]=='"' || byte ptr [edx]=="'"
;			inc _lpStr
;			dec _nLen
;		.endif
;		add edx,_nLen
;		.if byte ptr [edx]=='"' || byte ptr [edx]=="'"
;			dec _nLen
;		.endif
;	.endif
	invoke MultiByteToWideChar,_nCS,0,_lpStr,_nLen,eax,ecx
	mov ecx,eax
	pop eax
	mov word ptr [eax+ecx*2],0
_Ex:
	ret
YurisGetLine endp

;
YurisCmpFuncName proc uses ebx esi edi _lpRes,_nLen
	LOCAL @pStr
	mov esi,_lpRes
	.if byte ptr [esi]!='M'
		xor eax,eax
		ret
	.endif
	mov ecx,_nLen
	inc ecx
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,ecx
	test eax,eax
	jz _Ex
	mov @pStr,eax
	add esi,3
	mov edi,eax
	mov ecx,_nLen
	sub ecx,3
	_loop1:
		mov al,[esi]
		inc esi
		or al,20h
		mov [edi],al
		inc edi
		dec ecx
		jnz _loop1
	
	mov ebx,_nLen
	sub ebx,3
	
	mov ecx,ebx
	mov esi,@pStr
	lea edi,dbFSel
	repe cmpsb
	.if ZERO?
		mov ebx,FUNC_SEL
		jmp _out
	.endif
	
	mov ecx,ebx
	mov esi,@pStr
	lea edi,dbFMarkSet
	repe cmpsb
	.if ZERO?
		mov ebx,FUNC_MARKSET
		jmp _out
	.endif
	
	mov ecx,ebx
	mov esi,@pStr
	lea edi,dbFCharName
	repe cmpsb
	.if ZERO?
		mov ebx,FUNC_CHARNAME
		jmp _out
	.endif
	
	mov ecx,ebx
	mov esi,@pStr
	lea edi,dbFInputStr
	repe cmpsb
	.if ZERO?
		mov ebx,FUNC_INPUTSTR
		jmp _out
	.endif
	
	mov ecx,ebx
	mov esi,@pStr
	lea edi,dbFTipsStr
	repe cmpsb
	.if ZERO?
		mov ebx,FUNC_TIPS
		jmp _out
	.endif
	
	mov ecx,ebx
	mov esi,@pStr
	lea edi,dbFTipsTxStr
	repe cmpsb
	.if ZERO?
		mov ebx,FUNC_TIPSTX
		jmp _out
	.endif
	xor ebx,ebx
_out:
	invoke HeapFree,hHeap,0,@pStr
	mov eax,ebx
_Ex:
	ret
YurisCmpFuncName endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @nTemp,@opMsg,@opCall
	LOCAL @pCode,@pArg,@lpRes,@pInstEnd
	LOCAL @nInst
	LOCAL @nLine
	LOCAL @hdr:YurisHdr
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStream
	lea edi,@hdr
	mov ecx,sizeof YurisHdr/4
	rep movsd
	mov edi,_lpFI

	lea esi,VerTable
	mov eax,@hdr.nVersion
	xor ebx,ebx
	assume esi:ptr YurisVerInfo
	.while ecx<nVerInfos
		.if eax>=[esi].nVerMin && eax<=[esi].nVerMax
			mov ax,[esi].opMsg
			mov cx,[esi].opCall
			mov word ptr @opMsg,ax
			mov byte ptr @opCall,cl
			inc ebx
			.break
		.endif
		add esi,sizeof YurisVerInfo
		inc ecx
	.endw
	.if !ebx
		mov eax,E_WRONGFORMAT
		ret
	.endif
	assume esi:nothing
	
	cmp @hdr.nVersion,124h
	ja _NewVer
_OldVer:
	mov eax,@hdr.segInfo.s2.nInstSize
	shr eax,1
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
	
	mov esi,[edi].lpStream
	add esi,sizeof YurisHdr
	mov @pCode,esi
	mov ecx,esi
	add ecx,@hdr.segInfo.s2.nInstSize
	mov @pInstEnd,ecx
	mov eax,@hdr.segInfo.s2.nResOff
	add eax,[edi].lpStream
	mov @lpRes,eax
	
	xor ebx,ebx
	.while esi<@pInstEnd
		mov ax,[esi]
		add esi,6
		.if al==38h
			add esi,4
			.continue
		.elseif ax==word ptr @opMsg
			mov edx,esi
			mov @pArg,esi
			assume edx:ptr YurisArg
			add esi,12
			.continue .if [edx].len1==0
			mov eax,[edx].offset1
			add eax,@lpRes
			.if [edx].type1!=0
				int 3
			.endif
			invoke YurisGetLine,eax,[edx].len1,[edi].nCharSet
			or eax,eax
			je _Nomem
			assume edx:nothing
			mov edx,[edi].lpTextIndex
			mov [edx+ebx*4],eax
			mov edx,[edi].lpStreamIndex
			mov eax,@pArg
			lea ecx,[ebx+ebx*2]
			mov _StreamEntry.lpStart[edx+ecx*4],eax
			inc ebx
		.elseif al==byte ptr @opCall && ah!=0
			mov @pArg,esi
			mov edx,esi
			mov ecx,YurisArg.offset1[edx]
			add ecx,@lpRes
			movzx eax,ah
			mov @nTemp,eax
			invoke YurisCmpFuncName,ecx,YurisArg.len1[edx]
			.if !eax
				mov al,byte ptr @nTemp
				shl ax,8
				jmp _Default2
			.endif
			dec @nTemp
			add esi,12
			.repeat
				assume edx:ptr YurisArg
				mov edx,esi
				cmp [edx].len1,0
				je _Ctn22
				mov eax,[edx].offset1
				add eax,@lpRes
				.if [edx].type1==3
					movzx ecx,word ptr [eax+1]
					or ecx,ecx
					je _Ctn22
					.if byte ptr [eax]!=4dh
						int 3
					.endif
					add eax,3
					cmp word ptr [eax],"''"
					je _Ctn22
					cmp word ptr [eax],'""'
					je _Ctn22
					invoke YurisGetLine,eax,ecx,[edi].nCharSet
					or eax,eax
					je _Nomem
					assume edx:nothing
					mov edx,[edi].lpTextIndex
					mov [edx+ebx*4],eax
					mov edx,[edi].lpStreamIndex
					lea ecx,[ebx+ebx*2]
					mov _StreamEntry.lpStart[edx+ecx*4],esi
					inc ebx
				.endif
			_Ctn22:
				dec @nTemp
				add esi,12
			.until @nTemp==0
		.else
	_Default2:
			movzx eax,ah
			shl eax,2
			lea ecx,[eax+eax*2]
			add esi,ecx
		.endif
	.endw
	mov [edi].nLine,ebx
	mov [edi].nMemoryType,MT_EVERYSTRING
	jmp _End
	
_NewVer:
	mov eax,@hdr.segInfo.s1.nArgSize
	shr eax,1
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
	
	mov esi,[edi].lpStream
	add esi,sizeof YurisHdr
	mov @pCode,esi
	mov eax,esi
	add eax,@hdr.segInfo.s1.nCodeSize
	mov @pArg,eax
	add eax,@hdr.segInfo.s1.nArgSize
	mov @lpRes,eax
	
	xor ebx,ebx
	mov @nLine,ebx
	.while ebx<@hdr.segInfo.s1.nCount
		lodsd
		.if ax==word ptr @opMsg
			mov edx,@pArg
			assume edx:ptr YurisArg
			cmp [edx].len1,0
			je _Ctn
			mov eax,[edx].offset1
			add eax,@lpRes
			.if [edx].type1!=0
				int 3
			.endif
			invoke YurisGetLine,eax,[edx].len1,[edi].nCharSet
			or eax,eax
			je _Nomem
			assume edx:nothing
			mov ecx,@nLine
			mov edx,[edi].lpTextIndex
			mov [edx+ecx*4],eax
			mov edx,[edi].lpStreamIndex
			mov eax,@pArg
			lea ecx,[ecx+ecx*2]
			mov _StreamEntry.lpStart[edx+ecx*4],eax
			inc @nLine
			add @pArg,12
		.elseif al==byte ptr @opCall && ah!=0
			mov edx,@pArg
			mov ecx,YurisArg.offset1[edx]
			add ecx,@lpRes
			movzx eax,ah
			mov @nTemp,eax
			invoke YurisCmpFuncName,ecx,YurisArg.len1[edx]
			.if !eax
				mov al,byte ptr @nTemp
				shl ax,8
				jmp _Default
			.endif
			dec @nTemp
			add @pArg,12
			.repeat
				assume edx:ptr YurisArg
				mov edx,@pArg
				cmp [edx].len1,0
				je _Ctn2
				mov eax,[edx].offset1
				add eax,@lpRes
				.if [edx].type1==3
					movzx ecx,word ptr [eax+1]
					or ecx,ecx
					je _Ctn2
					.if byte ptr [eax]!=4dh
						int 3
					.endif
					add eax,3
					cmp word ptr [eax],"''"
					je _Ctn2
					cmp word ptr [eax],'""'
					je _Ctn2
					invoke YurisGetLine,eax,ecx,[edi].nCharSet
					or eax,eax
					je _Nomem
					assume edx:nothing
					mov ecx,@nLine
					mov edx,[edi].lpTextIndex
					mov [edx+ecx*4],eax
					mov edx,[edi].lpStreamIndex
					mov eax,@pArg
					lea ecx,[ecx+ecx*2]
					mov _StreamEntry.lpStart[edx+ecx*4],eax
					inc @nLine
				.endif
			_Ctn2:
				dec @nTemp
				add @pArg,12
			.until @nTemp==0
		.else
	_Default:
			movzx eax,ah
			shl eax,2
			lea ecx,[eax+eax*2]
			add @pArg,ecx
		.endif
	_Ctn:
		inc ebx
	.endw
	mov eax,@nLine
	mov [edi].nLine,eax
	mov [edi].nMemoryType,MT_EVERYSTRING

_End:
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
YurisSetLine proc uses esi edi _lpStr,_nType,_nCS
	LOCAL @nChar,@pStr2,@pStr
	invoke lstrlenW,_lpStr
	mov @nChar,eax
	cmp eax,0ffffh/2
	ja _Err
	.if _nType==3
		add eax,2
	.elseif _nType!=0
		jmp _Err
	.endif
	inc eax
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Err
	mov @pStr,eax
	.if _nType==3
		mov byte ptr [eax],4dh
		add eax,3
	.endif
	mov ecx,@nChar
	inc ecx
	shl ecx,1
	invoke WideCharToMultiByte,_nCS,0,_lpStr,-1,eax,ecx,0,0
	.if !eax
		int 3
	.endif
	lea ecx,[eax-1]
	.if _nType==3
		mov edx,@pStr
		mov word ptr [edx+1],cx
		add ecx,3
	.endif
	mov eax,@pStr
	ret
_Err:
	xor eax,eax
	ret
YurisSetLine endp

YurisCheckLine proc _lpBuff
	mov edx,_lpBuff
	movzx eax,word ptr [edx+1]
	mov cl,[edx+3]
	.if cl!='"' && cl!="'"
		xor eax,eax
		ret
	.endif
	lea edx,[edx+eax+2]
	mov cl,[edx]
	.if cl!='"' && cl!="'"
		xor eax,eax
		ret
	.endif
	mov eax,1
	ret
YurisCheckLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	LOCAL @hdr:YurisHdr
	LOCAL @lpRes
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStream
	lea edi,@hdr
	mov ecx,sizeof YurisHdr/4
	rep movsd
	mov edi,_lpFI
	.if @hdr.nVersion<=124h
		mov esi,[edi].lpStream
		add esi,@hdr.segInfo.s2.nResOff
	.else
		add esi,@hdr.segInfo.s1.nCodeSize
		add esi,@hdr.segInfo.s1.nArgSize
	.endif
	mov @lpRes,esi
	
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	mov esi,_StreamEntry.lpStart[ecx+eax*4]
	assume esi:ptr YurisArg
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	movzx eax,[esi].type1
	invoke YurisSetLine,ebx,eax,[edi].nCharSet
	.if !eax
		mov eax,E_NOMEM
		jmp _Ex
	.endif
	mov @pNewStr,eax
	mov @nNewLen,ecx
	.if [esi].type1==3
		invoke YurisCheckLine,@pNewStr
		.if !eax
			mov eax,E_LINEDENIED
			jmp _Ex
		.endif
	.endif
	
	mov eax,[esi].len1
	.if eax>=@nNewLen
		mov edi,[esi].offset1
		add edi,@lpRes
		mov ecx,@nNewLen
		mov [esi].len1,ecx
		mov esi,@pNewStr
		rep movsb
	.else
;		mov ecx,[edi].nStreamSize
;		add ecx,[edi].lpStream
		mov eax,@lpRes
		.if @hdr.nVersion<=124h
			add eax,@hdr.segInfo.s2.nResSize
			xor ecx,ecx
		.else
			add eax,@hdr.segInfo.s1.nResSize
			mov ecx,@hdr.segInfo.s1.nOffSize
		.endif
;		sub ecx,eax
		invoke _ReplaceInMem,@pNewStr,@nNewLen,eax,0,ecx
		.if eax
			mov ebx,eax
			invoke HeapFree,hHeap,0,@pNewStr
			mov eax,ebx
			jmp _Ex
		.endif
		
		.if @hdr.nVersion<=124h
			mov eax,@nNewLen
			mov [esi].len1,eax
			mov ecx,@hdr.segInfo.s2.nResSize
			mov [esi].offset1,ecx
			
			add [edi].nStreamSize,eax
			mov ebx,[edi].lpStream
			assume ebx:ptr YurisHdr
			add [ebx].segInfo.s2.nResSize,eax
		.else
			mov eax,@nNewLen
			mov [esi].len1,eax
			mov ecx,@hdr.segInfo.s1.nResSize
			mov [esi].offset1,ecx
			
			add [edi].nStreamSize,eax
			mov ebx,[edi].lpStream
			assume ebx:ptr YurisHdr
			add [ebx].segInfo.s1.nResSize,eax
		.endif
		assume ebx:nothing
		
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