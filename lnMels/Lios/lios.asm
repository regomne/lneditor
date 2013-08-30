.386
.model flat,stdcall
option casemap:none

include lios.inc

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

;判断文件头
Match proc _lpszName
	LOCAL @hFile,@buff[8]:byte
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,INVALID_HANDLE_VALUE
	je _ErrMatch
	mov @hFile,eax
	invoke ReadFile,@hFile,addr @buff,8,offset dwTemp,0
	invoke CloseHandle,@hFile
	cmp dword ptr [@buff+4],24h
	je @F
	cmp dword ptr [@buff+4],1ch
	jne _NotMatch
	@@:
	
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
PreProc proc _lpPreData
	mov eax,_lpPreData
	mov ecx,[eax+_PreData.hGlobalHeap]
	mov hHeap,ecx
	mov edx,[eax+_PreData.lpHandles]
	mov ecx,[edx]
	mov hWinMain,ecx
	ret
PreProc endp

;
GetText proc uses edi ebx esi _lpFI,_lpRI
	LOCAL @pStream,@pTIdx,@pSIdx,@dwTemp
	LOCAL @nCharSet
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,sizeof(_GscInfo)
	or eax,eax
	je _NomemGT
	mov ebx,_lpFI
	assume ebx:ptr _FileInfo
	mov [ebx].Reserved,eax
	mov esi,[ebx].lpStream
	mov @pStream,esi
	mov edi,eax
	mov ecx,[esi+_GscInfo.sHeader.nHeaderSize]
	invoke _memcpy
	mov edi,[ebx].Reserved
	assume edi:ptr _GscInfo
	mov esi,[ebx].nStreamSize
	mov eax,[edi].sHeader.nHeaderSize
	sub esi,eax
	add @pStream,eax
	
	sub esi,[edi].sHeader.nControlStreamSize
	invoke _MakeFromStream,[edi].sHeader.nControlStreamSize,addr @pStream
	or eax,eax
	je _NomemGT
	mov [edi].lpControlStream,eax
	
	sub esi,[edi].sHeader.nIndexSize
	invoke _MakeFromStream,[edi].sHeader.nIndexSize,addr @pStream
	or eax,eax
	je _NomemGT
	mov [edi].lpIndex,eax
	
	sub esi,[edi].sHeader.nTextSize
	invoke _MakeFromStream,[edi].sHeader.nTextSize,addr @pStream
	or eax,eax
	je _NomemGT
	mov [edi].lpText,eax
 
	invoke _MakeFromStream,esi,addr @pStream
	or eax,eax
	je _NomemGT
	mov [edi].lpExtraData,eax
	
	invoke VirtualAlloc,0,[edi].sHeader.nControlStreamSize,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _NomemGT
	mov [edi].lpIndexCS,eax
	invoke VirtualAlloc,0,[edi].sHeader.nControlStreamSize,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _NomemGT
	mov [edi].lpRelocTable,eax
	
	.if [edi].sHeader.nHeaderSize==24h
		invoke _ProcControlStream,edi,offset dtParamSize20
		or eax,eax
		je _ErrScriptGT
	.elseif [edi].sHeader.nHeaderSize==1ch
		invoke _ProcControlStream,edi,offset dtParamSize21
		or eax,eax
		je _ErrScriptGT
	.endif

	mov [ebx].nMemoryType,MT_EVERYSTRING
	
	mov eax,[edi].nTotalInst
	mov [ebx].nLine,eax
	shl eax,2
	mov esi,eax
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _NomemGT
	mov [ebx].lpTextIndex,eax
	mov @pTIdx,eax
	
	lea eax,[esi+esi*2]
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _NomemGT
	mov [ebx].lpStreamIndex,eax
	mov ecx,[ebx].nCharSet
	mov @pSIdx,eax
	mov @nCharSet,ecx
	.if ecx==CS_UNICODE
		invoke Release,_lpFI
		mov ecx,_lpRI
		mov eax,E_ERROR
		mov dword ptr [ecx],RI_FAIL_ERRORCS
		ret
	.endif
	assume ebx:nothing
	
	xor ebx,ebx
	.while ebx<[edi].nTotalInst
		mov edx,[edi].lpIndexCS
		mov esi,[edx+ebx*4]
		add esi,[edi].lpControlStream
		lodsw
		.if ax==51h
			add esi,14h
			.if dword ptr [esi-4]
				invoke _GetTextByIdx,[esi-4],edi
				lea ecx,@pTIdx
				invoke _AddString,eax,ecx,@nCharSet
				or eax,eax
				je _Nomem2GT
				mov ecx,@pSIdx
				mov _StreamEntry.lpStart[ecx],ebx
				add @pSIdx,sizeof _StreamEntry
			.endif 
