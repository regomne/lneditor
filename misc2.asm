.code

_MakeStringListFromStream proc uses edi esi ebx _lpFI
	local @nStringType,@nLine,@nCharSet
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov esi,[edi].lpStreamIndex
	xor ebx,ebx
	mov ecx,[edi].nStringType
	mov eax,[edi].nLine
	.if !eax
		xor eax,eax
		jmp _ExMSL
	.endif
	mov edx,[edi].nCharSet
	mov @nStringType,ecx
	mov @nCharSet,edx
	mov @nLine,eax
	shl eax,2
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	.if !eax
		mov eax,E_NOMEM
		jmp _ExMSL
	.endif
	mov [edi].lpTextIndex,eax
	assume edi:nothing
	mov edi,eax
	.while ebx<@nLine
		push esi
		push edi
		push _lpFI
		call dbSimpFunc+_SimpFunc.GetStr
;		invoke _GetStringFromStmPtr,_lpFI,edi,esi
		or eax,eax
		jnz _ExMSL
		add edi,4
		add esi,sizeof _StreamEntry
		inc ebx
	.endw
	xor eax,eax
_ExMSL:
	ret
_MakeStringListFromStream endp

_GetStringFromStmPtr proc uses esi edi ebx _lpFI,_lppString,_lpStreamEntry
	LOCAL @nStrLen,@bIsEnd
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov eax,[edi].nStringType
	MOV edx,[edi].nCharSet
	assume edi:nothing
	.if eax==ST_ENDWITHZERO
		mov ecx,_lpStreamEntry
		mov esi,_StreamEntry.lpStart[ecx]
		.if edx==CS_UNICODE
			invoke lstrlenW,esi
			lea ecx,[eax+eax+2]
		.else
			invoke lstrlenA,esi
			lea ecx,[eax+1]
		.endif
	.elseif eax==ST_PASCAL2
		mov ecx,_lpStreamEntry
		mov esi,_StreamEntry.lpStart[ecx]
		xor ecx,ecx
		mov cx,[esi]
		add esi,2
		.if edx==CS_UNICODE
			SHL ecx,1
		.endif
	.elseif eax==ST_PASCAL4
		mov ecx,_lpStreamEntry
		mov esi,_StreamEntry.lpStart[ecx]
		mov ecx,[esi]
		add esi,4
		.if edx==CS_UNICODE
			SHL ecx,1
		.endif
	.elseif eax==ST_SPECLEN
		mov ecx,_lpStreamEntry
		mov esi,_StreamEntry.lpStart[ecx]
		mov ecx,_StreamEntry.nStringLen[ecx]
	.elseif eax==ST_TXTENDW
		mov ecx,_lpStreamEntry
		mov edi,_StreamEntry.lpStart[ecx]
		xor ecx,ecx
		.while word ptr [edi]!=0dh
			.break .if !word ptr [edi]
			add edi,2
			add ecx,2
		.endw
		mov @nStrLen,ecx
		add ecx,2
		invoke HeapAlloc,hGlobalHeap,0,ecx
		.if !eax
			mov eax,E_NOMEM
			jmp _ExGSFS
		.endif
		mov edx,_lppString
		mov [edx],eax
		mov ecx,@nStrLen
		shr ecx,1
		mov edi,eax
		mov edx,_lpStreamEntry
		mov esi,_StreamEntry.lpStart[edx]
		rep movsw
		mov word ptr [edi],0
		xor eax,eax
		jmp _ExGSFS
	.elseif eax==ST_TXTENDA
		.if edx==CS_UNICODE
			mov eax,E_INVALIDPARAMETER
			jmp _ExGSFS
		.endif
		mov ecx,_lpStreamEntry
		mov edi,_StreamEntry.lpStart[ecx]
		mov @bIsEnd,0
		xor ecx,ecx
		.while word ptr [edi]!=0a0dh
			.break .if !byte ptr [edi]
			inc edi
			inc ecx
		.endw
		mov @nStrLen,ecx
		inc ecx
		shl ecx,1
		mov eax,ecx
		shr ecx,1
		push ecx
		invoke HeapAlloc,hGlobalHeap,0,eax
		.if !eax
			add esp,4
			mov eax,E_NOMEM
			jmp _ExGSFS
		.endif
		mov edx,_lppString
		push ecx
		mov [edx],eax
		push eax
		push @nStrLen
		mov ecx,_lpStreamEntry
		push _StreamEntry.lpStart[ecx]
		push 0
		mov ebx,_lpFI
		mov eax,[ebx+_FileInfo.nCharSet]
		push eax
		call MultiByteToWideChar
		.if !eax
			mov eax,E_NOTENOUGHBUFF
			jmp _ExGSFS
		.endif
		mov ecx,_lpStreamEntry
		mov ecx,_StreamEntry.lpStart[ecx]
		mov word ptr [ecx+eax*2],0
		xor eax,eax
		jmp _ExGSFS
	.else
		mov eax,E_INVALIDPARAMETER
		jmp _ExGSFS
	.endif
	assume edi:ptr _FileInfo
	mov @nStrLen,ecx
	.if edx==CS_UNICODE
		add ecx,4
		invoke HeapAlloc,hGlobalHeap,0,ecx
		.if !eax
			mov eax,E_NOMEM
			jmp _ExGSFS
		.endif
		mov ecx,_lppString
		mov [ecx],eax
		mov ecx,@nStrLen
		mov edx,[edi].nStringType
		mov edi,eax
		shr ecx,1
		rep movsw
		.if edx==ST_PASCAL2 || EDX==ST_PASCAL4 || edx==ST_SPECLEN
			mov word ptr [edi],0
		.endif
	.else
		inc ecx
		shl ecx,1
		mov ebx,ecx
		invoke HeapAlloc,hGlobalHeap,0,ecx
		.if !eax
			add esp,4
			mov eax,E_NOMEM
			jmp _ExGSFS
		.endif
		mov ecx,_lppString
		mov [ecx],eax
		.if @nStrLen!=0
			invoke MultiByteToWideChar,[edi].nCharSet,0,esi,@nStrLen,eax,ebx
			.if !eax
				mov ecx,_lppString
				invoke HeapFree,hGlobalHeap,0,[ecx]
				mov eax,E_NOTENOUGHBUFF
				jmp _ExGSFS
			.endif
		.else
			xor eax,eax
		.endif
		mov edx,[edi].nStringType
		.if edx==ST_PASCAL2 || EDX==ST_PASCAL4 || edx==ST_SPECLEN
			mov ecx,_lppString
			mov edx,[ecx]
			mov word ptr [edx+eax*2],0
		.endif
	.endif
	assume edi:nothing
	xor eax,eax
