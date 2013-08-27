.386
.model flat,stdcall
option casemap:none

include yukapsp.inc

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
Match proc _lpszName
	LOCAL @hFile,@dwTemp
	LOCAL @buff[8]:byte
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _ErrMatch
	mov @hFile,eax
	invoke ReadFile,@hFile,addr @buff,8,addr @dwTemp,0
	or eax,eax
	je _ErrMatch
	invoke CloseHandle,@hFile
	lea eax,@buff
	.if dword ptr [eax]==736b79h && dword ptr [eax+4]==302e31h
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
	mov hGlobalHeap,eax
	assume ecx:nothing
	ret
PreProc endp

;
GetText proc uses edi ebx esi _lpFI,_lpRI
	LOCAL @ddn,@pEnd,@bFirstCreate
	LOCAL @pStreamList,@pTextList,@pStrInList
	LOCAL @nLine
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,sizeof YukaStruct
	or eax,eax
	je _NoMemGT
	mov [edi].lpCustom,eax
	mov ebx,eax
	assume ebx:ptr YukaStruct
	mov esi,[edi].lpStream
	assume esi:ptr YukaHeader
	mov eax,[esi].PrgCount
	shl eax,2
	mov [ebx].nPrgLen,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	or eax,eax
	je _GotorelGT
	mov [ebx].lpPrg,eax
	
	mov eax,[esi].CmdCount
	shl eax,4
	mov [ebx].nCmdLen,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	.if !eax
_GotorelGT:
		invoke Release,_lpFI
		jmp _NoMemGT
	.endif
	mov [ebx].lpCmd,eax
	
	mov eax,[esi].ResSize
	mov [ebx].nResLen,eax
	shl eax,1
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	or eax,eax
	je _GotorelGT
	mov [ebx].lpRes,eax
	
	mov eax,[esi].UnkCount
	shl eax,1
	mov [ebx].nUnkLen,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	test eax,eax
	jz _GotorelGT
	mov [ebx].lpUnk,eax
	
	mov eax,[esi].UnkVals[0]
	mov ecx,[esi].UnkVals[4]
	mov edx,[esi].UnkVals[8]
	mov [ebx].nUnkVals[0],eax
	mov [ebx].nUnkVals[4],ecx
	mov [ebx].nUnkVals[8],edx
	
	mov eax,[ebx].nPrgLen
	lea eax,[eax+eax*2]
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _GotorelGT
	mov [edi].lpStreamIndex,eax
	mov @pStreamList,eax
	invoke VirtualAlloc,0,[ebx].nPrgLen,MEM_COMMIT,PAGE_READWRITE
	or eax,eax
	je _GotorelGT
	mov [edi].lpTextIndex,eax
	mov @pTextList,eax
;	invoke VirtualAlloc,0,[ebx+14h],MEM_COMMIT,PAGE_READWRITE
;	or eax,eax
;	je _GotorelGT
;	mov [edi].lpText,eax
;	mov @pStrInList,eax

	mov @ddn,0
	mov edx,edi
	.while @ddn<4
		mov edi,edx
		mov esi,[edi].lpStream
		mov eax,@ddn
		add esi,dword ptr [esi+eax*8+14h]
		mov edi,dword ptr [ebx+eax*8]
		mov ecx,dword ptr [ebx+eax*8+4]
		invoke _memcpy
		inc @ddn
	.endw
	mov edi,edx
	
	assume edi:nothing
	assume esi:nothing
	
	mov @nLine,0
	mov esi,[ebx].lpPrg
	mov eax,esi
	add eax,dword ptr [ebx].nPrgLen
	mov @pEnd,eax
	.while esi<@pEnd
		lodsd
		mov ecx,eax
		lodsd
		shl ecx,4
		mov edi,[ebx].lpCmd
		add edi,ecx
		.if word ptr [edi]
			sub esi,4
			.continue
		.endif
		.if eax>=10h
			int 3
		.endif
		mov ecx,[edi+4]
		mov edi,[ebx].lpRes
		add edi,ecx
		push eax
		invoke _CmpStrOut,edi
		.if eax==-1
			pop eax
			lea esi,[esi+eax*4]
			.continue
		.elseif !eax
			int 3
		.elseif eax==2
			add esi,4
		.endif
		pop eax
