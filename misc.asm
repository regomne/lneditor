.code

;从资源中获取字符串
_GetConstString proc
	shl eax,8
	add eax,lpStrings
	ret
_GetConstString endp

_ofnOpenHook proc uses esi edi ebx hwnd,uMsg,wParam,lParam
	LOCAL @szName[512]:byte
	LOCAL @i
	mov eax,uMsg
	.if eax==WM_NOTIFY
		mov esi,lParam
		assume esi:ptr OFNOTIFY
		.if [esi].hdr.code==CDN_FIRST-CDN_FILEOK
			invoke SendDlgItemMessageW,hwnd,IDC_OPEN_PLUGINS,CB_GETCURSEL,0,0
			sub eax,2
			mov ecx,[esi].lpOFN
			mov OPENFILENAME.lCustData[ecx],eax
		.endif
		assume esi:nothing
	.elseif eax==WM_INITDIALOG
		invoke GetDlgItem,hwnd,IDC_OPEN_PLUGINS
		mov edi,eax
		mov ebx,SendMessageW
		assume ebx:ptr arg4
		mov eax,IDS_AUTOMATCH
		invoke _GetConstString
		invoke ebx,edi,CB_ADDSTRING,0,eax
		invoke _GetMelInfo,-1,addr @szName,VT_PRODUCTNAME
		invoke ebx,edi,CB_ADDSTRING,0,addr @szName
		mov esi,lpMels
		xor ecx,ecx
		mov @i,ecx
		.while ecx<nMels
			invoke _GetMelInfo,esi,addr @szName,VT_PRODUCTNAME
			invoke ebx,edi,CB_ADDSTRING,0,addr @szName
			inc @i
			mov ecx,@i
			add esi,sizeof _MelInfo
		.endw
		invoke ebx,edi,CB_SETCURSEL,0,0
		assume ebx:nothing
	.endif
	xor eax,eax
	ret
_ofnOpenHook endp

;
_OpenFileDlg proc uses edi ebx _lpszFilter,_lppszFN,_lpszInit,_lpszTitle,_lpdwPlugin
	LOCAL @opFileName:OPENFILENAME
	LOCAL @szErrMsg[128]:byte
	
	lea edi,@opFileName
	xor eax,eax
	mov ecx,sizeof @opFileName
	rep stosb
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
	test eax,eax
	jz _ExOFD
	mov edx,eax
	mov ecx,_lppszFN
	mov [ecx],eax
	mov ebx,MAX_STRINGLEN/2
_GetFN:
	mov @opFileName.lStructSize,sizeof @opFileName
	push hWinMain
	pop @opFileName.hwndOwner
	push hInstance
	pop @opFileName.hInstance
	push _lpszFilter
	pop @opFileName.lpstrFilter
	mov word ptr [edx],0
	mov @opFileName.lpstrFile,edx
	mov @opFileName.nMaxFile,ebx
	push _lpszInit
	pop @opFileName.lpstrInitialDir
	push _lpszTitle
	pop @opFileName.lpstrTitle
	mov @opFileName.lpTemplateName,IDD_OPENTML
	mov @opFileName.lpfnHook,offset _ofnOpenHook
	.if _lpdwPlugin
		mov @opFileName.Flags,OFN_FILEMUSTEXIST OR OFN_PATHMUSTEXIST or OFN_EXPLORER or \
			OFN_HIDEREADONLY or OFN_ENABLETEMPLATE OR OFN_ENABLEHOOK OR OFN_ENABLESIZING
	.else
		mov @opFileName.Flags,OFN_FILEMUSTEXIST OR OFN_PATHMUSTEXIST or OFN_EXPLORER or \
			OFN_HIDEREADONLY or OFN_ENABLESIZING
	.endif
	lea eax,@opFileName
	invoke GetOpenFileNameW,eax
	.if !eax
		invoke CommDlgExtendedError
		test eax,eax
		jz _ErrOFD
		.if eax==FNERR_BUFFERTOOSMALL
			mov eax,IDS_SELECTFILEAGAIN
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_ICONEXCLAMATION
			xor eax,eax
			mov ecx,@opFileName.lpstrFile
			mov ax,[ecx]
			add eax,10
			mov ebx,eax
			shl eax,1
			invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
			test eax,eax
			jz _ErrOFD
			mov edi,eax
			mov ecx,_lppszFN
			invoke HeapFree,hGlobalHeap,0,[ecx]
			mov ecx,_lppszFN
			mov [ecx],edi
			mov edx,edi
			jmp _GetFN
		.endif
		mov ebx,eax
		mov eax,IDS_ERROPENDLG
		invoke _GetConstString
		invoke wsprintfW,addr @szErrMsg,eax,ebx
		invoke MessageBoxW,hWinMain,addr @szErrMsg,0,MB_OK or MB_ICONERROR
		xor eax,eax
		ret
	.endif
	mov ecx,_lpdwPlugin
	.if ecx
		mov eax,@opFileName.lCustData
		mov [ecx],eax
	.endif
	mov eax,1