_i51GT:
			invoke _GetTextByIdx,[esi],edi
			lea ecx,@pTIdx
			invoke _AddString,eax,ecx,@nCharSet
			or eax,eax
			je _Nomem2GT
			mov ecx,@pSIdx
			mov _StreamEntry.lpStart[ecx],ebx
			add @pSIdx,sizeof _StreamEntry
		.elseif ax==52h
			add esi,10h
			jmp _i51GT
		.elseif ax==0eh
			lodsw
			push ebx
			movzx ebx,ax
			mov @dwTemp,ebx
			invoke _GetTextByIdx,[esi],edi
			lea ecx,@pTIdx
			invoke _AddString,eax,ecx,@nCharSet
			or eax,eax
			je _Nomem2GT
			add esi,18h
			.while ebx
				lodsd
				.break .if !eax
				invoke _GetTextByIdx,eax,edi
				lea ecx,@pTIdx
				invoke _AddString,eax,ecx,@nCharSet
				or eax,eax
				je _Nomem2GT
				dec ebx
			.endw
			pop ebx
			push edi
			mov ecx,@dwTemp
			inc ecx
			mov edx,ecx
			mov edi,@pSIdx
			@@:
				mov _StreamEntry.lpStart[edi],ebx
				add edi,sizeof _StreamEntry
			dec ecx
			jnz @B
			lea edx,[edx+edx*2]
			shl edx,2
			add @pSIdx,edx
			pop edi
		.endif
		inc ebx
	.endw
	assume edi:nothing
	
	mov ebx,_lpFI
	assume ebx:ptr _FileInfo
	mov eax,@pTIdx
	sub eax,[ebx].lpTextIndex
	shr eax,2
	mov [ebx].nLine,eax
	assume ebx:nothing
	
	mov bIsSilent,0
	xor eax,eax
	mov ecx,_lpRI
	mov dword ptr [ecx],RI_SUC_LINEONLY
	ret
_ErrScriptGT:
	invoke Release,_lpFI
	or eax,E_ERROR
	mov ecx,_lpRI
	mov dword ptr [ecx],RI_FAIL_FORMAT
	ret
_NomemGT:
	invoke Release,_lpFI
	or eax,E_ERROR
	mov ecx,_lpRI
	mov dword ptr [ecx],RI_FAIL_MEM
	ret
_Nomem2GT:
	invoke _ReleaseHeap,_lpFI
	jmp _NomemGT
GetText endp

