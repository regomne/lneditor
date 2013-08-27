.386
.model flat,stdcall
option casemap:none

include N2System.inc

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

;
Match proc uses esi _lpszName
	LOCAL @szMagic[5]:dword
	LOCAL @sExtend[2]:dword
	LOCAL @nLen
	LOCAL @hHeap
	invoke lstrlenW,_lpszName
	mov @nLen,eax
	mov ecx,_lpszName
	lea ecx,[ecx+eax*2-8]
	lea edx,@sExtend
	mov eax,[ecx]
	mov [edx],eax
	mov eax,[ecx+4]
	mov [edx+4],eax
	and dword ptr [edx],0ffdfffffh
	and dword ptr [edx+4],0ffdfffdfh
	.if dword ptr [edx]==4e002eh && dword ptr [edx+4]==0420053h
		invoke GetProcessHeap
		mov @hHeap,eax
		mov eax,@nLen
		inc eax
		shl eax,1
		invoke HeapAlloc,@hHeap,0,eax
		or eax,eax
		je _ErrMatch
		mov esi,eax
		invoke lstrcpyW,esi,_lpszName
		mov eax,@nLen
		lea ecx,[esi+eax*2-8]
		mov dword ptr [ecx],6d002eh
		mov dword ptr [ecx+4],700061h
		invoke CreateFileW,esi,0,FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		.if eax==-1
			invoke HeapFree,@hHeap,0,esi
			jmp _NotMatch
		.endif
		invoke CloseHandle,eax
		
		.if lpMapFile
			invoke HeapFree,@hHeap,0,lpMapFile
		.endif
		.if word ptr [esi+2]==':' || dword ptr [esi]==5c005ch
			mov lpMapFile,esi
		.else
			invoke GetFullPathNameW,esi,0,0,0
			mov @nLen,eax
			shl eax,1
			invoke HeapAlloc,@hHeap,0,eax
			.if !eax
				invoke HeapFree,@hHeap,0,esi
				jmp _ErrMatch
			.endif
			mov lpMapFile,eax
			invoke GetFullPathNameW,esi,@nLen,lpMapFile,0
			invoke HeapFree,@hHeap,0,esi
		.endif
		
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
N2GetLine proc uses esi edi _lpStr,_nCS,_nCode
	LOCAL @nLen,@nChar
	LOCAL @pStr,@pStr2
	mov esi,_lpStr
	lodsd
	mov @nLen,eax
	add eax,7
	shl eax,2
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Ex
	mov @pStr2,eax
	mov edi,eax
;	invoke wsprintf,eax,$CTA0("%02X: "),_nCode
;	mov ecx,@pStr2
;	lea edi,[ecx+eax]
	mov ecx,@nLen
	mov @nChar,0
;	mov @nChar,eax
	xor edx,edx
	.if !ecx
		mov @pStr,0
		jmp _Ex2
	.endif
	@@:
		lodsb
		.if al>80h && ecx
			stosb
			movsb
			dec ecx
			inc @nChar
			mov edx,1
		.elseif al==0ah
			.if byte ptr [esi]==0ah && ecx
				inc esi
				dec ecx
				mov ax,705ch
			.else
				mov ax,6e5ch
			.endif
			stosw
			add @nChar,2
		.else
			stosb
			inc @nChar
		.endif
	loop @B
	mov byte ptr [edi],0
	.if !edx
		mov @pStr,0
		jmp _Ex2
	.endif
	
	inc @nChar
	mov ecx,@nChar
	shl ecx,1
	invoke HeapAlloc,hHeap,0,ecx
	.if !eax
		invoke HeapFree,hHeap,0,@pStr2
		xor eax,eax
		jmp _Ex
	.endif
	mov @pStr,eax
	mov word ptr [eax],0

	invoke MultiByteToWideChar,_nCS,0,@pStr2,-1,@pStr,@nChar
_Ex2:
	invoke HeapFree,hHeap,0,@pStr2
	mov eax,@pStr
