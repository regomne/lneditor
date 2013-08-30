.code
assume fs:nothing

if 0
;
_OpenScript proc
	LOCAL @nReturnInfo
	LOCAL @nPos
	LOCAL @pbInfo:_ProgBarInfo
	LOCAL @szstr[SHORT_STRINGLEN]:byte
	
	xor eax,eax
	mov FileInfo2.bReadOnly,eax
	inc eax
	mov FileInfo1.bReadOnly,eax
	.if dbConf+_Configs.nEditMode==EM_SINGLE
		invoke _GenName2,FileInfo1.lpszName,offset FileInfo2.lpszName
		or eax,eax
		je _ExOS
	.endif
	
	mov eax,nCurMel
	.if eax!=-1
		mov edi,lpMels
		mov bx,sizeof _MelInfo
		mul bx
		add edi,eax
		mov ebx,_MelInfo.lpMelInfo2[edi]
	.else
		mov ebx,offset dbMelInfo2
	.endif
	invoke _LoadFile,offset FileInfo1,LM_NONE,ebx
	.if !eax
		invoke _ClearAll,offset FileInfo1
		jmp _ErrLoadOS
	.endif
	.if dbConf+_Configs.nEditMode==EM_SINGLE
		invoke _LoadFile,offset FileInfo2,LM_HALF,ebx
		.if !eax
			invoke GetLastError
			.if eax==ERROR_FILE_NOT_FOUND
				invoke CopyFileW,FileInfo1.lpszName,FileInfo2.lpszName,FALSE
				invoke _LoadFile,offset FileInfo2,LM_HALF,ebx
				or eax,eax
				jne @F
			.endif
			invoke _ClearAll,offset FileInfo1
			invoke _ClearAll,offset FileInfo2
			jmp _ErrLoadOS
		.endif
	.endif
	
	@@:
;	invoke _ReadRec,REC_CHARSET
	
	push offset _HandlerOS
	push fs:[0]
	mov fs:[0],esp
	lea eax,@nReturnInfo
	push eax
	push offset FileInfo1
	call dword ptr [dbSimpFunc+_SimpFunc.GetText]
	.if !eax
		.if @nReturnInfo==RI_SUC_LINEONLY
			.if FileInfo1.nMemoryType==MT_POINTERONLY
				invoke _MakeStringListFromStream,offset FileInfo1
				.if eax
					mov ecx,eax
					mov eax,IDS_ERRORCODE
					invoke _GetConstString
					invoke wsprintfW,addr @szstr,eax,ecx
					invoke _ClearAll,offset FileInfo1
					invoke MessageBoxW,hWinMain,addr @szstr,0,MB_ICONERROR or MB_OK
				.endif
			.endif
			invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,FileInfo1.nLine
			mov lpMarkTable,eax