;预读一遍脚本中的控制流，保证没有异常，指令地址记入IndexCS
_ProcControlStream proc uses esi edi ebx _lpGscInfo,_lpTable2
	LOCAL @pIdx,@nCSSize
	mov edx,_lpGscInfo
	mov eax,[edx+_GscInfo.lpIndexCS]
	mov @pIdx,eax
	mov esi,[edx+_GscInfo.lpControlStream]
	mov eax,[edx+_GscInfo.sHeader.nControlStreamSize]
	mov @nCSSize,eax
	xor ebx,ebx
	xor edx,edx
	.while edx<@nCSSize
		mov ax,[esi+edx]
		add edx,2
		mov cx,ax
		and ax,0f000h
		.if !ZERO?
			shr ax,12
			and eax,0fh
			lea edi,dtParamSize1
			movsx eax,byte ptr [edi+eax]
			.if eax==-1
				inc eax
				ret
			.endif
			mov ecx,@pIdx
			mov [ecx],edx
			sub dword ptr [ecx],2
			add @pIdx,4
			add edx,eax
		.else
			mov edi,_lpTable2
			movzx ecx,cl
			movsx eax,byte ptr [edi+ecx]
			.if eax==-1
				inc eax
				ret
			.endif
			push eax
			mov eax,@pIdx
			mov [eax],edx
			sub dword ptr [eax],2
			add @pIdx,4
			pop eax
			add edx,eax
			
			.if (cl>=03 && cl<=05)
				lea eax,[edx-4]
				mov ecx,_lpGscInfo
				mov edi,[ecx+_GscInfo.lpRelocTable]
				mov [edi+ebx],eax
				add ebx,4
				.continue
			.elseif cl==0eh
				lea eax,[edx-52]
				mov ecx,_lpGscInfo
				mov edi,[ecx+_GscInfo.lpRelocTable]
				mov ecx,5
				@@:
					mov [edi+ebx],eax
					add eax,4
					add ebx,4
					.continue .if !dword ptr [esi+eax]
				loop @B
			.endif
		.endif
	.endw
	mov edx,_lpGscInfo
	mov ecx,[edx+_GscInfo.lpIndexCS]
	mov eax,@pIdx
	sub eax,ecx
	shr eax,2
	mov [edx+_GscInfo.nTotalInst],eax
	mov eax,1
	ret
_ProcControlStream endp

_CheckPage proc uses esi _lpStr,_line,_char
	mov esi,_lpStr
	xor edx,edx
	.repeat
		mov ecx,_char
		.repeat
			_Ctn1:
			lodsw
			.if ax=='^'
				lodsw
				.break .if ax=='n'
				.if ax=='d' || ax=='c' || ax=='f'
					lodsw
					or ax,ax
					je _NoPage
				.elseif ax=='g' || ax=='a' || ax=='v'
					.repeat
						lodsw
					.until ax<'0' || ax>'9'
					or ax,ax
					je _NoPage
					.if !ah
						dec ecx
					.else
						sub ecx,2
					.endif
				.else
					cmp ax,'s'
					je _NoPage
					cmp ax,'m'
					je _NoPage
					or ax,ax
					je _NoPage
				.endif
			.elseif !ah
				dec ecx
			.else
				sub ecx,2
			.endif
			or ax,ax
			je _NoPage
			cmp ecx,0
			jg _Ctn1
			.break
		.until 0
		inc edx
		.if edx>_line
			sub esi,_lpStr
			mov eax,esi
			ret
		.endif
	.until !word ptr [esi]
_NoPage:
	xor eax,eax
	ret
_CheckPage endp

_WndProc proc hwnd,uMsg,wParam,lParm
	LOCAL @str[64]:byte
	LOCAL @str2[64]:byte
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if ax==IDC_OK
			invoke IsDlgButtonChecked,hwnd,IDC_CHK1
			.if eax==BST_CHECKED
				mov bIsSilent,1
			.else
				mov bIsSilent,0
			.endif
			jmp @F
		.endif
	.elseif eax==WM_INITDIALOG
		invoke LoadStringW,hInstance,IDS_MORELINE,addr @str2,32
		mov eax,nLine
		inc eax
		lea ecx,@str
		invoke wsprintfW,ecx,addr @str2,eax
		invoke SetDlgItemTextW,hwnd,IDC_TEXTLONG,addr @str
	.elseif eax==WM_CLOSE
	@@:
		invoke EndDialog,hwnd,0
	.endif
	xor eax,eax
	ret