_ExGSFS:
	ret
_GetStringFromStmPtr endp

_RecodeFile proc uses esi ebx edi _lpFI,_bReopen,_bReread
	LOCAL @ret
	mov esi,_lpFI
	assume esi:ptr _FileInfo
	.if !_bReopen && [esi].nMemoryType==MT_POINTERONLY
		mov ebx,[esi].lpTextIndex
		invoke _MakeStringListFromStream,_lpFI
		.if eax
			mov [esi].lpTextIndex,ebx
			jmp _ExRF
		.endif
		mov edi,ebx
		xor ebx,ebx
		.while ebx<[esi].nLine
			mov eax,[edi+ebx*4]
			.if eax
				invoke HeapFree,hGlobalHeap,0,eax
			.endif
			inc ebx
		.endw
		invoke VirtualFree,edi,0,MEM_RELEASE
	.else
		mov eax,dbSimpFunc+_SimpFunc.Release
		.if eax
			push esi
			call eax
		.endif
		.if [esi].nMemoryType==MT_EVERYSTRING || [esi].nMemoryType==MT_POINTERONLY
			mov edi,[esi].lpTextIndex
			xor ebx,ebx
			.while ebx<[esi].nLine
				invoke HeapFree,hGlobalHeap,0,[edi+ebx*4]
				inc ebx
			.endw
		.endif
		invoke VirtualFree,[esi].lpTextIndex,0,MEM_RELEASE
		mov [esi].lpTextIndex,0
		invoke VirtualFree,[esi].lpStreamIndex,0,MEM_RELEASE
		mov [esi].lpStreamIndex,0
		.if _bReread
			invoke VirtualFree,[esi].lpStream,0,MEM_RELEASE
			mov [esi].lpStream,0
			mov [esi].nStreamSize,0
		.endif
		lea eax,@ret
		push eax
		push _lpFI
		call dword ptr [dbSimpFunc+_SimpFunc.GetText]
		.if eax
			mov eax,E_FATALERROR
			jmp _ExRF
		.endif
	.endif
	assume esi:nothing
	xor eax,eax