;			invoke _ReadRec,REC_MARKTABLE
			.if dbConf+_Configs.bAlwaysFilter
				invoke _UpdateHideTable,offset FileInfo1
			.endif
			mov bProgBarStopping1,0
			invoke _AddLinesToList,offset FileInfo1,hList1,offset bProgBarStopping1
		.endif
	.else
		jmp _ErrDllOS
	.endif
	.if dbConf+_Configs.nEditMode==EM_SINGLE
		lea eax,@nReturnInfo
		push eax
		push offset FileInfo2
		call dword ptr [dbSimpFunc+_SimpFunc.GetText]
		.if !eax
			mov eax,FileInfo1.nLine
			.if eax!=FileInfo2.nLine
				invoke _ClearAll,offset FileInfo1
				invoke _ClearAll,offset FileInfo2
				.if lpMarkTable
					invoke HeapFree,hGlobalHeap,0,lpMarkTable
				.endif
				mov eax,IDS_LINENOTMATCH
				invoke _GetConstString				
				invoke MessageBoxW,hWinMain,eax,0,MB_OK OR MB_ICONERROR
				jmp _Ex2OS
			.endif
			.if @nReturnInfo==RI_SUC_LINEONLY
				.if FileInfo2.nMemoryType==MT_POINTERONLY
					invoke _MakeStringListFromStream,offset FileInfo2
					.if eax
						mov ecx,eax
						mov eax,IDS_ERRORCODE
						invoke _GetConstString
						invoke wsprintfW,addr @szstr,eax,ecx
						invoke _ClearAll,offset FileInfo1
						invoke _ClearAll,offset FileInfo2
						invoke MessageBoxW,hWinMain,addr @szstr,0,MB_ICONERROR or MB_OK
						.if lpMarkTable
							invoke HeapFree,hGlobalHeap,0,lpMarkTable
						.endif
						jmp _Ex2OS
					.endif
				.endif
				mov nCurIdx,-1
				mov bProgBarStopping2,0
				invoke _DirFileNameW,FileInfo2.lpszName
				mov @pbInfo.lpszTitle,eax
				mov @pbInfo.bNoStop,0
				invoke _AddLinesToList,offset FileInfo2,hList2,offset bProgBarStopping2
				invoke DialogBoxParamW,hInstance,IDD_PROGBAR,hWinMain,offset _WndProgBarProc,addr @pbInfo
				mov ecx,dbConf+_Configs.nAutoCode
				.if ecx && FileInfo2.nCharSet!=CS_UNICODE && FileInfo2.nCharSet!=CS_UTF8
					mov FileInfo2.nCharSet,ecx
					xor ebx,ebx
					xor edi,edi
					.while ebx<FileInfo2.nLine
						push ebx
						push offset FileInfo2
						call dbSimpFunc+_SimpFunc.ModifyLine
						or edi,eax
						inc ebx
					.endw
					.if edi
						mov eax,IDS_CODECVTFAILED
						invoke _GetConstString
						invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
					.endif
				.endif 
				invoke _SetOpenState,1
			.endif
		.else
			.if lpMarkTable
				invoke HeapFree,hGlobalHeap,0,lpMarkTable
			.endif
			jmp _ErrDllOS
		.endif
		
		invoke EnableMenuItem,hMenu,IDM_LOAD,MF_GRAYED

		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,FileInfo1.nLine
		mov lpModifyTable,eax
		
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN+SHORT_STRINGLEN
		or eax,eax
		je _Ex2OS
		mov ebx,eax
		invoke _GenWindowTitle,ebx,GWT_FILENAME1
		invoke SetWindowTextW,hWinMain,ebx
		invoke HeapFree,hGlobalHeap,0,ebx
	.else
		invoke EnableMenuItem,hMenu,IDM_LOAD,MF_ENABLED
	.endif
_Ex2OS:
	pop fs:[0]
	pop ecx
_ExOS:
	xor eax,eax
	ret
_ErrLoadOS:
	mov eax,IDS_ERRLOADFILE
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
	xor eax,eax
	ret
_ErrDllOS:
	pop fs:[0]
	pop eax
	mov eax,IDS_DLLERR
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
	invoke _ClearAll,offset FileInfo1
	invoke _ClearAll,offset FileInfo2
	xor eax,eax
	ret
_HandlerOS:
	mov eax,[esp+0ch]
	mov [eax+0b8h],offset _ErrDllOS
	xor eax,eax
	retn 0ch
_OpenScript endp
endif

_OpenScript2 proc uses edi esi ebx _lpOpenPara
	LOCAL @err
	LOCAL @pbInfo:_ProgBarInfo
	mov edi,_lpOpenPara
	assume edi:ptr _OpenParameters
	
	invoke _OpenSingleScript,edi,offset FileInfo1,1
	mov @err,eax
	test eax,eax
	jnz _ErrOS
	invoke _OpenSingleScript,edi,offset FileInfo2,0
	mov @err,eax
	test eax,eax
	jnz _Err2OS
	
	mov eax,FileInfo1.nLine
	.if eax!=FileInfo2.nLine
		mov @err,E_LINENOTMATCH
		jmp _Err3OS
	.endif
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,FileInfo1.nLine
	mov lpMarkTable,eax
	invoke _ReadRec,[edi].ScriptName,REC_MARKTABLE,FileInfo1.nLine
	.if dbConf+_Configs.bAlwaysFilter
		invoke _UpdateHideTable,offset FileInfo1
	.endif
	
	mov ecx,dbConf+_Configs.nAutoCode
	.if ecx && FileInfo2.nCharSet!=CS_UNICODE && FileInfo2.nCharSet!=CS_UTF8
		mov FileInfo2.nCharSet,ecx
		xor ebx,ebx
		xor esi,esi
		.while ebx<FileInfo2.nLine
			push ebx
			push offset FileInfo2
			call dbSimpFunc+_SimpFunc.ModifyLine
			or esi,eax
			inc ebx
		.endw
		.if esi
			mov eax,IDS_CODECVTFAILED
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
		.endif
	.endif
	
	mov eax,[edi].Line
	mov nCurIdx,eax
	mov bProgBarStopping1,0
	mov bProgBarStopping2,0
	invoke _DirFileNameW,[edi].ScriptName
	mov @pbInfo.lpszTitle,eax
	mov @pbInfo.bNoStop,0
	invoke _AddLinesToList,offset FileInfo1,hList1,offset bProgBarStopping1
	invoke _AddLinesToList,offset FileInfo2,hList2,offset bProgBarStopping2
	invoke DialogBoxParamW,hInstance,IDD_PROGBAR,hWinMain,offset _WndProgBarProc,addr @pbInfo
	
	invoke _SetOpenState,1

	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,FileInfo1.nLine
	mov lpModifyTable,eax
	
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN+SHORT_STRINGLEN
	or eax,eax
	je _ExOSS
	mov ebx,eax
	invoke _GenWindowTitle,ebx,GWT_FILENAME1
	invoke SetWindowTextW,hWinMain,ebx
	invoke HeapFree,hGlobalHeap,0,ebx

	assume edi:nothing