_GetStringGT:
		mov edi,[ebx].lpCmd
		lodsd
		shl eax,4
		add edi,eax
		.if word ptr [edi]!=5
			int 3
		.endif
		mov eax,@pStreamList
		mov _StreamEntry.lpStart[eax],edi
		add @pStreamList,sizeof _StreamEntry
		mov ecx,[edi+8]
		mov edi,[ebx].lpRes
		add edi,ecx
		invoke lstrlenA,edi
		inc eax
		push eax
		shl eax,1
		invoke HeapAlloc,hGlobalHeap,0,eax
		pop edx
		test eax,eax
		jz _NoMemGT
		mov ecx,@pTextList
		mov [ecx],eax
		add @pTextList,4
		mov ecx,_lpFI
		invoke MultiByteToWideChar,_FileInfo.nCharSet[ecx],0,edi,-1,eax,edx
		.if !eax
			jmp _NoMemGT ;不准确
		.endif
		inc @nLine
	.endw
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	assume ebx:nothing
	mov eax,@nLine
	mov [edi].nLine,eax
	
	mov [edi].nMemoryType,MT_EVERYSTRING
	assume edi:nothing
	mov eax,_lpRI
	mov dword ptr [eax],RI_SUC_LINEONLY
	
	xor eax,eax
	ret
_NoMemGT:
	mov eax,E_NOMEM
	ret
GetText endp

;
ModifyLine proc uses ebx edi esi _lpFI,_nLine
	LOCAL @pStr,@pToNewStr,@nNewLen,@bNeedExpand
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	mov ebx,[edi].lpCustom
	or ebx,ebx
	je _ErrML
	assume ebx:ptr YukaStruct
	invoke _GetStringInList,_lpFI,_nLine
	mov @pStr,eax
	mov eax,[edi].lpStreamIndex
	mov ecx,_nLine
	lea ecx,[ecx+ecx*2]
	mov esi,_StreamEntry.lpStart[eax+ecx*4]
	cmp word ptr [esi],5
	jne _ErrML
	mov eax,[ebx].lpRes
	add eax,dword ptr [ebx].nResLen
	mov @pToNewStr,eax
	invoke WideCharToMultiByte,[edi].nCharSet,0,@pStr,-1,eax,0,0,0
	mov @nNewLen,eax
	mov eax,[esi+8]
	add eax,dword ptr [ebx].lpRes
	invoke lstrlenA,eax
	
	;填充为0
	xor ecx,ecx
	mov edx,[esi+8]
	add edx,[ebx].lpRes
	.while ecx<eax
		mov byte ptr [edx+ecx],20h
		inc ecx
	.endw
	
	inc eax
	.if eax<@nNewLen
		mov ecx,[edi].lpStream
		mov ecx,YukaHeader.ResSize[ecx]
		shl ecx,1
		sub ecx,dword ptr [ebx].nResLen
		mov @bNeedExpand,TRUE
	.else
		mov ecx,[esi+8]
		add ecx,dword ptr [ebx].lpRes
		mov @pToNewStr,ecx
		mov ecx,eax
		mov @bNeedExpand,FALSE
	.endif
	invoke WideCharToMultiByte,[edi].nCharSet,0,@pStr,-1,@pToNewStr,ecx,0,0
	or eax,eax
	je _ErrML
	.if @bNeedExpand
		add [ebx].nResLen,eax
		add [edi].nStreamSize,eax
		mov ecx,@pToNewStr
		sub ecx,[ebx].lpRes
		mov [esi+8],ecx
	.endif
	assume edi:nothing
	assume ebx:nothing
	xor eax,eax
	ret
_ErrML:
	or eax,-1
	ret
ModifyLine endp