_ExOFD:
	ret
_ErrOFD:
	mov ecx,_lppszFN
	invoke HeapFree,hGlobalHeap,0,[ecx]
	xor eax,eax
	ret
_OpenFileDlg endp

;
_SaveFileDlg proc _lpszFilter,_lpszPath,_lpszInit,_lpszTitle
	LOCAL @opFileName:OPENFILENAME
	LOCAL @szErrMsg[128]:byte
	
	lea edi,@opFileName
	xor eax,eax
	mov ecx,sizeof @opFileName
	rep stosb
	mov @opFileName.lStructSize,sizeof @opFileName
	push hWinMain
	pop @opFileName.hwndOwner
	push _lpszFilter
	pop @opFileName.lpstrFilter
	push _lpszPath
	pop @opFileName.lpstrFile
	mov @opFileName.nMaxFile,MAX_STRINGLEN/2
	push _lpszInit
	pop @opFileName.lpstrInitialDir
	push _lpszTitle
	pop @opFileName.lpstrTitle
	mov @opFileName.Flags,OFN_EXPLORER or OFN_HIDEREADONLY or OFN_OVERWRITEPROMPT
	lea eax,@opFileName
	invoke GetSaveFileNameW,eax
	.if !eax
		invoke CommDlgExtendedError
		.if !eax
			ret
		.endif
		mov ebx,eax
		mov eax,IDS_ERROPENDLG
		invoke _GetConstString
		invoke wsprintfW,addr @szErrMsg,eax,ebx
		invoke MessageBoxW,hWinMain,addr @szErrMsg,0,MB_OK or MB_ICONERROR
		xor eax,eax
		ret
	.endif
	mov eax,1
	ret
_SaveFileDlg endp

;目录地址操作函数
_DirBackW proc uses edi _lpszPath
	mov edi,_lpszPath
	xor ax,ax
	mov ecx,MAX_STRINGLEN/2
	repne scasw
	sub edi,4
	.if word ptr [edi]=='\'
		sub edi,2
	.endif
	sub ecx,MAX_STRINGLEN/2
	neg ecx
	mov ax,'\'
	std
	repne scasw
	cld
	.if ecx
		mov word ptr [edi+4],0
		mov eax,1
		ret
	.endif
	mov eax,ecx
	ret
_DirBackW endp

_DirFileNameW proc uses edi _lpszPath
	mov edi,_lpszPath	
	xor ax,ax
	mov ecx,MAX_STRINGLEN/2
	repne scasw
	sub edi,2
	.if word ptr [edi-2]=='\'
		xor eax,eax
		ret
	.endif
	sub ecx,MAX_STRINGLEN/2
	neg ecx
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
_DirFileNameW endp

_DirCatW proc uses edi _lpszPath,_lpszName
	mov edi,_lpszName
	.if dword ptr [edi]==5c002eh;".\"
		add _lpszName,4
	.endif
	mov edi,_lpszPath
	xor ax,ax
	mov ecx,MAX_STRINGLEN/2
	repne scasw
	.if word ptr [edi-4]!='\'
		mov word ptr [edi-2],'\'
		mov word ptr [edi],0
	.endif
	invoke lstrcatW,_lpszPath,_lpszName
	ret
_DirCatW endp

_DirCmpW proc uses edi ebx _lpszPath,_lpszName
	
	mov edi,_lpszName
	.if dword ptr [edi]==5c002eh;".\"
		add _lpszName,4
	.endif
	mov edi,_lpszPath
	xor ax,ax
	mov ecx,MAX_STRINGLEN/2
	repne scasw
	xor ebx,ebx
	.if word ptr [edi-4]=='\'
		lea ebx,[edi-4]
		mov word ptr [ebx],0
		sub edi,4
	.endif
	sub ecx,MAX_STRINGLEN/2
	neg ecx
	mov ax,'\'
	std
	repne scasw
	cld
	add edi,4
	invoke lstrcmpW,edi,_lpszName
	.if ebx
		mov word ptr [ebx],'\'
	.endif
	ret