_ExOSS:
	ret
_Err3OS:
	invoke _ClearAll,offset FileInfo2
_Err2OS:
	invoke _ClearAll,offset FileInfo1
_ErrOS:
	invoke _OutputMessage,@err,offset szInnerName,0,0
	ret
_OpenScript2 endp

_OpenSingleScript proc uses esi edi ebx _lpOpenPara,_lpFI,_bIsLeft
	LOCAL @nReturnInfo
	mov edi,_lpOpenPara
	assume edi:ptr _OpenParameters
	mov eax,[edi].ScriptName
	.if !eax
		mov eax,E_INVALIDPARAMETER
		jmp _ExOSS
	.endif
	
	.if _bIsLeft
		invoke HeapAlloc,hGlobalHeap,0,MAX_STRINGLEN
		.if !eax
			mov eax,E_NOMEM
			jmp _ExOSS
		.endif
		mov ecx,_lpFI
		mov _FileInfo.lpszName[ecx],eax
		.if nUIStatus&UIS_CONSOLE
			mov _FileInfo.bReadOnly[ecx],0
		.else
			mov _FileInfo.bReadOnly[ecx],1
		.endif
		mov eax,[edi].Code1
		mov _FileInfo.nCharSet[ecx],eax
		invoke lstrcpyW,_FileInfo.lpszName[ecx],[edi].ScriptName
	.else
		mov ecx,_lpFI
		mov _FileInfo.bReadOnly[ecx],0
		mov eax,[edi].Code2
		mov _FileInfo.nCharSet[ecx],eax
		invoke _GenName2,[edi].ScriptName,addr _FileInfo.lpszName[ecx]
		.if !eax
			mov eax,E_NOMEM
			jmp _ExOSS
		.endif
	.endif
	
	mov eax,[edi].Plugin
	.if eax!=-1
		mov esi,lpMels
		mov bx,sizeof _MelInfo
		mul bx
		add esi,eax
		mov ebx,_MelInfo.lpMelInfo2[esi]
	.else
		mov eax,[edi].Filter
		mov nCurMef,eax
		mov ebx,offset dbMelInfo2
	.endif
	.if _bIsLeft
		.if nUIStatus&UIS_CONSOLE
			invoke _LoadFile,_lpFI,LM_ONE,ebx
		.else
			invoke _LoadFile,_lpFI,LM_NONE,ebx
		.endif
		@@:
		.if !eax
			mov eax,E_FILEACCESSERROR
			jmp _ErrDll2OSS
		.endif
	.else
		invoke _LoadFile,_lpFI,LM_HALF,ebx
		.if !eax
			invoke GetLastError
			.if eax==ERROR_FILE_NOT_FOUND
				mov ecx,_lpFI
				invoke CopyFileW,[edi].ScriptName,_FileInfo.lpszName[ecx],FALSE
				invoke _LoadFile,offset FileInfo2,LM_HALF,ebx
				jmp @B
			.endif
			mov eax,E_FILEACCESSERROR
			jmp _ErrDll2OSS
		.endif
	.endif
	push ebp
	push offset _HandlerOSS
	push fs:[0]
	mov fs:[0],esp
	lea eax,@nReturnInfo
	push eax
	push _lpFI
	call dword ptr [dbSimpFunc+_SimpFunc.GetText]
	test eax,eax
	jnz _ErrDllOSS
	mov ecx,_lpFI
	.if _FileInfo.nMemoryType[ecx]==MT_POINTERONLY
		invoke _MakeStringListFromStream,_lpFI
		test eax,eax
		jnz _ErrDllOSS
	.endif
	
	assume edi:nothing