_Ex:
	ret
N2GetLine endp

;
N2OpenMapFile proc uses esi ebx _lpszName,_lpN2I
	LOCAL @nFileSize[2]
	invoke lstrlenW,_lpszName
	mov ebx,eax
	inc eax
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	.if !eax
		mov eax,E_NOMEM
		jmp _Ex
	.endif
	mov esi,eax
	invoke lstrcpyW,esi,_lpszName
	lea ecx,[esi+ebx*2-8]
	mov dword ptr [ecx],6d002eh
	mov dword ptr [ecx+4],700061h
	invoke CreateFileW,esi,GENERIC_READ OR GENERIC_WRITE,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax==-1
		.if lpMapFile
			invoke N2DirFileNameW,lpMapFile
			or eax,eax
			je @F
			mov ebx,eax
			invoke N2DirFileNameW,esi
			or eax,eax
			je @F
			invoke lstrcmpiW,eax,ebx
			or eax,eax
			jne @F
			invoke CreateFileW,lpMapFile,GENERIC_READ OR GENERIC_WRITE,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
			cmp eax,-1
			jne _SucOpenMap
		.endif
		@@:
		invoke HeapFree,hHeap,0,esi
		invoke _OutputMessage,WLT_CUSTOM,offset szInnerName,offset szNoMapFile,0
		mov eax,E_ERROR
		jmp _Ex
	.endif
_SucOpenMap:
	mov ebx,eax
	invoke HeapFree,hHeap,0,esi
	
	mov esi,_lpN2I
	assume esi:ptr N2Index
	mov [esi].hMap,ebx
	
	invoke GetFileSizeEx,[esi].hMap,addr @nFileSize
	.if !eax
		mov eax,E_ERROR
		jmp _Ex
	.endif
	invoke HeapAlloc,hHeap,0,dword ptr @nFileSize
;	invoke VirtualAlloc,0,dword ptr @nFileSize,MEM_COMMIT,PAGE_READWRITE
	.if !eax
		mov eax,E_NOMEM
		jmp _Ex
	.endif
	mov [esi].lpMapStream,eax
	invoke ReadFile,[esi].hMap,[esi].lpMapStream,dword ptr @nFileSize,offset dwTemp,0
	mov ecx,dwTemp
	mov [esi].nStreamSize,ecx
	
	assume esi:nothing
	xor eax,eax
_Ex:
	ret
N2OpenMapFile endp

;
N2MakeIndexTable proc uses esi edi ebx _lpN2I
	LOCAL @pEnd
	mov edi,_lpN2I
	assume edi:ptr N2Index
	mov esi,[edi].lpMapStream
	mov eax,esi
	add eax,[edi].nStreamSize
	mov @pEnd,eax
	
	xor ebx,ebx
	.while esi<@pEnd
		add esi,4
		xor eax,eax
		lodsw
		add esi,eax
		inc ebx
	.endw
	
	mov [edi].nIndex,ebx
	shl ebx,2
	invoke HeapAlloc,hHeap,0,ebx
;	invoke VirtualAlloc,0,ebx,MEM_COMMIT,PAGE_READWRITE
	.if !eax
		mov eax,E_NOMEM
		jmp _Ex
	.endif
	mov [edi].lpIndex,eax
	
	mov esi,[edi].lpMapStream
	xor ebx,ebx
	mov edx,[edi].lpIndex
	.while ebx<[edi].nIndex
		mov [edx+ebx*4],esi
		add esi,4
		xor eax,eax
		lodsw
		add esi,eax
		inc ebx
	.endw
	
	assume edi:nothing
	xor eax,eax
_Ex:
	ret
N2MakeIndexTable endp