_DirCmpW endp

_DirModifyExtendName proc uses edi _lpOri,_lpExtendName
	mov edi,_lpOri
	xor ax,ax
	or ecx,-1
	repne scasw
	sub edi,2
	not ecx
	mov eax,edi
	.while word ptr [edi]!='.'
		sub edi,2
		dec ecx
		.if !ecx || word ptr [edi]=='\'
			mov edi,eax
			.break
		.endif
	.endw
	mov word ptr [edi],0
	invoke lstrcatW,_lpOri,_lpExtendName
	ret
_DirModifyExtendName endp

;将FileInfo中的String添加到列表框里面
_AddLines proc uses esi edi ebx _pdb
	LOCAL @hList
	LOCAL @nLine
	LOCAL @lpStopping
;	LOCAL @time1
	mov eax,_pdb
	mov edi,[eax]
	mov ecx,[eax+4]
	mov @hList,ecx
	mov ecx,[eax+8]
	mov @lpStopping,ecx
	assume edi:ptr _FileInfo
	xor ebx,ebx
	invoke SendMessageW,@hList,WM_SETREDRAW,FALSE,0
	mov ecx,[edi].nLine
	mov @nLine,ecx
	mov ecx,hList2
	.if ecx==@hList
;		rdtsc
;		shr eax,28
;		shl edx,4
;		or edx,eax
;		mov @time1,edx
		invoke SendDlgItemMessageW,hProgBarWindow,IDC_PRBAR_BAR,PBM_SETRANGE32,0,@nLine
	.endif
	.if [edi].nMemoryType==MT_EVERYSTRING || [edi].nMemoryType==MT_POINTERONLY
		mov esi,[edi].lpTextIndex
		.while ebx<@nLine
			mov eax,@lpStopping
			.if dword ptr [eax]!=0
				mov ecx,hList2
				.if ecx==@hList
					invoke PostMessageW,hWinMain,WM_COMMAND,IDM_CLOSE,0
				.endif
				jmp _ExAL
			.endif
			mov ecx,lpMarkTable
			.if !(byte ptr [ecx+ebx]&2)
				invoke SendMessageW,@hList,LB_ADDSTRING,0,[esi]
				mov ecx,hList2
				.if ecx==@hList && hProgBarWindow
					mov nProgBarLine,ebx
				.endif
			.endif
			add esi,4
			inc ebx
		.endw
	.endif
	mov ecx,hList2
	.if ecx==@hList
;		rdtsc
;		shr eax,28
;		shl edx,4
;		or edx,eax
;		sub edx,@time1
;		int 3
		mov eax,@lpStopping
		mov dword ptr [eax],1
		invoke EndDialog,hProgBarWindow,0
	.endif

	invoke SendMessageW,@hList,WM_SETREDRAW,TRUE,0
	invoke HeapFree,hGlobalHeap,0,_pdb
	.if ![edi].bReadOnly
		.if nCurIdx!=-1
			invoke _SetLineInListbox,nCurIdx,1
		.endif
	.endif
	assume edi:nothing
_ExAL:
	ret
_AddLines endp

_AddLinesToList proc uses esi edi ebx _pFI,_hList,_lpStopping
	LOCAL @pdb
	invoke HeapAlloc,hGlobalHeap,0,12
	or eax,eax
	je _ExALT
	mov @pdb,eax
	mov ecx,_pFI
	mov [eax],ecx
	mov ecx,_hList
	mov [eax+4],ecx
	mov ecx,_lpStopping
	mov [eax+8],ecx
	invoke CreateThread,0,0,offset _AddLines,@pdb,0,0
_ExALT:
	ret
_AddLinesToList endp