;
SaveText proc uses edi ebx esi _lpFI
	LOCAL @dbHdr:YukaHeader,@dwTemp
	LOCAL @nCur
	mov edi,_lpFI
	assume edi:ptr _FileInfo
	cmp [edi].bReadOnly,1
	je _ErrST
	lea esi,szHeader
	mov edx,edi
	lea edi,@dbHdr
	mov ecx,14h
	invoke _memcpy
	mov edi,edx
	mov ebx,[edi].lpCustom
	assume ebx:ptr YukaStruct
	mov esi,sizeof(YukaHeader)
	mov @dbHdr.PrgOff,esi
	mov eax,[ebx].nPrgLen
	add esi,eax
	shr eax,2
	mov @dbHdr.PrgCount,eax
	mov @dbHdr.CmdOff,esi
	mov eax,[ebx].nCmdLen
	add esi,eax
	shr eax,4
	mov @dbHdr.CmdCount,eax
	mov @dbHdr.ResOff,esi
	mov eax,[ebx].nResLen
	add esi,eax
	mov @dbHdr.ResSize,eax
	mov @dbHdr.UnkOff,esi
	mov eax,[ebx].nUnkLen
	shr eax,1
	mov @dbHdr.UnkCount,eax
	mov eax,[ebx].nUnkVals[0]
	mov ecx,[ebx].nUnkVals[4]
	mov edx,[ebx].nUnkVals[8]
	mov @dbHdr.UnkVals[0],eax
	mov @dbHdr.UnkVals[4],ecx
	mov @dbHdr.UnkVals[8],edx
	
	invoke SetFilePointer,[edi].hFile,0,0,FILE_BEGIN
	invoke WriteFile,[edi].hFile,addr @dbHdr,sizeof @dbHdr,addr @dwTemp,0
	mov esi,eax
	invoke WriteFile,[edi].hFile,[ebx].lpPrg,[ebx].nPrgLen,addr @dwTemp,0
	and esi,eax
	invoke WriteFile,[edi].hFile,[ebx].lpCmd,[ebx].nCmdLen,addr @dwTemp,0
	and esi,eax
	invoke WriteFile,[edi].hFile,[ebx].lpRes,[ebx].nResLen,addr @dwTemp,0
	and esi,eax
	invoke WriteFile,[edi].hFile,[ebx].lpUnk,[ebx].nUnkLen,addr @dwTemp,0
	and eax,esi
	je _ErrST
	invoke SetEndOfFile,[edi].hFile
	assume edi:nothing
	assume ebx:nothing
	xor eax,eax
	ret
_ErrST:
	or eax,-1
	ret
SaveText endp

SetLine proc _para1,_para2
	invoke _SetLine,_para1,_para2
	ret
SetLine endp

;
Release proc uses ebx _lpFI
	mov eax,_lpFI
	assume eax:ptr _FileInfo
	mov ebx,[eax].lpCustom
	mov [eax].lpCustom,0
	assume eax:nothing
	.if ebx
		mov ecx,4
		@@:
		mov eax,[ebx]
		.if eax
			push ecx
			invoke HeapFree,hGlobalHeap,0,eax
			pop ecx
		.endif
		add ebx,8
		loop @B
		invoke HeapFree,hGlobalHeap,0,ebx 
	.endif
	ret
Release endp

_memcpy proc
	mov eax,ecx
	shr ecx,2
	REP MOVSd
	mov ecx,eax
	and ecx,3
	REP MOVSb
	ret
_memcpy endp

_IsEncode proc uses esi ebx _pTB
	mov ebx,_pTB
	mov esi,[ebx+8h]
	mov ecx,[ebx+0ch]
	@@:
	.if !dword ptr [esi]
		mov ecx,[esi+4]
		add ecx,[ebx+10h]
		xor eax,eax
		mov al,[ecx]
		shr al,7
		ret
	.endif
	add esi,10h
	loop @B
	xor eax,eax
	ret
_IsEncode endp

_Encode proc uses edi _lpBuf,_nSize
	mov edi,_lpBuf
	mov ecx,_nSize
	@@:
	xor byte ptr [edi],0aah
	inc edi
	loop @B
	ret
_Encode endp

_CmpStrOut proc uses esi edi _lpsz
	
	invoke lstrcmp,_lpsz,offset szStrOut
	.if !eax
		mov eax,1
		ret
	.endif
	invoke lstrcmp,_lpsz,offset szStrOutNWC
	.if !eax
		mov eax,2
		ret
	.endif
	mov edi,_lpsz
	mov esi,offset szStrOut
	mov ecx,7
	repe cmpsb
	.if ecx
		or eax,-1
		ret
	.endif
	mov eax,ecx
	ret
_CmpStrOut endp


end DllMain