_ExRF:
	ret
_RecodeFile endp

;
_GetMelInfo2 proc _idx
	mov eax,_idx
	.if eax==-1
		lea eax,dbMelInfo2
	.else
		mov ecx,sizeof _MelInfo
		mul ecx
		add eax,lpMels
		mov eax,_MelInfo.lpMelInfo2[eax]
	.endif
	ret
_GetMelInfo2 endp

;
_GetCodeIndex proc _code
	mov ecx,_code
	.if ecx==CS_GBK
		mov eax,1
	.elseif ecx==CS_SJIS
		mov eax,2
	.elseif ecx==CS_BIG5
		mov eax,3
	.elseif ecx==CS_UTF8
		mov eax,4
	.elseif ecx==CS_UNICODE
		mov eax,5
	.else
		xor eax,eax
	.endif
	ret
_GetCodeIndex endp

;
_AddCodeCombo proc uses esi _hCombo
	mov esi,SendMessageW
	assume esi:ptr arg4
	invoke esi,_hCombo,CB_ADDSTRING,0,offset szcdDefault
	invoke esi,_hCombo,CB_ADDSTRING,0,offset szcdGBK
	invoke esi,_hCombo,CB_ADDSTRING,0,offset szcdSJIS
	invoke esi,_hCombo,CB_ADDSTRING,0,offset szcdBig5
	invoke esi,_hCombo,CB_ADDSTRING,0,offset szcdUTF8
	invoke esi,_hCombo,CB_ADDSTRING,0,offset szcdUnicode
	assume esi:nothing
	ret
_AddCodeCombo endp

;
_GetDispLine proc _nRealLine
	.if lpDisp2Real
_BeginGDL:
		mov eax,_nRealLine
		cmp eax,FileInfo1.nLine
		ja _ErrGDL
		mov ecx,lpMarkTable
		test byte ptr [ecx+eax],2
		jne _ErrGDL
		mov ecx,lpDisp2Real
		xor edx,edx
		.while edx<FileInfo1.nLine
			.if eax==dword ptr [ecx+edx*4]
				mov eax,edx
				ret
			.endif
			inc edx
		.endw
		jmp _ErrGDL
	.endif
	push esi
	push edi
	mov esi,lpMarkTable
	.if esi
		mov eax,FileInfo1.nLine
		shl eax,2
		invoke HeapAlloc,hGlobalHeap,0,eax
		or eax,eax
		je _ErrGDL
		mov lpDisp2Real,eax
		mov edi,eax
		or eax,-1
		mov ecx,FileInfo1.nLine
		rep stosb
		mov edi,lpDisp2Real
		xor eax,eax
		mov edx,FileInfo1.nLine
		.while eax<edx
			.if !(byte ptr [esi+eax]&2)
				stosd
			.endif
			inc eax
		.endw
	.else
		pop edi
		mov eax,_nRealLine
		pop esi
		ret
	.endif
	pop edi
	pop esi
	jmp _BeginGDL
	ret
_ErrGDL:
	or eax,-1
	ret
_GetDispLine endp

;
_GetRealLine proc _nDispLine
	.if lpDisp2Real
_BeginGRL:
		mov eax,_nDispLine
		mov ecx,lpDisp2Real
		mov eax,[ecx+eax*4]
		ret
	.endif
	push esi
	push edi
	mov esi,lpMarkTable
	.if esi
		mov eax,FileInfo1.nLine
		shl eax,2
		invoke HeapAlloc,hGlobalHeap,0,eax
		or eax,eax
		je _ErrGRL
		mov lpDisp2Real,eax
		mov edi,eax
		or eax,-1
		mov ecx,FileInfo1.nLine
		rep stosb
		mov edi,lpDisp2Real
		xor eax,eax
		mov edx,FileInfo1.nLine
		.while eax<edx
			.if !(byte ptr [esi+eax]&2)
				stosd
			.endif
			inc eax
		.endw
	.else
		pop edi
		mov eax,_nDispLine
		pop esi
		ret
	.endif
	pop edi
	pop esi
	jmp _BeginGRL
;	mov esi,lpMarkTable
;	mov eax,_nDispLine
;	.if esi
;		mov ebx,FileInfo1.nLine
;		xor ecx,ecx
;		xor edx,edx
;		.while ecx!=eax
;			.if !(byte ptr [esi+edx] & 2)
;				inc ecx
;			.endif
;			inc edx
;			.break .if edx>=ebx
;		.endw
;		mov eax,edx
;	.endif
;	ret
_ErrGRL:
	or eax,-1
	ret