_WndProc endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nSelectTableIndex
	LOCAL @nCharSet,@nTextBufferSize
	invoke _GetStringInList,_lpFI,_nLine
	mov @pNewStr,eax
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov eax,[edi].lpStream
	mov ecx,[eax+_GscHeader.nTextSize]
	shl ecx,1
	mov @nTextBufferSize,ecx
	mov eax,[edi].nCharSet
	mov ecx,[edi].lpStreamIndex
	mov @nCharSet,eax
	mov edx,_nLine
	lea eax,[edx+edx*2]
	lea esi,[ecx+eax*4]
	mov eax,_StreamEntry.lpStart[esi]
	mov @nSelectTableIndex,0
	sub esi,sizeof _StreamEntry
	.if esi>=ecx && eax==dword ptr [esi]
		inc @nSelectTableIndex
		.while esi>ecx
			sub esi,sizeof _StreamEntry
			.break .if eax!=_StreamEntry.lpStart[esi]
			inc @nSelectTableIndex
		.endw
	.endif
	mov ebx,[edi].Reserved
	assume ebx:ptr _GscInfo
	mov ecx,[ebx].lpIndexCS
	mov esi,[ecx+eax*4]
	add esi,[ebx].lpControlStream
	assume edi:nothing
	lodsw
	.if ax==51h
		add esi,14h
		mov ecx,_lpFI
		mov ecx,[ecx+_FileInfo.lpStreamIndex]
		mov edx,_nLine
		lea eax,[edx+edx*2]
		lea eax,[ecx+eax*4]
		mov ecx,_StreamEntry.lpStart[eax]
		.if ecx==_StreamEntry.lpStart[eax+sizeof _StreamEntry]
			sub esi,4
		.endif
		invoke _CheckPage,@pNewStr,3,42
		.if eax && !bIsSilent
;			mov eax,_nLine
;			mov nLine,eax
;			invoke DialogBoxParamW,hInstance,IDD_DLG1,hWinMain,_WndProc,0
		.endif
_i51ML:
		invoke _GetTextByIdx,[esi],ebx
		mov edi,eax
		invoke lstrlenA,eax
		inc eax
		invoke WideCharToMultiByte,@nCharSet,0,@pNewStr,-1,edi,eax,0,0
		.if !eax
			invoke GetLastError
			.if eax==ERROR_INSUFFICIENT_BUFFER
				mov ecx,[ebx].sHeader.nTextSize
				mov edx,ecx
				mov eax,@nTextBufferSize
				add ecx,[ebx].lpText
				sub eax,edx
				invoke WideCharToMultiByte,@nCharSet,0,@pNewStr,-1,ecx,eax,0,0
				.if !eax
					mov eax,E_NOTENOUGHBUFF
					jmp _ExML
				.endif
				mov edx,[ebx].sHeader.nTextSize
				add [ebx].sHeader.nTextSize,eax
				mov ecx,[ebx].lpIndex
				mov eax,[esi]
				mov [ecx+eax*4],edx
			.endif
		.endif
		
	.elseif ax==52h
		add esi,10h
		invoke _CheckPage,@pNewStr,2,42
		.if eax && !bIsSilent
;			mov eax,_nLine
;			mov nLine,eax
;			invoke DialogBoxParamW,hInstance,IDD_DLG1,hWinMain,_WndProc,0
		.endif
		invoke _GetTextByIdx,[esi],ebx
		mov edi,eax
		invoke lstrlenA,eax
		inc eax
		invoke WideCharToMultiByte,@nCharSet,0,@pNewStr,-1,edi,eax,0,0
		.if !eax
			invoke GetLastError
			.if eax==ERROR_INSUFFICIENT_BUFFER
				mov ecx,[ebx].sHeader.nTextSize
				mov edx,ecx
				mov eax,@nTextBufferSize
				add ecx,[ebx].lpText
				sub eax,edx
				invoke WideCharToMultiByte,@nCharSet,0,@pNewStr,-1,ecx,eax,0,0
				.if !eax
					mov eax,E_NOTENOUGHBUFF
					jmp _ExML
				.endif
				mov edx,[ebx].sHeader.nTextSize
				add [ebx].sHeader.nTextSize,eax
				mov ecx,[ebx].lpIndex
				mov eax,[esi]
				mov [ecx+eax*4],edx
			.endif
		.endif
	.elseif ax==0eh
		xor eax,eax
		lodsw
		mov ecx,@nSelectTableIndex
		.if ecx>eax
			mov eax,E_PLUGINERROR
			jmp _ExML
		.endif
		or ecx,ecx
		je _i51ML
		dec ecx
		lea esi,[esi+ecx*4+18h]
		jmp _i51ML
	.else
		mov eax,E_PLUGINERROR
		jmp _ExML
	.endif
	assume ebx:nothing
	xor eax,eax
_ExML:
	ret
ModifyLine endp