;
GetText proc uses esi ebx edi _lpFI,_lpRI
	LOCAL @pEnd
	LOCAL @nLine,@nCode
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	
	invoke HeapAlloc,hHeap,HEAP_ZERO_MEMORY,sizeof N2Index
	or eax,eax
	je _Nomem
	mov [edi].lpCustom,eax

	.if ![edi].bReadOnly
		invoke N2OpenMapFile,[edi].lpszName,[edi].lpCustom
		.if !eax
			invoke N2MakeIndexTable,[edi].lpCustom
			mov ecx,[edi].lpCustom
			.if !eax
				mov N2Index.bWritable[ecx],TRUE
			.endif
		.endif
	.endif
	
	mov esi,[edi].lpStream
	mov eax,esi
	add eax,[edi].nStreamSize
	mov @pEnd,eax
	xor ebx,ebx
	.while esi<@pEnd
		.if word ptr [esi+4]==0d8h && word ptr [esi+6]==3
			inc ebx
		.endif
		movzx ecx,word ptr [esi+6]
;		add ebx,ecx
		add esi,8
		.while ecx
			lodsd
			add esi,eax
			dec ecx
		.endw
	.endw
	mov @nLine,ebx
	
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
	
	mov esi,[edi].lpStream
	mov @nLine,0
	xor ebx,ebx
	.while esi<@pEnd
		.if word ptr [esi+4]==0d8h && word ptr [esi+6]==3
			add esi,8
			lodsd
			add esi,eax
			lodsd
			add esi,eax
			invoke N2GetLine,esi,[edi].nCharSet,0
			or eax,eax
			je @F
			mov ecx,[edi].lpTextIndex
			mov [ecx+ebx*4],eax
			mov ecx,[edi].lpStreamIndex
			lea eax,[ebx+ebx*2]
			mov _StreamEntry.lpStart[ecx+eax*4],esi
			inc ebx
			@@:
			lodsd
			add esi,eax
		.else
			movzx ecx,word ptr [esi+6]
			add esi,8
			.while ecx
				lodsd
				add esi,eax
				dec ecx
			.endw
		.endif
;		movzx ebx,word ptr [esi+6]
;		movzx eax,word ptr [esi+4]
;		mov @nCode,eax
;		add esi,8
;		.while ebx
;			invoke N2GetLine,esi,[edi].nCharSet,@nCode
;			or eax,eax
;			je @F
;			mov ecx,[edi].lpTextIndex
;			mov edx,@nLine
;			mov [ecx+edx*4],eax
;			mov ecx,[edi].lpStreamIndex
;			mov [ecx+edx*4],esi
;			inc @nLine
;			@@:
;			lodsd
;			add esi,eax
;			dec ebx
;		.endw
	.endw
	
	mov [edi].nMemoryType,MT_EVERYSTRING
;	mov eax,@nLine
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
N2SetLine proc uses esi edi _lpStr,_nCS
	LOCAL @nChar,@pStr2,@pStr
	invoke lstrlenW,_lpStr
	mov @nChar,eax
	inc eax
	shl eax,1
	invoke HeapAlloc,hHeap,0,eax
	or eax,eax
	je _Err
	mov @pStr2,eax
	mov esi,_lpStr
	mov edi,eax
	mov ecx,@nChar
	@@:
		lodsw
		.if ax=='\'
			.if word ptr [esi]=='n'
				add esi,2
				mov ax,0ah
				stosw
				dec ecx
				loop @B
			.elseif word ptr [esi]=='p'
				add esi,2
				mov eax,0a000ah
				stosd
				dec ecx
				loop @B
			.endif
		.endif
		stosw
	loop @B
	mov word ptr [edi],0
	sub edi,@pStr2
	inc edi
	invoke HeapAlloc,hHeap,0,edi
	.if !eax
		invoke HeapFree,hHeap,0,@pStr2
		jmp _Err
	.endif
	mov @pStr,eax
	mov word ptr [eax],55h
	invoke WideCharToMultiByte,_nCS,0,@pStr2,-1,@pStr,edi,0,0