_Ex2OSS:
	pop fs:[0]
	add esp,8
_ExOSS:
	ret
_ErrDllOSS:
	pop fs:[0]
	add esp,8
_ErrDll2OSS:
	mov ebx,eax
	invoke _ClearAll,_lpFI
	mov eax,ebx
	ret
_HandlerOSS:
	mov edx,[esp+0ch]
	mov [edx+0b8h],offset _ErrDllOSS
	mov ecx,[esp+8]
	mov [edx+0c4h],ecx
	mov eax,[ecx+8]
	mov [edx+0b4h],eax
	mov ecx,[esp+4]
	mov eax,[ecx]
	.if eax==STATUS_BREAKPOINT ;8..3
		mov dword ptr [edx+0b0h],E_ANALYSISFAILED
	.elseif eax==STATUS_ACCESS_VIOLATION ;c..5
		mov dword ptr [edx+0b0h],E_OVERMEM
	.else
		mov dword ptr [edx+0b0h],E_PLUGINERROR
	.endif
	xor eax,eax
	retn 0ch
_OpenSingleScript endp

;
_LoadScript proc
	LOCAL @nReturnInfo
	LOCAL @szstr[20]:word
	
	mov eax,nCurMel
	.if eax!=-1
		mov edi,lpMels
		mov bx,sizeof _MelInfo
		mul bx
		add edi,eax
		mov ebx,_MelInfo.lpMelInfo2[edi]
	.else
		mov ebx,offset dbMelInfo2
	.endif
	invoke _LoadFile,offset FileInfo2,LM_HALF,ebx
	.if !eax
		invoke _ClearAll,offset FileInfo2
		jmp _ErrLoadLS
	.endif
	
	push offset _HandlerLS
	push fs:[0]
	mov fs:[0],esp
	lea eax,@nReturnInfo
	push eax
	push offset FileInfo2
	call dword ptr [dbSimpFunc+_SimpFunc.GetText]
	.if !eax
		mov eax,FileInfo1.nLine
		.if eax!=FileInfo2.nLine
			invoke _ClearAll,offset FileInfo2
			mov eax,IDS_LINENOTMATCH
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_OK OR MB_ICONERROR
			jmp _ExLS
		.endif
		.if @nReturnInfo==RI_SUC_LINEONLY
			.if FileInfo2.nMemoryType==MT_POINTERONLY
				invoke _MakeStringListFromStream,offset FileInfo2
				.if eax
					mov ecx,eax
					mov eax,IDS_ERRORCODE
					invoke _GetConstString
					invoke wsprintfW,addr @szstr,eax,ecx
					invoke _ClearAll,offset FileInfo2
					invoke MessageBoxW,hWinMain,addr @szstr,0,MB_ICONERROR or MB_OK
				.endif
			.endif
			mov nCurIdx,-1
			mov bProgBarStopping2,0
			invoke _AddLinesToList,offset FileInfo2,hList2,offset bProgBarStopping2
			mov ecx,dbConf+_Configs.nAutoCode
;			.if ecx && FileInfo2.nCharSet!=CS_UNICODE && File2.nCharSet!=CS_UTF8
;				mov FileInfo2.nCharSet,ecx
;				xor ebx,ebx
;				xor edi,edi
;				.while ebx<FileInfo2.nLine
;					push ebx
;					push offset FileInfo2
;					call dbSimpFunc+_SimpFunc.ModifyLine
;					or edi,eax
;					inc ebx
;				.endw
;				.if edi
;					mov eax,IDS_CODECVTFAILED
;					invoke _GetConstString
;					invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
;				.endif
;			.endif
			invoke _SetOpenState,1
		.endif
	.else
		invoke _ClearAll,offset FileInfo2
		jmp _Ex2LS
	.endif
_Ex2LS:
	pop fs:[0]
	pop ecx
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN+SHORT_STRINGLEN
	or eax,eax
	je _ExLS
	mov ebx,eax
	invoke _GenWindowTitle,ebx,GWT_FILENAME2
	invoke SetWindowTextW,hWinMain,ebx
	invoke HeapFree,hGlobalHeap,0,ebx

