UPDATE_LIST_VERSION			equ		1

.data
bIsUpdatingProgram		dd		?
TW		'http://lneditor.googlecode.com/',		szGoogleCode
TW0		'svn/trunk/ lneditor/',
TW0		'bin/update.lst',			szUpdateListFile

.code

_UpdateThd proc uses esi edi ebx _lparam
	LOCAL @szUrl[1024]:word
	LOCAL @szFileName[1024]:word
	LOCAL @ppos
	LOCAL @lpList,@nListSize,@nListFile,@lpTempName,@lpNewFileName
	LOCAL @FInfo:_UpdateFileInfo
	LOCAL @ft:FILETIME
	LOCAL @st:SYSTEMTIME,@st2:SYSTEMTIME
	
	invoke GetFileTime,hLogFile,0,0,addr @ft
	invoke FileTimeToSystemTime,addr @ft,addr @st
	invoke GetSystemTime,addr @st2
	mov ax,@st2.wDay
	cmp ax,@st.wDay
	je _ExUT
	mov bIsUpdatingProgram,1
	
	lea ebx,@szUrl
	invoke lstrcpyW,ebx,offset szGoogleCode
	invoke lstrcatW,ebx,offset szUpdateListFile
	invoke URLDownloadToCacheFileW,0,ebx,addr @szFileName,1024,0,0
	.if eax!=S_OK
		invoke _WriteLog,WLT_UPDATEERR,offset szInnerName,offset szWltEUpdate1,offset szNULL
		jmp _ExUT
	.endif
	
	invoke CreateFileW,addr @szFileName,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _ExUT
	mov ebx,eax
	invoke GetFileSize,ebx,0
	mov @nListSize,eax
	invoke HeapAlloc,hGlobalHeap,0,eax
	.if !eax
		invoke CloseHandle,ebx
		jmp _ExUT
	.endif
	mov @lpList,eax
	invoke ReadFile,ebx,@lpList,@nListSize,offset dwTemp,0
	xchg eax,ebx
	invoke CloseHandle,eax
	invoke DeleteFileW,addr @szFileName
	test ebx,ebx
	jz _Ex2UT
	
	mov esi,@lpList
	.if dword ptr [esi]!=UPDATE_LIST_VERSION
		mov eax,IDS_LISTFILEVERSIONTOOLOW
		invoke _GetConstString
		invoke _OutputMessage,WLT_UPDATEERR,offset szInnerName,eax,offset szNULL
		jmp _Ex2UT
	.endif
	mov eax,[esi+4]
	add esi,8
	mov @nListFile,eax
	
	mov eax,lpArgTbl
	mov ebx,[eax]
	invoke lstrlenW,ebx
	lea edi,[ebx+eax*2]
	.while word ptr [edi]!='\'
		.break .if edi<=ebx
		sub edi,2
	.endw
	add edi,2
	sub edi,ebx
	mov @ppos,edi
	
	invoke HeapAlloc,hGlobalHeap,0,1024*2
	test eax,eax
	jz _Ex2UT
	mov @lpTempName,eax
	invoke HeapAlloc,hGlobalHeap,0,1024*2
	test eax,eax
	jz _Ex3UT
	mov @lpNewFileName,eax
	.while @nListFile
		mov @FInfo.lpszName,esi
		invoke lstrlenW,esi
		lea esi,[esi+eax*2+2]
		lea edi,@FInfo.lpszName+4
		mov ecx,sizeof _UpdateFileInfo-4
		rep movsb
		
		mov ecx,lpArgTbl
		lea ebx,@szFileName
		invoke lstrcpyW,ebx,[ecx]
		mov eax,@ppos
		add eax,ebx
		invoke lstrcpyW,eax,@FInfo.lpszName
		invoke CreateFileW,ebx,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		.if eax==-1
			invoke GetLastError
			cmp eax,ERROR_FILE_NOT_FOUND
			je _DownFileUT
			jmp _MakePathUT
		.endif
		push eax
		lea ecx,@ft
		invoke GetFileTime,eax,0,0,ecx
		call CloseHandle
		mov eax,@FInfo.ftMTime.dwLowDateTime
		mov ecx,@FInfo.ftMTime.dwHighDateTime
		cmp ecx,@ft.dwHighDateTime
		jb _NextFileUT
		ja _DownFileUT
		cmp eax,@ft.dwLowDateTime
		jbe _NextFileUT
		ja _DownFileUT
	_MakePathUT:
		invoke _MakePath,addr @szFileName
		.if eax
			invoke CloseHandle,eax
		.endif
	_DownFileUT:
		lea edi,@szUrl
		invoke lstrcpyW,edi,offset szGoogleCode
		invoke lstrcatW,edi,@FInfo.lpszName
		invoke URLDownloadToCacheFileW,0,edi,@lpNewFileName,1024,0,0
		.if eax!=S_OK
			invoke lstrcpyW,edi,offset szGoogleCode
			invoke lstrcatW,edi,$CTW0('bin/')
			invoke lstrcatW,edi,@FInfo.lpszName
			invoke URLDownloadToCacheFileW,0,edi,@lpNewFileName,1024,0,0
			.if eax!=S_OK
				invoke _WriteLog,WLT_UPDATEERR,offset szInnerName,offset szWltEUpdate2,@FInfo.lpszName
				jmp _NextFileUT
			.endif
		.endif
		invoke _CheckFile,@lpNewFileName,addr @FInfo
		.if !eax
			invoke _WriteLog,WLT_UPDATEERR,offset szInnerName,offset szWltEUpdate3,@FInfo.lpszName
			invoke DeleteFileW,@lpNewFileName
			jmp _NextFileUT
		.else
			lea ebx,@szFileName
			invoke lstrcpyW,@lpTempName,ebx
			invoke lstrcatW,@lpTempName,$CTW0('.bak')
			invoke GetFileAttributesW,ebx
			.if eax!=-1
				invoke MoveFileExW,ebx,@lpTempName,MOVEFILE_REPLACE_EXISTING
				.if !eax
					_lbl2:
					invoke DeleteFileW,@lpNewFileName
					invoke _WriteLog,WLT_UPDATEERR,offset szInnerName,offset szWltEUpdate4,@FInfo.lpszName
					jmp _NextFileUT
				.endif
			.endif
			invoke MoveFileExW,@lpNewFileName,ebx,MOVEFILE_REPLACE_EXISTING or MOVEFILE_COPY_ALLOWED
			.if !eax
				invoke MoveFileExW,@lpTempName,ebx,MOVEFILE_REPLACE_EXISTING
				jmp _lbl2
			.endif
			invoke DeleteFileW,@lpTempName
			invoke DeleteFileW,@lpNewFileName
			invoke _WriteLog,WLT_UPDATEERR,offset szInnerName,offset szWltEUpdateSuccess,@FInfo.lpszName
		.endif
	_NextFileUT:
		dec @nListFile
	.endw