_GetRealLine endp

;
_IsDisplay proc _nRealLine
	mov ecx,lpMarkTable
	.if ecx
		mov edx,_nRealLine
		xor eax,eax
		test byte ptr [ecx+edx],2
		sete al
		ret
	.else
		mov eax,1
		ret
	.endif
_IsDisplay endp

_MatchFilter proc uses esi edi ebx _lpStr,_lpFilter
	LOCAL @szStr[MAX_STRINGLEN]:byte
	mov esi,_lpFilter
	assume esi:ptr _TextFilter
	.if [esi].bInclude
		mov edi,[esi].lpszInclude
	assume esi:nothing
		.if word ptr [edi]
			.repeat
				mov eax,edi
				loop1:
				.while word ptr [edi]!='\'
					.if !word ptr [edi]
				loop2:
						invoke lstrcpyW,addr @szStr,eax
						jmp loop3
					.endif
					add edi,2
				.endw
				cmp word ptr [edi+2],0
				je loop2
				.if word ptr [edi+2]!='n'
					add edi,4
					jmp loop1
				.endif
				mov ecx,edi
				sub ecx,eax
				shr ecx,1
				mov esi,eax
				mov edx,edi
				lea edi,@szStr
				rep movsw
				mov word ptr [edi],0
				lea edi,[edx+4]
				loop3:
				invoke _WildcharMatchW,addr @szStr,_lpStr
				or eax,eax
				jne _NextMatch
			.until !word ptr [edi]
			jmp _NotMatch
		.endif
	.endif
_NextMatch:
	mov esi,_lpFilter
	assume esi:ptr _TextFilter
	.if [esi].bExclude
		mov edi,[esi].lpszExclude
	assume esi:nothing
		.if word ptr [edi]
			.repeat
				mov eax,edi
				loop4:
				.while word ptr [edi]!='\'
					.if !word ptr [edi]
				loop5:
						invoke lstrcpyW,addr @szStr,eax
						jmp loop6
					.endif
					add edi,2
				.endw
				cmp word ptr [edi+2],0
				je loop5
				.if word ptr [edi+2]!='n'
					add edi,4
					jmp loop4
				.endif
				mov ecx,edi
				sub ecx,eax
				shr ecx,1
				mov esi,eax
				mov edx,edi
				lea edi,@szStr
				rep movsw
				mov word ptr [edi],0
				lea edi,[edx+4]
				loop6:
				invoke _WildcharMatchW,addr @szStr,_lpStr
				or eax,eax
				jne _NotMatch
			.until !word ptr [edi]
		.endif
	.endif
	mov eax,1
	ret
_NotMatch:
	xor eax,eax
	ret
_MatchFilter endp

_UpdateHideTable proc uses esi ebx _lpFI
	LOCAL @nLine
	mov ecx,_lpFI
	mov eax,_FileInfo.nLine[ecx]
	mov @nLine,eax
	xor ebx,ebx
	mov esi,lpMarkTable
	.while ebx<@nLine
		invoke _GetStringInList,_lpFI,ebx
		.if eax
			invoke _MatchFilter,eax,offset dbConf+_Configs.TxtFilter
			not al
			and al,1
			shl al,1
			or byte ptr [esi+ebx],al
		.endif
		inc ebx
	.endw
	ret
_UpdateHideTable endp

_ResetHideTable proc _lpFI
	mov ecx,_lpFI
	mov edx,_FileInfo.nLine[ecx]
	mov eax,lpMarkTable
	xor ecx,ecx
	.if eax
		.while ecx<edx
			and byte ptr [eax+ecx],not 2
			inc ecx
		.endw
	.endif
	.if lpDisp2Real
		invoke HeapFree,hGlobalHeap,0,lpDisp2Real
		mov lpDisp2Real,0
	.endif
	ret
_ResetHideTable endp