_ExLS:
	xor eax,eax
	ret
_ErrLoadLS:
	mov eax,IDS_ERRLOADFILE
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
	xor eax,eax
	ret
_ErrDllLS:
	pop fs:[0]
	pop eax
	mov eax,IDS_DLLERR
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
	invoke _ClearAll,offset FileInfo2
	xor eax,eax
	ret
_HandlerLS:
	mov eax,[esp+0ch]
	mov [eax+0b8h],offset _ErrDllLS
	xor eax,eax
	ret
_LoadScript endp

;
_SaveScript proc
	.if bModified
		invoke _SaveFile,offset FileInfo2
		or eax,eax
		jne _ErrSS
		mov eax,IDS_SUCSAVE
		INVOKE _GetConstString
		invoke _DisplayStatus,eax,2000
		invoke _SetModified,0
	.endif
	xor eax,eax
	ret
_ErrSS:
	mov eax,IDS_ERRSAVE
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
	xor eax,eax
	ret
_SaveScript endp

;
_SaveAs proc
	LOCAL @fi:_FileInfo
	LOCAL @szStr[MAX_STRINGLEN]:byte
	lea eax,@szStr
	mov word ptr [eax],0
	mov eax,IDS_OPENTITLE3
	invoke _GetConstString	
	invoke _SaveFileDlg,offset szOpenFilter,addr @szStr,dbConf+_Configs.lpInitDir2,eax
	.if eax
		lea edi,@fi
		lea esi,FileInfo2
		mov ecx,sizeof _FileInfo
		rep movsb
		lea eax,@szStr
		mov @fi.lpszName,eax
		invoke CreateFileW,@fi.lpszName,GENERIC_WRITE or GENERIC_READ,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
		.if eax==-1
			mov eax,IDS_CANTOPENFILE
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
			jmp _ExSA
		.endif
		mov @fi.hFile,eax
		
		invoke _SaveFile,addr @fi
		or eax,eax
		jne _ErrSA
		mov eax,IDS_SUCSAVE
		INVOKE _GetConstString
		invoke _DisplayStatus,eax,2000
	.endif
_ExSA:
	xor eax,eax
	ret
_ErrSA:
	mov eax,IDS_ERRSAVE
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
	jmp _ExSA
_SaveAs endp

;
_CloseScript proc
	cmp bOpen,0
	je _ExCSC
	.if bModified
		invoke _SaveOrNot
		.if eax==IDYES
			invoke _SaveFile,offset FileInfo2
			or eax,eax
			je @F
			mov eax,IDS_ERRSAVE
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
			jmp _Ex2CSC
		.endif
		cmp eax,IDCANCEL
		je _Ex2CSC
	.endif
	invoke _WriteRec
	@@:
	.if lpMarkTable
		invoke HeapFree,hGlobalHeap,0,lpMarkTable
		mov lpMarkTable,0
	.endif
	.if lpDisp2Real
		invoke HeapFree,hGlobalHeap,0,lpDisp2Real
		mov lpDisp2Real,0
	.endif
	.if lpModifyTable
		invoke HeapFree,hGlobalHeap,0,lpModifyTable
		mov lpModifyTable,0
	.endif
	invoke SendMessageW,hList1,LB_RESETCONTENT,0,0
	invoke SendMessageW,hList2,LB_RESETCONTENT,0,0
	invoke InvalidateRect,hWinMain,0,TRUE
	invoke _ClearAll,offset FileInfo1
	invoke _ClearAll,offset FileInfo2
	invoke SendMessageW,hEdit1,WM_SETTEXT,0,offset szNULL
	invoke SendMessageW,hEdit2,WM_SETTEXT,0,offset szNULL
	invoke SetFocus,hList1
	invoke _SetModified,0
	invoke _SetOpenState,0
	mov nCurIdx,-1
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,64
	or eax,eax
	je _ExCSC
	push eax
	invoke _GenWindowTitle,eax,GWT_VERSION
	invoke SetWindowTextW,hWinMain,[esp]
	push 0
	push hGlobalHeap
	call HeapFree
_ExCSC:
	xor eax,eax
	ret
_Ex2CSC:
	or eax,-1
	ret
_CloseScript endp

;
_SetCode proc
	invoke DialogBoxParamW,hInstance,IDD_CODE,hWinMain,offset _WndCodeProc,0
	ret