;从Name1生成Name2
_GenName2 proc uses ebx _lpszName1,_lppszName2
	LOCAL @lpszStr
	LOCAL @szTemp[SHORT_STRINGLEN]:byte
	.if dbConf+_Configs.nEditMode==EM_DOUBLE
		invoke lstrlenW,_lpszName1
		add eax,5
		shl eax,1
		invoke HeapAlloc,hGlobalHeap,0,eax
		test eax,eax
		jz _ErrGN
		mov ecx,_lppszName2
		mov [ecx],eax
		invoke lstrcpyW,eax,_lpszName1
	.endif

	invoke lstrlenW,_lpszName1
	add eax,20
	shl eax,1
	mov ebx,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	test eax,eax
	jz _ErrGN
	mov ecx,_lppszName2
	mov [ecx],eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	.if !eax
		mov ecx,_lppszName2
		invoke HeapFree,hGlobalHeap,0,[ecx]
		jmp _ErrGN
	.endif
	mov @lpszStr,eax
	
	invoke lstrcpyW,@lpszStr,_lpszName1
	invoke _DirBackW,@lpszStr
	invoke _DirFileNameW,_lpszName1
	mov ebx,eax
	invoke _DirCmpW,@lpszStr,dbConf+_Configs.lpNewScDir
	.if !eax
		invoke lstrcpyW,@lpszStr, _lpszName1
		invoke _DirBackW,@lpszStr
		invoke _DirBackW,@lpszStr
		invoke _DirFileNameW,_lpszName1
		invoke _DirCatW,@lpszStr,eax
		invoke CreateFileW,@lpszStr,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		.if eax!=-1
			invoke CloseHandle,eax
			mov eax,IDS_WRONGPOS
			invoke _GetConstString
			mov ecx,eax
			mov eax,IDS_WINDOWTITLE
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,ecx,eax,MB_YESNOCANCEL or MB_DEFBUTTON1 or MB_ICONQUESTION
			.if eax==IDYES
				.if dbConf+_Configs.nNewLoc==NL_CURRENT
					mov ecx,_lppszName2
					invoke lstrcpyW,[ecx],_lpszName1
					invoke lstrcpyW,_lpszName1,@lpszStr
					jmp _ExGN
				.else
					invoke lstrcpyW,_lpszName1,@lpszStr
					jmp _MakeFN2GN
				.endif
			.endif
			cmp eax,IDCANCEL
			jne _MakeFN2GN
			invoke HeapFree,hGlobalHeap,0,@lpszStr
			mov ecx,_lppszName2
			invoke HeapFree,hGlobalHeap,0,[ecx]
			xor eax,eax
			ret
		.endif
	.endif
_MakeFN2GN:
	.if dbConf+_Configs.nNewLoc==NL_CURRENT
		invoke lstrcpyW,@lpszStr,_lpszName1
	.else
		invoke GetModuleFileNameW,0,@lpszStr,MAX_STRINGLEN/2
	.endif
	invoke _DirBackW,@lpszStr
	invoke _DirCatW,@lpszStr,dbConf+_Configs.lpNewScDir
	invoke SetCurrentDirectoryW,@lpszStr
	.if !eax
		invoke CreateDirectoryW,@lpszStr,0
		invoke SetCurrentDirectoryW,@lpszStr
		.if !eax
			mov ecx,_lppszName2
			mov eax,[ecx]
			mov word ptr [eax],0
			invoke HeapFree,hGlobalHeap,0,@lpszStr
			jmp _ErrGN
		.endif
	.endif
	invoke _DirFileNameW,_lpszName1
	invoke _DirCatW,@lpszStr,eax
	mov ecx,_lppszName2
	invoke lstrcpyW,[ecx],@lpszStr
_ExGN:
	invoke HeapFree,hGlobalHeap,0,@lpszStr
	mov eax,1
	ret
_ErrGN:
	xor eax,eax
	ret
_GenName2 endp

;通过FileInfo结构中的文件名，打开文件并将其读入内存
_LoadFile proc uses edi _pFI,_LargeMem,_lpMelInfo2
	LOCAL @nFileSize:LARGE_INTEGER
	mov edi,_pFI
	assume edi:ptr _FileInfo