;	.if !eax
;		invoke HeapFree,hHeap,0,@pStr2
;		invoke HeapFree,hHeap,0,@pStr
;		jmp _Err
;	.endif
	invoke HeapFree,hHeap,0,@pStr2
	mov eax,@pStr
	ret
_Err:
	xor eax,eax
	ret
N2SetLine endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pNewStr,@nNewLen,@nOldLen
	mov edi,_lpFI
	assume edi:ptr _FileInfo 
	
	mov ecx,[edi].lpCustom
	.if !N2Index.bWritable[ecx]
		mov eax,E_LINEDENIED
		jmp _Ex
	.endif
	
	invoke _GetStringInList,edi,_nLine
	mov ebx,eax
	invoke N2SetLine,ebx,[edi].nCharSet
	.if !eax
		mov eax,E_LINEDENIED
		jmp _Ex
	.endif
	mov @pNewStr,eax
	invoke lstrlenA,eax
	mov @nNewLen,eax
	
	mov ecx,[edi].lpStreamIndex
	mov eax,_nLine
	lea eax,[eax+eax*2]
	mov esi,_StreamEntry.lpStart[ecx+eax*4]
	lodsd
	
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
		
		mov eax,@nNewLen
		mov [esi-4],eax
		
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
		
		lea edx,[esi-4]
		sub edx,[edi].lpStream
		mov esi,[edi].lpCustom
		assume esi:ptr N2Index
		mov ecx,[esi].nIndex
		mov esi,[esi].lpIndex
		assume esi:nothing
		@@:
			lodsd
			.if dword ptr [eax]>edx
				add dword ptr [eax],ebx
			.endif
		loop @B
		
	.endif
	
	assume edi:nothing
_Success:
	invoke HeapFree,hHeap,0,@pNewStr
	xor eax,eax
_Ex:
	ret
ModifyLine endp

;
SaveText proc uses edi _lpFI
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	invoke SetFilePointer,[edi].hFile,0,0,FILE_BEGIN
	invoke WriteFile,[edi].hFile,[edi].lpStream,[edi].nStreamSize,offset dwTemp,0
	invoke SetEndOfFile,[edi].hFile
	
	mov edi,[edi].lpCustom
	assume edi:ptr N2Index
	invoke SetFilePointer,[edi].hMap,0,0,FILE_BEGIN
	invoke WriteFile,[edi].hMap,[edi].lpMapStream,[edi].nStreamSize,offset dwTemp,0
	assume edi:nothing
	xor eax,eax
	ret
SaveText endp

;
SetLine proc
	jmp _SetLine
SetLine endp

Release proc uses ebx _lpFI
	mov ecx,_lpFI
	mov ebx,_FileInfo.lpCustom[ecx]
	assume ebx:ptr N2Index
	.if ebx
		.if [ebx].hMap
			invoke CloseHandle,[ebx].hMap
		.endif
		.if [ebx].lpMapStream
			invoke HeapFree,hHeap,0,[ebx].lpMapStream
;			invoke VirtualFree,[ebx].lpMapStream,0,MEM_RELEASE
		.endif
		.if [ebx].lpIndex
			invoke HeapFree,hHeap,0,[ebx].lpIndex
;			invoke VirtualFree,[ebx].lpIndex,0,MEM_RELEASE
		.endif
		invoke HeapFree,hHeap,0,ebx
		mov ecx,_lpFI
		mov _FileInfo.lpCustom[ecx],0
	.endif
	assume ebx:nothing
	ret
Release endp

;
N2DirFileNameW proc uses edi _lpszPath
	mov edi,_lpszPath
	xor ax,ax
	or ecx,-1
	repne scasw
	sub edi,2
	.if word ptr [edi-2]=='\'
		xor eax,eax
		ret
	.endif
	not ecx
	mov ax,'\'
	std
	repne scasw
	cld
	.if ecx
		lea eax,[edi+4]
		ret
	.endif
	mov eax,_lpszPath
	ret
N2DirFileNameW endp

end DllMain