_CalcCenterIndex proc uses ebx esi edi _nCurTop,_nCur
	LOCAL @rect:RECT
	mov ebx,_nCur
	cmp ebx,1
	jbe _Ex
	dec ebx
	xor esi,esi
	mov ecx,dbConf+_Configs.windowRect[WRI_LIST2]+RECT.bottom
	sub ecx,dbConf+_Configs.windowRect[WRI_LIST2]+RECT.top
	shl ecx,1
	mov eax,0cccccccdh
	mul ecx
	mov edi,eax
	.while ebx>_nCurTop
		invoke SendMessageW,hList2,LB_GETITEMRECT,ebx,addr @rect
		mov eax,@rect.bottom
		sub eax,@rect.top
		add esi,eax
		.if esi>=edi
			mov eax,ebx
			ret
		.endif
		dec ebx
	.endw
_Ex:
	or eax,-1
	ret
_CalcCenterIndex endp

;
_MakeFile proc _lpFileName
	LOCAL @szStr1[1024]:byte
	invoke lstrcpyW,addr @szStr1,_lpFileName
	lea ecx,@szStr1
	lea ecx,[ecx+eax*2-2]
	invoke CreateFileW,addr @szStr1,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if eax==INVALID_HANDLE_VALUE
		invoke GetLastError
		.if eax==ERROR_PATH_NOT_FOUND
			push esi
			push edi
			push ebx
			lea edi,@szStr1
			or ecx,-1
			xor ax,ax
			repne scasw
			sub edi,2
			not ecx
			dec ecx
			std
			mov ax,'\'
			repne scasw
			cld
			lea ebx,[edi+2]
			mov word ptr [ebx],0
			lea edi,@szStr1
			mov ecx,ebx
			sub ecx,edi
			shr ecx,1
			.while edi<ebx
				repne scasw
				.if ecx
					mov esi,ecx
					mov word ptr [edi-2],0
					invoke CreateDirectoryW,addr @szStr1,0
					mov word ptr [edi-2],'\'
					.if !eax
						invoke GetLastError
						.if eax!=ERROR_ALREADY_EXISTS
							mov word ptr [ebx],'\'
							pop ebx
							pop edi
							pop esi
							xor eax,eax
							ret
						.endif
					.endif
					mov ecx,esi
					mov ax,'\'
				.else
					mov edi,ebx
					invoke CreateDirectoryW,addr @szStr1,0
					mov word ptr [ebx],'\'
					invoke CreateFileW,addr @szStr1,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
					.if eax==INVALID_HANDLE_VALUE
						xor eax,eax
					.endif
				.endif
			.endw
			pop ebx
			pop edi
			pop esi
		.else
			xor eax,eax
		.endif
	.endif
	ret
_MakeFile endp

_MakePath proc _lpFileName
	LOCAL @szStr1[1024]:byte
	invoke lstrcpyW,addr @szStr1,_lpFileName
	lea ecx,@szStr1
	lea ecx,[ecx+eax*2-2]
	invoke CreateFileW,addr @szStr1,GENERIC_WRITE,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax==INVALID_HANDLE_VALUE
		invoke GetLastError
		.if eax==ERROR_PATH_NOT_FOUND
			push esi
			push edi
			push ebx
			lea edi,@szStr1
			or ecx,-1
			xor ax,ax
			repne scasw
			sub edi,2
			not ecx
			dec ecx
			std
			mov ax,'\'
			repne scasw
			cld
			lea ebx,[edi+2]
			mov word ptr [ebx],0
			lea edi,@szStr1
			mov ecx,ebx
			sub ecx,edi
			shr ecx,1
			.while edi<ebx
				repne scasw
				.if ecx
					mov esi,ecx
					mov word ptr [edi-2],0
					invoke CreateDirectoryW,addr @szStr1,0
					mov word ptr [edi-2],'\'
					.if !eax
						invoke GetLastError
						.if eax!=ERROR_ALREADY_EXISTS
							mov word ptr [ebx],'\'
							pop ebx
							pop edi
							pop esi
							xor eax,eax
							ret
						.endif
					.endif
					mov ecx,esi
					mov ax,'\'
				.else
					mov edi,ebx
					invoke CreateDirectoryW,addr @szStr1,0
					mov word ptr [ebx],'\'
					invoke CreateFileW,addr @szStr1,GENERIC_WRITE,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
					.if eax==INVALID_HANDLE_VALUE
						xor eax,eax
					.endif
				.endif
			.endw
			pop ebx
			pop edi
			pop esi
		.else
			xor eax,eax
		.endif
	.endif
	ret
_MakePath endp