_BeginLF:
	.if [edi].bReadOnly
		mov ecx,GENERIC_READ
	.else
		mov ecx,GENERIC_READ or GENERIC_WRITE
	.endif
	invoke CreateFileW,[edi].lpszName,ecx,FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _FailLF
	mov [edi].hFile,eax
	
	mov ecx,_lpMelInfo2
	.if !(_MelInfo2.nCharacteristic[ecx] & MIC_NOPREREAD)
		invoke GetFileSizeEx,[edi].hFile,addr @nFileSize
		mov eax,dword ptr @nFileSize
		.if !eax && !dword ptr [@nFileSize+4]
			invoke CloseHandle,[edi].hFile
			invoke DeleteFileW,[edi].lpszName
			jmp _BeginLF
		.endif
		.if _LargeMem==LM_HALF
			mov ecx,eax
			shr ecx,1
			add eax,ecx
			mov dword ptr @nFileSize,eax
		.elseif _LargeMem==LM_ONE
			shl eax,1
			mov dword ptr @nFileSize,eax
		.else
			add eax,4
			mov dword ptr @nFileSize,eax
		.endif
		invoke VirtualAlloc,0,dword ptr @nFileSize,MEM_COMMIT,PAGE_READWRITE
		or eax,eax
		je _FailLF
		mov [edi].lpStream,eax
		invoke ReadFile,[edi].hFile,[edi].lpStream,dword ptr @nFileSize,offset dwTemp,0
		or eax,eax
		je _FailLF
		mov eax,dwTemp
		mov [edi].nStreamSize,eax
	.endif
	assume edi:nothing
_SucLF:
	mov eax,1
	ret
_FailLF:
	xor eax,eax
	ret
_LoadFile endp

;显示是否保存对话框
_SaveOrNot proc
	mov eax,IDS_SAVEORNOT
	invoke _GetConstString
	mov ecx,eax
	mov eax,IDS_WINDOWTITLE
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,ecx,eax,MB_YESNOCANCEL or MB_DEFBUTTON1 or MB_ICONINFORMATION
	
	ret
_SaveOrNot endp

;释放FileInfo结构中的内存并清零
_ClearAll proc uses edi ebx esi _pFI
	mov edi,_pFI
	assume edi:ptr _FileInfo
	mov eax,dbSimpFunc+_SimpFunc.Release
	.if eax
		push edi
		call eax
	.endif
	mov ecx,[edi].nMemoryType
	.if ecx==MT_EVERYSTRING || ecx==MT_POINTERONLY
		mov esi,[edi].lpTextIndex
		mov ebx,[edi].nLine
		.while ebx
			lodsd
			invoke HeapFree,hGlobalHeap,0,eax
			dec ebx
		.endw
	.endif
	
	invoke CloseHandle,[edi].hFile
	invoke VirtualFree,[edi].lpStream,0,MEM_RELEASE
	invoke VirtualFree,[edi].lpTextIndex,0,MEM_RELEASE
	invoke VirtualFree,[edi].lpStreamIndex,0,MEM_RELEASE
	invoke HeapFree,hGlobalHeap,0,[edi].lpszName
	assume edi:nothing
	xor al,al
	mov ecx,sizeof _FileInfo
	rep stosb
	ret
_ClearAll endp

;状态框文本显示
_Display proc uses edi _sztime
	mov edi,_sztime
	invoke SetWindowTextW,hStatus,[edi]
	invoke Sleep,[edi+4]
	invoke SetWindowTextW,hStatus,NULL
	invoke HeapFree,hGlobalHeap,0,edi
	xor eax,eax
	ret
_Display endp
_DisplayStatus proc _lpsz,_time
;	invoke HeapAlloc,hGlobalHeap,0,8
;	or eax,eax
;	je @F
;	mov ecx,_lpsz
;	mov [eax],ecx
;	mov ecx,_time
;	mov [eax+4],ecx
;	invoke CreateThread,0,0,offset _Display,eax,0,0
;	invoke CloseHandle,eax
;	@@:
	ret
_DisplayStatus endp

;根据FileInfo结构保存文件（调用插件的SaveText或者直接保存）
_SaveFile proc uses edi ebx _pFI
	mov edi,_pFI
	assume edi:ptr _FileInfo
	.if dbSimpFunc+_SimpFunc.SaveText
		push _pFI
		call [dbSimpFunc+_SimpFunc.SaveText]
		or eax,eax
		jne _ExSF
	.else
		invoke SetFilePointer,[edi].hFile,0,0,FILE_BEGIN
		invoke WriteFile,[edi].hFile,[edi].lpStream,[edi].nStreamSize,offset dwTemp,0
		or eax,eax
		je _ErrFileSF
		invoke SetEndOfFile,[edi].hFile
		or eax,eax
		je _ErrFileSF
	.endif
	invoke _WriteRec
	xor eax,eax
_ExSF:
	ret
_ErrFileSF:
	mov eax,E_FILEACCESSERROR
	ret