;
SaveText proc uses edi ebx esi _lpFI
	LOCAL @hFile
	LOCAL @lpfnBak
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke lstrlenW,edi
	add eax,5
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	mov @lpfnBak,eax
	.if eax
		invoke lstrcpyW,eax,edi
		invoke lstrcatW,@lpfnBak,$CTW0(".bak")
		invoke CopyFileW,edi,@lpfnBak,FALSE
	.endif
	
	mov esi,[edi].Reserved
	assume esi:ptr _GscInfo
	mov eax,[esi].sHeader.nHeaderSize
	add eax,[esi].sHeader.nControlStreamSize
	add eax,[esi].sHeader.nIndexSize
	add eax,[esi].sHeader.nTextSize
	
	mov ebx,[esi].sHeader.nExtra
	mov ecx,[esi].sHeader.nExtra[4]
	shl ecx,1
	add ebx,ecx
	.if [esi].sHeader.nHeaderSize==24h
		mov ecx,[esi].sHeader.nExtra[8]
		shl ecx,1
		add ebx,ecx
		add ebx,[esi].sHeader.nExtra[12]
	.endif
	add eax,ebx
	mov [esi].sHeader.nFileSize,eax
	mov ecx,[edi].hFile
	mov @hFile,ecx
	assume edi:nothing
	mov edi,1
	invoke SetFilePointer,@hFile,0,0,FILE_BEGIN
	invoke WriteFile,@hFile,esi,[esi].sHeader.nHeaderSize,offset dwTemp,0
	and edi,eax
	invoke WriteFile,@hFile,[esi].lpControlStream,[esi].sHeader.nControlStreamSize,offset dwTemp,0
	and edi,eax
	invoke WriteFile,@hFile,[esi].lpIndex,[esi].sHeader.nIndexSize,offset dwTemp,0
	and edi,eax
	invoke WriteFile,@hFile,[esi].lpText,[esi].sHeader.nTextSize,offset dwTemp,0
	and edi,eax
	invoke WriteFile,@hFile,[esi].lpExtraData,ebx,offset dwTemp,0
	and edi,eax
	invoke SetEndOfFile,@hFile
	
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
	
	xor eax,eax
	ret
SaveText endp

SetLine proc _lpsz,_lpRange
	cmp _lpRange,0
	je _ExSL
	mov eax,_lpsz
	.if dword ptr [eax]==67005eh
		mov ecx,_lpRange
		mov dword ptr [ecx],5
		mov dword ptr [ecx+4],-1
	.endif
	invoke _SetLine,_lpsz,_lpRange
_ExSL:
	ret
SetLine endp

Release proc uses esi edi ebx _lpFI
	mov eax,_lpFI
	mov edi,[eax+_FileInfo.Reserved]
	.if !edi
		ret
	.endif
	mov esi,edi
	add esi,_GscInfo.lpControlStream
	mov ebx,6
	.while ebx
		lodsd
		.if eax
			invoke VirtualFree,eax,0,MEM_RELEASE
		.endif
		dec ebx
	.endw
	invoke HeapFree,hHeap,0,edi
	mov eax,_lpFI
	mov dword ptr [eax+_FileInfo.Reserved],0
	mov eax,1
	ret
Release endp

;
_MakeFromStream proc uses esi edi _nSize,_lppStream
	mov eax,_nSize
	shl eax,1
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _ErrMFS
	push eax
	mov edi,eax
	mov edx,_lppStream
	mov esi,[edx]
	mov ecx,_nSize
	mov eax,ecx
	shr ecx,2
	REP MOVSd
	mov ecx,eax
	and ecx,3
	REP MOVSb
	mov [edx],esi
	pop eax
	ret
_ErrMFS:
	xor eax,eax
	ret
_MakeFromStream endp

_ReleaseHeap proc uses esi ebx _lpFI
	mov eax,_lpFI
	mov esi,[eax+_FileInfo.lpTextIndex]
	mov ebx,[eax+_FileInfo.nLine]
	.while ebx
		lodsd
		.break .if !eax
		invoke HeapFree,hHeap,0,eax
		dec ebx
	.endw
	ret
_ReleaseHeap endp