_Ex4UT:
	invoke HeapFree,hGlobalHeap,0,@lpNewFileName
_Ex3UT:
	invoke HeapFree,hGlobalHeap,0,@lpTempName
_Ex2UT:
	invoke HeapFree,hGlobalHeap,0,@lpList
_ExUT:
	invoke GetSystemTime,addr @st
	invoke SystemTimeToFileTime,addr @st,addr @ft
	invoke SetFileTime,hLogFile,0,0,addr @ft
	mov bIsUpdatingProgram,0
	ret
_UpdateThd endp

_CheckFile proc uses ebx _lpszName,_lpFInfo
	LOCAL @hFile,@lpFile
	LOCAL @nFileSize:LARGE_INTEGER
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _ErrCF
	mov @hFile,eax
	invoke GetFileSizeEx,@hFile,addr @nFileSize
	invoke HeapAlloc,hGlobalHeap,0,dword ptr @nFileSize
	.if !eax
		_lbl1:
		invoke CloseHandle,@hFile
		jmp _ErrCF
	.endif
	mov @lpFile,eax
	invoke ReadFile,@hFile,@lpFile,dword ptr @nFileSize,offset dwTemp,0
	mov ebx,eax
	invoke CloseHandle,@hFile
	.if !ebx
		invoke HeapFree,hGlobalHeap,0,@lpFile
		jmp _ErrCF
	.endif
	invoke _CalcCheckSum,@lpFile,dword ptr @nFileSize
	mov ebx,eax
	invoke HeapFree,hGlobalHeap,0,@lpFile
	mov ecx,_lpFInfo
	xor eax,eax
	cmp ebx,_UpdateFileInfo.nCheckSum[ecx]
	sete al
	ret
_ErrCF:
	xor eax,eax
	ret
_CheckFile endp