_SetCode endp


_WndCodeProc proc uses edi esi ebx hwnd,uMsg,wParam,lParam
	LOCAL @lpMelInfo2
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if ax==IDC_CODE_OK
			invoke _GetMelInfo2,nCurMel
			mov @lpMelInfo2,eax
			invoke SendDlgItemMessageW,hwnd,IDC_CODE_OPEN1,CB_GETCURSEL,0,0
			mov ecx,dword ptr [eax*4+dbCodeTable]
			mov ebx,FileInfo1.nCharSet
			.if ecx!=ebx
				mov FileInfo1.nCharSet,ecx
				mov eax,@lpMelInfo2
				.if _MelInfo2.nCharacteristic[eax] & MIC_NOPREREAD
					mov ecx,TRUE
				.else
					mov ecx,FALSE
				.endif
				invoke _RecodeFile,offset FileInfo1,FALSE,ecx
				.if eax
					.if eax==E_FATALERROR
						mov bModified,0
						invoke _CloseScript
						mov eax,IDS_CODEFAILED
						invoke _GetConstString
						invoke MessageBoxW,hwnd,eax,0,MB_OK or MB_ICONERROR
						jmp _ExitWCP
					.endif
					mov FileInfo1.nCharSet,ebx
				.endif
			.endif
			invoke SendDlgItemMessageW,hwnd,IDC_CODE_OPEN2,CB_GETCURSEL,0,0
			mov ecx,dword ptr [eax*4+dbCodeTable]
			mov ebx,FileInfo2.nCharSet
			.if ecx!=ebx
				mov FileInfo2.nCharSet,ecx
				mov eax,@lpMelInfo2
				.if _MelInfo2.nCharacteristic[eax] & MIC_NOPREREAD
					mov ecx,TRUE
				.else
					mov ecx,FALSE
				.endif
				invoke _RecodeFile,offset FileInfo2,FALSE,ecx
				.if eax
					.if eax==E_FATALERROR
						mov bModified,0
						invoke _CloseScript
						mov eax,IDS_CODEFAILED
						invoke _GetConstString
						invoke MessageBoxW,hwnd,eax,0,MB_OK or MB_ICONERROR
						jmp _ExitWCP
					.endif
					mov FileInfo1.nCharSet,ebx
					mov eax,IDS_FAILCONVERT
					invoke _GetConstString
					invoke MessageBoxW,hwnd,eax,0,MB_OK or MB_ICONEXCLAMATION
					jmp _ExWCP
				.endif
			.endif
			invoke SendDlgItemMessageW,hwnd,IDC_CODE_SAVE2,CB_GETCURSEL,0,0
			mov ecx,dword ptr [eax*4+dbCodeTable]
			mov esi,FileInfo2.nCharSet
			.if ecx!=esi
				mov FileInfo2.nCharSet,ecx
				xor ebx,ebx
				xor edi,edi
				.while ebx<FileInfo2.nLine
					push ebx
					push offset FileInfo2
					call dbSimpFunc+_SimpFunc.ModifyLine
					or edi,eax
					inc ebx
				.endw
				.if edi
					mov FileInfo2.nCharSet,esi
					mov eax,IDS_FAILCONVERT
					invoke _GetConstString
					invoke MessageBoxW,hwnd,eax,0,MB_OK or MB_ICONEXCLAMATION
					jmp _ExWCP
				.endif
			.endif 
			invoke InvalidateRect,hList1,0,TRUE
			invoke InvalidateRect,hList2,0,TRUE
			invoke SendMessageW,hList1,LB_GETCURSEL,0,1
			.if eax<FileInfo1.nLine
				invoke _SetTextToEdit,eax
			.endif
			jmp _ExitWCP
		.elseif ax==IDC_CODE_CANCEL
_ExitWCP:
			invoke EndDialog,hwnd,0
		.endif
	.elseif eax==WM_INITDIALOG
		invoke GetDlgItem,hwnd,IDC_CODE_OPEN1
		invoke _AddCodeCombo,eax
		invoke GetDlgItem,hwnd,IDC_CODE_OPEN2
		invoke _AddCodeCombo,eax
		invoke GetDlgItem,hwnd,IDC_CODE_SAVE2
		invoke _AddCodeCombo,eax
		.if bOpen
			invoke _GetCodeIndex,FileInfo1.nCharSet
			invoke SendDlgItemMessageW,hwnd,IDC_CODE_OPEN1,CB_SETCURSEL,eax,0
			invoke _GetCodeIndex,FileInfo2.nCharSet
			mov ebx,eax
			invoke SendDlgItemMessageW,hwnd,IDC_CODE_OPEN2,CB_SETCURSEL,eax,0
			invoke SendDlgItemMessageW,hwnd,IDC_CODE_SAVE2,CB_SETCURSEL,ebx,0
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hwnd,0
	.endif