_SaveFile endp

;设置修改标志，设置菜单项。
_SetModified proc uses ebx _bFlag
	.if _bFlag && !bModified
		invoke EnableMenuItem,hMenu,IDM_SAVE,MF_ENABLED
		mov bModified,1
		
		mov eax,dbConf+_Configs.nAutoSaveTime
		.if eax
			mov edx,1000
			mul edx
			invoke SetTimer,hWinMain,IDC_TIMER,eax,NULL
		.endif
		
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
		or eax,eax
		je @F
		mov ebx,eax
		invoke _GenWindowTitle,ebx,GWT_MODIFIED
		invoke SetWindowTextW,hWinMain,ebx
		invoke HeapFree,hGlobalHeap,0,ebx
	.elseif !_bFlag && bModified
		invoke EnableMenuItem,hMenu,IDM_SAVE,MF_GRAYED
		mov bModified,0
		
		.if dbConf+_Configs.nAutoSaveTime
			invoke KillTimer,hWinMain,IDC_TIMER
		.endif
		
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
		or eax,eax
		je @F
		mov ebx,eax
		.if dbConf+_Configs.nEditMode==EM_SINGLE
			mov eax,GWT_FILENAME1
		.else
			mov eax,GWT_FILENAME2
		.endif
		invoke _GenWindowTitle,ebx,eax
		invoke SetWindowTextW,hWinMain,ebx
		invoke HeapFree,hGlobalHeap,0,ebx
	.endif
	@@:
	ret
_SetModified endp

;
_SetOpenState proc uses esi edi ebx _bFlag
	.if _bFlag
		mov ecx,sizeof _MelInfo
		mov eax,nCurMel
		.if eax!=-1
			mul cx
			add eax,lpMels
			mov ebx,_MelInfo.lpMelInfo2[eax]
		.else
			lea ebx,dbMelInfo2
		.endif
		mov bOpen,1
		mov esi,MF_ENABLED
		mov edi,MF_GRAYED
		.if _MelInfo2.nCharacteristic[ebx]&MIC_NOHALFANGLE
			push edi
		.else
			push esi
		.endif
		push IDM_CVTHALF
		push hMenu
		call EnableMenuItem
		invoke GetTickCount
		mov nFileOpenTime,eax
	.else
		mov bOpen,0
		mov edi,MF_ENABLED
		mov esi,MF_GRAYED
		invoke EnableMenuItem,hMenu,IDM_SAVE,esi
		invoke EnableMenuItem,hMenu,IDM_CVTHALF,ESI
		mov nFileOpenTime,0
	.endif
	invoke EnableMenuItem,hMenu,IDM_CLOSE,esi
	invoke EnableMenuItem,hMenu,IDM_SAVEAS,esi
	invoke EnableMenuItem,hMenu,IDM_SETCODE,esi
	invoke EnableMenuItem,hMenu,IDM_IMPORT,ESI
	invoke EnableMenuItem,hMenu,IDM_EXPORT,ESI
	mov ebx,IDM_MODIFY
	.while ebx<=IDM_GOTO
		invoke EnableMenuItem,hMenu,ebx,esi
		inc ebx
	.endw
	invoke EnableMenuItem,hMenu,IDM_CVTFULL,esi
	invoke EnableMenuItem,hMenu,IDM_UNMARKALL,esi
	invoke EnableMenuItem,hMenu,IDM_PROGRESS,esi
	ret
_SetOpenState endp

;获取StringList中的指定行的文本
_GetStringInList proc uses edi _pFI,_nLine
	mov edi,_pFI
	assume edi:ptr _FileInfo
	mov eax,_nLine
	.if eax>=[edi].nLine
		xor eax,eax
		ret
	.endif
	.if [edi].nMemoryType==MT_EVERYSTRING || [edi].nMemoryType==MT_POINTERONLY
		mov edi,[edi].lpTextIndex
		mov eax,dword ptr [edi+eax*4]
	.else
		xor eax,eax
	.endif
	assume edi:nothing
	ret
_GetStringInList endp