;
_CalcCheckSum proc uses esi ebx _lpBuff,_nSize
	mov esi,_lpBuff
	xor eax,eax
	mov edx,eax
	xor ecx,ecx
	mov ebx,_nSize
	.while ecx<ebx
		add al,byte ptr [esi+ecx]
		add dl,al
		inc ecx
	.endw
	shl edx,8
	or eax,edx
	ret
_CalcCheckSum endp

;
_FindPlugin proc uses edi ebx esi _lpszName,_dwType
	LOCAL @pStr
	invoke lstrcmpiW,_lpszName,offset szTxt+2
	.if !eax && _dwType==1
		mov eax,-1
		ret
	.endif
	invoke HeapAlloc,hGlobalHeap,0,SHORT_STRINGLEN
	test eax,eax
	jz _Err
	mov @pStr,eax
	xor ecx,ecx
	mov edi,eax
	mov esi,_lpszName
	.while ecx<SHORT_STRINGLEN
		mov ax,[esi+ecx]
		.if ax=='.'
			mov word ptr [edi+ecx],0
			.break
		.endif
		mov [edi+ecx],ax
		.break .if !ax
		add ecx,2
	.endw
	
	.if _dwType==1
		mov edi,lpMels
		invoke lstrcatW,@pStr,$CTW0(".mel")
		mov esi,sizeof _MelInfo
	.elseif _dwType==2
		mov edi,lpMefs
		invoke lstrcatW,@pStr,$CTW0(".mef")
		mov esi,sizeof _MefInfo
	.endif
	
	xor ebx,ebx
	.while ebx<MAX_MELCOUNT
		invoke lstrcmpiW,edi,@pStr
		test eax,eax
		jz _Success
		add edi,esi
		inc ebx
	.endw
	invoke HeapFree,hGlobalHeap,0,@pStr
_Err:
	mov eax,-2
	ret
_Success:
	invoke HeapFree,hGlobalHeap,0,@pStr
	mov eax,edi
	mov ecx,ebx
	ret
_FindPlugin endp


_ReplaceCharsW proc uses esi edi ebx  _lpStr,_nOption,_lpReserved
	LOCAL @lpNew
	mov @lpNew,0
	mov eax,_nOption
	and eax,0ffffh
	.if eax&RCH_ENTERS
		mov esi,_lpStr
		invoke lstrlenW,esi
		lea ebx,[eax+1]
		xor ecx,ecx
		xor edx,edx
		.while ecx<ebx
			mov ax,[esi+ecx*2]
			.if ax==0ah || ax==0dh || ax==9
				inc edx
			.endif
			inc ecx
		.endw
		inc edx
		shl edx,1
		lea eax,[ebx*2+edx]
		invoke HeapAlloc,hGlobalHeap,0,eax
		test eax,eax
		jz _ExRC
		mov @lpNew,eax
		mov edi,eax
		
		mov eax,_nOption
		.if eax&RCH_TOESCAPE
			xor ecx,ecx
			.while ecx<ebx
				mov ax,[esi+ecx*2]
				.if ax==0ah
					mov word ptr [edi],'\'
					mov word ptr [edi+2],'n'
					add edi,4
				.elseif ax==0dh
					mov word ptr [edi],'\'
					mov word ptr [edi+2],'r'
					add edi,4
				.elseif ax==9
					mov word ptr [edi],'\'
					mov word ptr [edi+2],'t'
					add edi,4
				.else
					mov word ptr [edi],ax
					add edi,2
				.endif
				inc ecx
			.endw
		.else
			xor ecx,ecx
			.while ecx<ebx
				mov ax,[esi+ecx*2]
				.if ax=='\'
					mov dx,[esi+ecx*2+2]
					.if dx=='n'
						mov word ptr [edi],0ah
						inc ecx
					.elseif dx=='r'
						mov word ptr [edi],0dh
						inc ecx
					.elseif dx=='t'
						mov word ptr [edi],9
						inc ecx
					.else
						mov word ptr [edi],'\'
					.endif
				.else
					mov [edi],ax
				.endif
				add edi,2
				inc ecx
			.endw
		.endif
	.endif
	mov eax,@lpNew
	ret
_ExRC:
	xor eax,eax
	ret
_ReplaceCharsW endp

_IsRelativePath proc _lpszPath
	mov eax,1
	mov ecx,_lpszPath
	.if word ptr [ecx+2]==':' || word ptr [ecx]=='\'
		xor eax,eax
	.endif
	ret
_IsRelativePath endp