_ExWCP:
	xor eax,eax
	ret
_WndCodeProc endp

;
_ExportTxt proc
	LOCAL @szStr[MAX_STRINGLEN]:byte
	LOCAL @hTxtFile
	
	invoke lstrcpyW,addr @szStr,FileInfo2.lpszName
	invoke _DirModifyExtendName,addr @szStr,offset szTxt
	
	mov eax,IDS_EXPORTTXT
	invoke _GetConstString
	invoke _SaveFileDlg,offset szTxtFilter,addr @szStr,dbConf+_Configs.lpInitDir2,eax
	.if eax
		invoke CreateFileW,addr @szStr,GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
		.if eax==-1
			mov eax,IDS_CANTOPENFILE
_ErrET:
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
			jmp _ExET
		.endif
		mov @hTxtFile,eax
		invoke _ExportSingleTxt,offset FileInfo2,@hTxtFile
		mov ebx,eax
		invoke CloseHandle,@hTxtFile
		.if ebx
			mov eax,IDS_FAILEXPORT
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
			
			jmp _ExET
		.endif
		
		mov eax,IDS_SUCEXPORT
		invoke _GetConstString
		invoke _DisplayStatus,eax,2000
	.endif
_ExET:
	xor eax,eax
	ret
_ExportTxt endp

;
_ExportSingleTxt proc uses esi edi ebx _lpFI,_hTxt
	LOCAL @lpBuff,@nLine
	mov ecx,_lpFI
	assume ecx:ptr _FileInfo
	mov eax,[ecx].nStreamSize
	shl eax,1
	invoke VirtualAlloc,0,eax,MEM_COMMIT,PAGE_READWRITE
	.if !eax
		mov eax,E_NOMEM
		jmp _ExEST
	.endif
	mov @lpBuff,eax
	
	mov edi,@lpBuff
	mov ax,0feffh
	stosw
	xor ebx,ebx
	mov ecx,_lpFI
	mov eax,[ecx].nLine
	mov @nLine,eax
	.if [ecx].nMemoryType==MT_EVERYSTRING || [ecx].nMemoryType==MT_POINTERONLY
		mov esi,[ecx].lpTextIndex
		.while ebx<@nLine
			invoke _IsDisplay,ebx
			or eax,eax
			je @F
			invoke lstrcpyW,edi,[esi]
			invoke lstrlenW,[esi]
			shl eax,1
			add edi,eax
			mov eax,0a000dh
			stosd
			@@:
			add esi,4
			inc ebx
		.endw
	.else
		mov eax,E_INVALIDPARAMETER
		jmp _ExEST
	.endif
	sub edi,@lpBuff
	invoke SetFilePointer,_hTxt,0,0,FILE_BEGIN
	invoke WriteFile,_hTxt,@lpBuff,edi,offset dwTemp,0
	mov ebx,eax
	invoke VirtualFree,@lpBuff,0,MEM_RELEASE
	invoke SetEndOfFile,_hTxt
	or ebx,ebx
	je _ErrEST
	assume ecx:nothing
	xor eax,eax
_ExEST:
	ret
_ErrEST:
	or eax,E_ERROR
	ret
_ExportSingleTxt endp