_ConvertFA proc uses esi edi _lpsz,_nType
	mov edi,_lpsz
	mov esi,edi
	.if _nType==AC_FULLANGLE
		lodsw
		.while ax
			.if ax==20h
				mov ax,3000h
				jmp @F
			.elseif ax<=7eh && ax>=21h
				add ax,0fee0h
				jmp @F
			.endif
			@@:
			stosw
			lodsw
		.endw
	.elseif _nType==AC_HALFANGLE
		lodsw
		.while ax
			.if ax==3000h
				mov ax,20h
				jmp @F
			.elseif ax>=0ff01h && ax<=0ff5eh
				sub ax,0fee0h
				jmp @F
			.endif
			@@:
			stosw
			lodsw
		.endw
	.endif
	ret
_ConvertFA endp

;计算列表框中行的高度
_CalHeight proc uses edi _nPos
	LOCAL @hdc,@pStr
	LOCAL @sz:POINT
	LOCAL @s[4]:byte
	LOCAL @tm:TEXTMETRIC
;获取字体的上间距，乘之前先加到@sz.y上面。
	invoke GetDC,hList1
	mov @hdc,eax
	invoke SelectObject,@hdc,hFontList
	mov dword ptr @s,3001h
	mov ecx,_nPos
	.if ecx>FileInfo1.nLine
		lea eax,@s
		jmp @F
	.endif
	invoke _GetStringInList,offset FileInfo1,_nPos
	.if !eax || !word ptr [eax]
		lea eax,@s
	.endif
	@@:
	mov @pStr,eax
	invoke lstrlenW,@pStr
	mov ecx,eax
	invoke GetTextExtentPoint32W,@hdc,@pStr,ecx,addr @sz
	mov eax,@sz.x
	xor edx,edx
	div dbConf+_Configs.windowRect[WRI_LIST1]+RECT.right
	.if edx
		inc eax
	.endif
	add @sz.y,LI_MARGIN_WIDTH
	mul @sz.y
	add eax,LI_MARGIN_WIDTH
	push eax
	
	invoke _GetStringInList,offset FileInfo2,_nPos
	.if !eax || !word ptr [eax]
		lea eax,@s
	.endif
	mov @pStr,eax
	invoke lstrlenW,@pStr
	mov ecx,eax
	invoke GetTextExtentPoint32W,@hdc,@pStr,ecx,addr @sz
	invoke ReleaseDC,hList1,@hdc
	mov eax,@sz.x
	xor edx,edx
	div dbConf+_Configs.windowRect[WRI_LIST2]+RECT.right
	.if edx
		inc eax
	.endif
	add @sz.y,LI_MARGIN_WIDTH
	mul @sz.y
	add eax,LI_MARGIN_WIDTH
	pop ecx
	.if ecx>eax
		mov eax,ecx
	.endif
	ret
_CalHeight endp

;将列表框中的文本显示在编辑框中
_SetTextToEdit proc uses esi edi ebx _nIdx
	LOCAL @ps1,@ps2
	LOCAL @range[2]:dword
	invoke _GetStringInList,offset FileInfo1,_nIdx
	or eax,eax
	je _ExSTTE
	mov esi,eax
	invoke lstrlenW,esi
	inc eax
	mov ebx,eax
	shl eax,2
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	or eax,eax
	je _ExSTTE
	mov @ps1,eax
	mov edi,eax
	mov ecx,ebx
	rep movsw
	
_Dis2STTE:
	invoke _GetStringInList,offset FileInfo2,_nIdx
	or eax,eax
	je _ExSTTE2
	mov esi,eax
	invoke lstrlenW,esi
	inc eax
	mov ebx,eax
	shl eax,2
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	or eax,eax
	je _ExSTTE2
	mov @ps2,eax
	mov edi,eax
	mov ecx,ebx
	rep movsw
	
	mov dword ptr @range,0
	mov dword ptr [@range+4],-1
	mov ebx,dbSimpFunc+_SimpFunc.SetLine
	.if ebx
		push 0
		push @ps1
		call ebx
		lea eax,@range
		push eax
		push @ps2
		call ebx
	.endif
	invoke SendMessageW,hEdit1,WM_SETTEXT,0,@ps1
	invoke SendMessageW,hEdit2,WM_SETTEXT,0,@ps2
	invoke SetFocus,hEdit2
	.if dbConf+_Configs.bAutoSelText==TRUE
		invoke SendMessageW,hEdit2,EM_SETSEL,@range,[@range+4]
	.ENDIF

	invoke HeapFree,hGlobalHeap,0,@ps2
_ExSTTE2:
	invoke HeapFree,hGlobalHeap,0,@ps1
_ExSTTE:
	xor eax,eax
	ret
_SetTextToEdit endp