;
_GetTextByIdx proc _idx,_lpGscInfo
	mov edx,_lpGscInfo
	mov ecx,[edx+_GscInfo.lpIndex]
	mov eax,_idx
	mov eax,[ecx+eax*4]
	mov ecx,[edx+_GscInfo.lpText]
	add eax,ecx
	ret
_GetTextByIdx endp

_AddString proc _lpStr,_lppTIdx,_nCharSet
	LOCAL @pStr,@nLen
	invoke lstrlenA,_lpStr
	inc eax
	mov @nLen,eax
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _NomemAS
	mov @pStr,eax
	mov ecx,_lppTIdx
	mov edx,[ecx]
	mov [edx],eax
	add dword ptr [ecx],4
	invoke MultiByteToWideChar,_nCharSet,0,_lpStr,-1,@pStr,@nLen
	mov eax,1
	ret
_NomemAS:
	xor eax,eax
	ret
_AddString endp

;
_CorrectRTCS proc uses edi esi _lpGscInfo,_idx,_nBytes,_Flags
	mov ecx,_lpGscInfo
	mov edi,[ecx+_GscInfo.lpIndexCS]
	mov esi,[ecx+_GscInfo.lpRelocTable]
	.if _Flags==CT_ADD
		xor ecx,ecx
		.repeat
			add edi,4
			inc ecx
		.until !dword ptr [edi]
		.while ecx>_idx
			mov eax,[edi-4]
			mov [edi],eax
			sub edi,4
			dec ecx
		.endw
		add edi,4
		mov eax,_nBytes
		.while dword ptr [edi]
			add dword ptr [edi],eax
			add edi,4
		.endw
		
		mov ecx,_lpGscInfo
		mov edi,[ecx+_GscInfo.lpIndexCS]
		mov eax,_idx
		mov edx,[edi+eax*4]
		mov ecx,_nBytes
		.while dword ptr [esi]
			.if dword ptr [esi]>=edx
				add dword ptr [esi],ecx
			.endif
			add esi,4
		.endw
	.else
		mov eax,_idx
		lea edi,[edi+eax*4]
		.while dword ptr [edi]
			mov eax,[edi+4]
			mov [edi],eax
			add edi,4
		.endw
		mov ecx,_lpGscInfo
		mov edi,[ecx+_GscInfo.lpIndexCS]
		mov eax,_idx
		lea edi,[edi+eax*4]
		mov eax,_nBytes
		.while dword ptr [edi]
			sub dword ptr [edi],eax
			add edi,4
		.endw
		
		mov ecx,_lpGscInfo
		mov edi,[ecx+_GscInfo.lpIndexCS]
		mov eax,_idx
		mov edx,[edi+eax*4]
		mov ecx,_nBytes
		.while dword ptr [esi]
			.if dword ptr [esi]>=edx
				sub dword ptr [esi],ecx
			.endif
			add esi,4
		.endw
		
	.endif
	invoke _Relocate,_lpGscInfo,_idx,_nBytes,_Flags
	ret
_CorrectRTCS endp
;
_Relocate proc uses edi esi _lpGscInfo,_idx,_nBytes,_Flags
	mov ecx,_lpGscInfo
	mov edi,[ecx+_GscInfo.lpIndexCS]
	mov eax,_idx
	mov edx,[edi+eax*4]
	mov esi,[ecx+_GscInfo.lpRelocTable]
	lodsd
	mov edi,[ecx+_GscInfo.lpControlStream]
	.if _Flags==CT_ADD
		.while eax
			mov ecx,[edi+eax]
			.if ecx>edx
				add ecx,_nBytes
				mov [edi+eax],ecx
			.endif
			lodsd
		.endw
	.else
		.while eax
			mov ecx,[edi+eax]
			.if ecx>edx
				sub ecx,_nBytes
				mov [edi+eax],ecx
			.endif
			lodsd
		.endw
	.endif
	ret
_Relocate endp

;
_memcpy proc
	mov eax,ecx
	shr ecx,2
	REP MOVSd
	mov ecx,eax
	and ecx,3
	REP MOVSb
	ret
_memcpy endp


end DllMain