_ImportSingleTxt proc uses esi edi ebx _lpFI,_lpTxt,_bFilterOn
	local @nLineTxt
	mov esi,_lpTxt
	.if word ptr [esi]!=0feffh
		mov eax,E_WRONGFORMAT
		jmp _Ex
	.endif
	
	add esi,2
	xor ecx,ecx
	.while word ptr [esi]
		.if dword ptr [esi]==0a000dh
			mov dword ptr [esi],0
			add esi,4
			inc ecx
			.continue
		.endif
		add esi,2
	.endw
	lea ebx,[ecx+1]

	mov esi,lpMarkTable
	.if !_bFilterOn
		mov ecx,_lpFI
		mov edx,_FileInfo.nLine[ecx]
	.else
		mov edx,_lpFI
		mov ecx,_FileInfo.nLine[edx]
		xor edx,edx
		@@:
			.if !(byte ptr [esi]&2)
				inc edx
			.endif
			inc esi
		loop @B
	.endif
	.if edx>ebx
		mov eax,E_LINENOTMATCH
		jmp _Ex
	.endif
	
	mov @nLineTxt,ebx
	
	mov esi,_lpFI
	assume esi:ptr _FileInfo
	mov eax,[esi].nMemoryType
	.if eax==MT_EVERYSTRING || eax==MT_POINTERONLY
		xor ebx,ebx
		mov edi,_lpTxt
		add edi,2
		.while ebx<[esi].nLine
			.if _bFilterOn
				invoke _IsDisplay,ebx
				or eax,eax
				je _NextLine2
			.endif
			mov eax,[esi].lpTextIndex
			mov ecx,[eax+ebx*4]
			mov dword ptr [eax+ebx*4],0
			invoke HeapFree,hGlobalHeap,0,ecx
			xor ax,ax
			push edi
			or ecx,-1
			repne scasw
			add edi,2
			not ecx
			shl ecx,1
			invoke HeapAlloc,hGlobalHeap,0,ecx
			.if !eax
				add esp,4
				mov eax,E_NOMEM
				jmp _Ex
			.endif
			mov ecx,[esi].lpTextIndex
			mov [ecx+ebx*4],eax
			push eax
			call lstrcpyW
		_NextLine2:
			inc ebx
		.endw
	.else
		mov eax,E_PLUGINERROR
		jmp _Ex
	.endif
	assume esi:nothing
	
	xor eax,eax
_Ex:
	ret
_ImportSingleTxt endp

;
_ImportTxt proc
	LOCAL @lpStr
	LOCAL @hTxtFile,@lpBuff,@pEnd,@nFlag
	local @nFZ:LARGE_INTEGER
	
	mov eax,IDS_IMPORTTXT
	invoke _GetConstString
	invoke _OpenFileDlg,offset szTxtFilter,addr @lpStr,dbConf+_Configs.lpInitDir2,eax,0
	.if eax
		invoke CreateFileW,@lpStr,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		.if eax==-1
			mov eax,IDS_CANTOPENFILE
_ErrIT:
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
			invoke HeapFree,hGlobalHeap,0,@lpStr
			jmp _ExIT
		.endif
		mov @hTxtFile,eax
		invoke HeapFree,hGlobalHeap,0,@lpStr
		invoke GetFileSizeEx,@hTxtFile,addr @nFZ
		invoke VirtualAlloc,0,dword ptr @nFZ,MEM_COMMIT,PAGE_READWRITE
		.if !eax
_NomemIT:
			invoke CloseHandle,@hTxtFile
			mov eax,IDS_NOMEM
			jmp _ErrIT
		.endif
		mov @lpBuff,eax
		invoke ReadFile,@hTxtFile,@lpBuff,dword ptr @nFZ,offset dwTemp,0
		
		invoke _ImportSingleTxt,offset FileInfo2,@lpBuff,TRUE
		.if !eax
			xor ebx,ebx
			.while ebx<FileInfo2.nLine
				invoke _IsDisplay,ebx
				or eax,eax
				je _NextIT
				push ebx
				push offset FileInfo2
				call dbSimpFunc+_SimpFunc.ModifyLine
				.if eax
					mov eax,IDS_FAILIMPORT
					invoke _GetConstString
					invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
					jmp _ExIT
				.endif
			_NextIT:
				inc ebx
			.endw
		.else
			cmp eax,E_NOMEM
			JE _NomemIT
			.if eax==E_WRONGFORMAT
				mov eax,IDS_TXTUNICODE
				jmp _ErrIT
			.endif
			.if eax==E_PLUGINERROR
				mov eax,IDS_DLLERR
				jmp _ErrIT
			.endif
			.if eax==E_LINENOTMATCH
				mov eax,IDS_LINENOTMATCH
				jmp _ErrIT
			.endif
			
		.endif
		
		invoke CloseHandle,@hTxtFile
		invoke InvalidateRect,hWinMain,0,TRUE
		invoke _SetModified,1
	.endif
_ExIT:
	xor eax,eax
	ret
_ImportTxt endp

;
_Exit proc
	invoke SendMessageW,hWinMain,WM_CLOSE,0,0
	ret
_Exit endp