;
_ShowPic proc uses ebx _hdc,_lpszName
	LOCAL @pStm:LPSTREAM
	LOCAL @pPic:LPPICTURE
	LOCAL @nSize[2],@hFilePic,@hGlobal
	LOCAL @hmWidth,@hmHeight
	LOCAL @hmdc,@hBmp,@hOldBmp,@bf:BLENDFUNCTION
	LOCAL @rect:RECT
;	invoke SHCreateStreamOnFileW,_lpszName,STGM_READ or STGM_SHARE_DENY_WRITE,addr @pStm
;	cmp eax,S_OK
;	jne _ErrSP
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,-1
	je _ErrSP
	mov @hFilePic,eax
	invoke GetFileSizeEx,@hFilePic,addr @nSize
	invoke GlobalAlloc,GMEM_MOVEABLE,dword ptr @nSize
	.if !eax
		_Ex1SJ:
		invoke CloseHandle,@hFilePic
		jmp _ErrSP
	.endif
	mov @hGlobal,eax
	invoke GlobalLock,@hGlobal
	.if !eax
		_Ex2SJ:
		invoke GlobalFree,@hGlobal
		jmp _Ex1SJ
	.endif
	invoke ReadFile,@hFilePic,eax,dword ptr @nSize,offset dwTemp,0
	invoke GlobalUnlock,@hGlobal
	invoke CreateStreamOnHGlobal,@hGlobal,TRUE,addr @pStm
	or eax,eax
	jne _Ex2SJ
	invoke OleLoadPicture,@pStm,dword ptr @nSize,TRUE,offset IID_IPicture,addr @pPic
	.if eax
		mov eax,@pStm
		mov eax,[eax]
		invoke (IStream ptr [eax]).Release,@pStm
		jmp _Ex1SJ
	.endif
	mov ebx,@pPic
	assume ebx:nothing
	mov ebx,[ebx]
	invoke (IPicture ptr [ebx]).get_Width,@pPic,addr @hmWidth
	invoke (IPicture ptr [ebx]).get_Height,@pPic,addr @hmHeight
	mov ecx,@hmHeight
	neg ecx
	invoke (IPicture ptr [ebx]).Render,@pPic,_hdc,0,0,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.right,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.bottom,\
		0,@hmHeight,@hmWidth,ecx,0
	invoke (IPicture ptr [ebx]).Release,@pPic
	mov eax,@pStm
	mov eax,[eax]
	invoke (IStream ptr [eax]).Release,@pStm
	invoke CloseHandle,@hFilePic
	mov eax,1
	ret
_ErrSP:
	xor eax,eax
	ret
_ShowPic endp

_GenWindowTitle proc _lpsz,_nType
	mov eax,_nType
	.if EAX==GWT_FILENAME1
		invoke lstrcpyW,_lpsz,FileInfo1.lpszName
		@@:
		invoke lstrcatW,_lpsz,offset szGang
		mov eax,IDS_WINDOWTITLE
		invoke _GetConstString
		invoke lstrcatW,_lpsz,eax
	.elseif eax==GWT_FILENAME2
		invoke lstrcpyW,_lpsz,FileInfo2.lpszName
		jmp @B
	.elseif eax==GWT_VERSION
		mov eax,IDS_WINDOWTITLE
		invoke _GetConstString
		invoke lstrcpyW,_lpsz,eax
		invoke lstrcatW,_lpsz,offset szDisplayVer
	.elseif eax==GWT_MODIFIED
		invoke lstrcpyW,_lpsz,offset szXing
		add _lpsz,4
		invoke GetWindowTextW,hWinMain,_lpsz,(MAX_STRINGLEN+SHORT_STRINGLEN-4)/2
	.endif
	ret
_GenWindowTitle endp

_Dev proc
	mov eax,IDS_DEVELOP
	invoke _GetConstString
	mov ecx,eax
	mov eax,IDS_SHUAI
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,ecx,MB_OK or MB_ICONEXCLAMATION
	ret
_Dev endp

;
_memcpy proc
;	mov eax,edi
;	and eax,3
;	mov edx,ecx
;	mov ecx,4
;	sub ecx,eax
;	rep movsb
;	mov ecx,edx
;	
	
	mov eax,ecx
	shr ecx,2
	REP MOVSd
	mov ecx,eax
	and ecx,3
	REP MOVSb
	ret
_memcpy endp
