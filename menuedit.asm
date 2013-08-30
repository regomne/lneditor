.code

;
_Undo proc
	invoke _Dev
	ret
_Undo endp

;
_Redo proc
	invoke _Dev
	ret
_Redo endp

;
_Modify proc
	LOCAL @pStr,@nLen,@lpTemp,@nTmp,@bIsAllocated
	invoke GetWindowTextLengthW,hEdit2
	shl eax,1
	mov @bIsAllocated,eax
	.if !eax
		mov @nLen,2
		mov @pStr,offset szDLLDir+6	;'\0'
		jmp @F
	.endif
	mov @nLen,eax
	shl eax,1
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
	or eax,eax
	je _NomemML
	mov @pStr,eax
	
	invoke GetWindowTextW,hEdit2,@pStr,@nLen
	mov eax,dbSimpFunc+_SimpFunc.RetLine
	.if eax
		push @pStr
		call eax
		.if eax
			mov eax,IDS_DECLINEMOD
			invoke _GetConstString
			invoke MessageBoxW,hWinMain,eax,0,MB_ICONERROR
			jmp _ExML
		.endif
	.endif
	@@:
	invoke SendMessageW,hList2,LB_GETCURSEL,0,1
	cmp eax,-1
	je _ExML
	invoke _ModifyStringInList,offset FileInfo2,eax,@pStr
	mov ebx,eax
	.if @bIsAllocated
		invoke HeapFree,hGlobalHeap,0,@pStr
	.endif
	.if ebx
		mov eax,IDS_STRTOOLONG
		invoke _GetConstString
		invoke MessageBoxW,hWinMain,eax,NULL,MB_OK or MB_ICONERROR
		jmp _ExML
	.endif
	
	invoke SendMessageW,hList2,LB_GETCURSEL,0,1
	mov ebx,eax
	push eax
	push offset FileInfo2
	call dbSimpFunc+_SimpFunc.ModifyLine
	.if eax
		mov eax,IDS_DECLINEMOD
		invoke _GetConstString
		invoke MessageBoxW,hWinMain,eax,NULL,MB_OK OR MB_ICONERROR
		jmp _ExML
	.endif
	
	;使下一行置中
	invoke _NextLineWithCenter

	invoke _SetModified,1
	mov edi,lpModifyTable
	.if edi
		invoke SendMessageW,hList2,LB_GETCURSEL,0,0
		mov byte ptr [eax+edi],1
	.endif
_ExML:
	xor eax,eax
	ret
_NomemML:
	mov eax,IDS_NOMEM
	invoke _GetConstString
	invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
	jmp _ExML
_Modify endp

;
_ModifyStringInList proc uses esi edi ebx _lpFI,_nLine,_lpStr
	LOCAL @nLen,@nTmp,@lpTemp
	invoke _ConvertFA,_lpStr,dbConf+_Configs.nAutoConvert
	mov ebx,_lpFI
	assume ebx:ptr _FileInfo
	invoke lstrlenW,_lpStr
	shl eax,1
	mov @nLen,eax
	MOV ECX,[ebx].nMemoryType
	.if ecx==MT_EVERYSTRING || ecx==MT_POINTERONLY
		mov esi,FileInfo2.lpTextIndex
		mov eax,_nLine
		lea edi,[esi+eax*4]
		mov esi,[edi]
		invoke lstrlenW,esi
		shl eax,1
		.if eax>=@nLen
			invoke lstrcpyW,esi,_lpStr
		.else
			mov ecx,@nLen
;			.if [ebx].nLineLen && ecx<[ebx].nLineLen
;				invoke lstrcpyW,esi,_lpStr
;				xor eax,eax
;				jmp _ExMSIL
;			.endif
			add ecx,2
			invoke HeapAlloc,hGlobalHeap,0,ecx
			or eax,eax
			je _NomemMSIL
			mov [edi],eax
			invoke lstrcpyW,eax,_lpStr
			invoke HeapFree,hGlobalHeap,0,esi
		.endif
	.else
		mov eax,E_INVALIDPARAMETER
		jmp _ExMSIL
	.endif
	assume ebx:nothing
	xor eax,eax
_ExMSIL:
	ret
_NomemMSIL:
	mov eax,E_NOMEM
	ret
_ModifyStringInList endp

;
_PrevLine proc
	invoke SendMessageW,hList2,LB_GETCURSEL,0,0
	mov ebx,eax
	.if ebx
		dec ebx
		invoke _SetLineInListbox,ebx,0
	.endif
	ret
_PrevLine endp

;
_NextLine proc
	invoke SendMessageW,hList2,LB_GETCURSEL,0,0
	mov ebx,eax
	invoke SendMessageW,hList2,LB_GETCOUNT,0,0
	inc ebx
	.if ebx<eax
		invoke _SetLineInListbox,ebx,0
	.endif
	ret
_NextLine endp

_NextLineWithCenter proc uses esi
	mov esi,SendMessageW
	assume esi:ptr arg4
	invoke esi,hList2,LB_GETCURSEL,0,0
	mov ebx,eax
	invoke esi,hList2,LB_GETCOUNT,0,0
	inc ebx
	.if ebx<eax
		invoke esi,hList1,WM_SETREDRAW,FALSE,0
		invoke esi,hList2,WM_SETREDRAW,FALSE,0
		invoke esi,hList1,LB_SETCURSEL,ebx,0
		invoke esi,hList2,LB_SETCURSEL,ebx,0
		invoke esi,hList2,LB_GETTOPINDEX,0,0
		invoke _CalcCenterIndex,eax,ebx
		.if eax!=-1
			invoke _SetListTopIndex,eax
		.endif
		invoke esi,hWinMain,WM_COMMAND,LBN_SELCHANGE*65536+IDC_LIST2,hList2
		assume esi:nothing
	.endif
	ret
_NextLineWithCenter endp

;
_MarkLine proc
	LOCAL @rect:RECT
	invoke SendMessageW,hList2,LB_GETCURSEL,0,1
	mov esi,lpMarkTable
	.if esi
		xor byte ptr [esi+eax],1
		invoke SendMessageW,hList2,LB_GETCURSEL,0,0
		mov ebx,eax
		invoke SendMessageW,hList1,LB_GETITEMRECT,ebx,addr @rect
		invoke InvalidateRect,hList1,addr @rect,TRUE
		invoke SendMessageW,hList2,LB_GETITEMRECT,ebx,addr @rect
		invoke InvalidateRect,hList2,addr @rect,TRUE
	.endif
	ret
_MarkLine endp

;
_PrevMark proc
	invoke SendMessageW,hList2,LB_GETCURSEL,0,1
	mov esi,lpMarkTable
	.if esi
		.repeat
			dec eax
			.if byte ptr [esi+eax] & 1 && !(byte ptr [esi+eax] & 2)
				invoke _SetLineInListbox,eax,1
				jmp @F
			.endif
		.until !eax
	.endif
	@@:
	ret
_PrevMark endp

;
_NextMark proc
	invoke SendMessageW,hList2,LB_GETCURSEL,0,1
	mov esi,lpMarkTable
	mov ebx,FileInfo2.nLine
	dec ebx
	.if esi
		.repeat
			inc eax
			.if byte ptr [esi+eax] &1 && !(byte ptr [esi+eax] & 2)
				invoke _SetLineInListbox,eax,1
				jmp @F
			.endif
		.until eax>=ebx
	.endif
	@@:
	ret
_NextMark endp

_UnmarkAll proc
	mov esi,lpMarkTable
	.if esi
		xor eax,eax
		mov ecx,FileInfo2.nLine
		.while eax<ecx
			and byte ptr [esi+eax],NOT 1
			inc eax
		.endw
		invoke InvalidateRect,hList1,0,TRUE
		invoke InvalidateRect,hList2,0,TRUE
	.endif
	ret
_UnmarkAll endp

;
_ToFull proc
	mov eBx,AC_FULLANGLE
_StartTF:
POSTF	EQU		_StartTF-_ToFull
	.if bOpen
	xor esi,esi
	xor edi,edi
	.while esi<FileInfo2.nLine
		invoke _IsDisplay,esi
		or eax,eax
		je @F
		invoke _GetStringInList,offset FileInfo2,esi
		invoke _ConvertFA,eax,ebx
		push esi
		push offset FileInfo2
		call dbSimpFunc+_SimpFunc.ModifyLine
		or edi,eax
		@@:
		inc esi
	.endw
	invoke _SetModified,1
	invoke InvalidateRect,hList2,0,TRUE
	.if !edi
		mov eax,IDS_SUCCONVERT
	.else
		mov eax,IDS_FAILCONVERT
	.endif
	invoke _GetConstString
	invoke _DisplayStatus,eax,2000
	.endif
	ret
_ToFull endp

;
_ToHalf proc
	mov ebx,AC_HALFANGLE
	mov eax,offset _ToFull+POSTF
	jmp eax
_ToHalf endp

;
_Find proc
	.if FindInfo.hFindWindow
		invoke SetFocus,FindInfo.hFindWindow
		jmp _ExFN
	.endif
	invoke CreateThread,0,0,offset _CreateFindWindow,0,0,0
_ExFN:
	ret
_Find endp

_CreateFindWindow proc _param
	local @stMsg:MSG

	invoke CreateDialogParamW,hInstance,IDD_FIND,0,offset _WndFindProc,0
	.if !eax
		ret
	.endif
	mov FindInfo.hFindWindow,eax
	
	.while TRUE
		invoke GetMessageW,addr @stMsg,NULL,0,0
		.break .if eax==0
		invoke IsDialogMessageW,FindInfo.hFindWindow,addr @stMsg
		.if !eax
			invoke TranslateMessage,addr @stMsg
			invoke DispatchMessageW,addr @stMsg
		.endif
	.endw

	xor eax,eax
	mov FindInfo.hFindWindow,eax
	ret
_CreateFindWindow endp

_WndFindProc proc uses edi esi ebx hwnd,uMsg,wParam,lParam
	LOCAL @nCurIdx,@pStr,@nFindLen,@pFileInfo,@bIsOri
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if eax==EN_CHANGE*65536+IDC_FIND_TEXT
			invoke GetDlgItemTextW,hwnd,IDC_FIND_TEXT,offset FindInfo.szFind,SHORT_STRINGLEN/2
			.if !word ptr [FindInfo.szFind]
				mov esi,FALSE
			.else
				mov esi,TRUE
			.endif
			invoke GetDlgItem,hwnd,IDOK
			invoke EnableWindow,eax,esi
			invoke GetDlgItem,hwnd,IDC_FIND_FINDP
			invoke EnableWindow,eax,esi
		.elseif eax==IDOK
			mov ebx,1
_FindNFN:
			invoke IsDlgButtonChecked,hwnd,IDC_FIND_ORI
			.if eax==BST_CHECKED
				lea eax,FileInfo1
				mov @bIsOri,1
			.else
				lea eax,FileInfo2
				mov @bIsOri,0
			.endif
			mov @pFileInfo,eax
			invoke lstrlenW,offset FindInfo.szFind
			mov @nFindLen,eax
			invoke SendMessageW,hList2,LB_GETCURSEL,0,1
			add eax,ebx
			mov @nCurIdx,eax
			invoke IsDlgButtonChecked,hwnd,IDC_FIND_WILD
			.if eax==BST_CHECKED
				mov eax,@nCurIdx
				.while eax<FileInfo2.nLine && eax!=-1
					mov esi,eax
					invoke _IsDisplay,eax
					or eax,eax
					je @F
					invoke _GetStringInList,@pFileInfo,esi
					invoke _WildcharMatchW,offset FindInfo.szFind,eax
					.if eax
						invoke _SetLineInListbox,@nCurIdx,1
						jmp _ExWFP
					.endif
					@@:
					add @nCurIdx,ebx
					mov eax,@nCurIdx
				.endw
			.else
				mov eax,@nCurIdx
				.while eax<FileInfo2.nLine && eax!=-1
					mov esi,eax
					invoke _IsDisplay,eax
					or eax,eax
					je @F
					invoke _GetStringInList,@pFileInfo,esi
					mov @pStr,eax
					mov esi,eax
					.while word ptr [esi]
						lea edi,FindInfo.szFind
						mov ecx,@nFindLen
						inc ecx
						repe cmpsw
						.if !ecx
							invoke _SetLineInListbox,@nCurIdx,1
							invoke _GetStringInList,@pFileInfo,@nCurIdx
							mov ecx,@pStr
							sub ecx,eax
							shr ecx,1
							mov eax,ecx
							add eax,@nFindLen
							.if @bIsOri
								mov esi,hEdit1
							.else
								mov esi,hEdit2
							.endif
							invoke SendMessageW,esi,EM_SETSEL,ecx,eax
							jmp _ExWFP
						.endif
						add @pStr,2
						mov esi,@pStr
					.endw
					@@:
					add @nCurIdx,ebx
					mov eax,@nCurIdx
				.endw
			.endif
		.elseif eax==IDC_FIND_FINDP
			mov ebx,-1
			jmp _FindNFN
		.elseif EAX==IDCANCEL
			invoke DestroyWindow,hwnd
			invoke PostQuitMessage,0
		.endif
	.elseif eax==WM_ACTIVATE
		.if word ptr wParam==WA_CLICKACTIVE
			invoke SetForegroundWindow,hwnd
		.endif
	.elseif eax==WM_INITDIALOG
		invoke CheckDlgButton,hwnd,IDC_FIND_NEW,BST_CHECKED
		invoke SetForegroundWindow,hwnd
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hwnd
		invoke PostQuitMessage,0
	.endif
_ExWFP:
	xor eax,eax
	ret
_WndFindProc endp

;
_Replace proc
	.if FindInfo.hFindWindow
		invoke SetFocus,FindInfo.hFindWindow
		invoke SetForegroundWindow,FindInfo.hFindWindow
		jmp _ExRPC
	.endif
	invoke CreateThread,0,0,offset _CreateReplaceWindow,0,0,0
_ExRPC:
	ret
_Replace endp

_CreateReplaceWindow proc _param
	local @stMsg:MSG

	invoke CreateDialogParamW,hInstance,IDD_REPLACE,0,offset _WndReplaceProc,0
	.if !eax
		ret
	.endif
	mov FindInfo.hFindWindow,eax
	
	.while TRUE
		invoke GetMessageW,addr @stMsg,NULL,0,0
		.break .if eax==0
		invoke IsDialogMessageW,FindInfo.hFindWindow,addr @stMsg
		.if !eax
			invoke TranslateMessage,addr @stMsg
			invoke DispatchMessageW,addr @stMsg
		.endif
	.endw

	xor eax,eax
	mov FindInfo.hFindWindow,eax
	ret
_CreateReplaceWindow endp

_WndReplaceProc proc uses edi esi ebx hwnd,uMsg,wParam,lParam
	LOCAL @nCurIdx,@pStr,@nFindLen,@pStr2,@nTotal,@nErrTotal
	LOCAL @nstp,@nedp,@pTemp
	LOCAL @rect:RECT
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if eax==EN_CHANGE*65536+IDC_RPC_FIND
			invoke GetDlgItemTextW,hwnd,IDC_RPC_FIND,offset FindInfo.szFind,SHORT_STRINGLEN/2
			.if !word ptr [FindInfo.szFind]
				mov esi,FALSE
			.else
				mov esi,TRUE
			.endif
			invoke GetDlgItem,hwnd,IDC_RPC_FINDN
			invoke EnableWindow,eax,esi
			invoke GetDlgItem,hwnd,IDC_RPC_FINDP
			invoke EnableWindow,eax,esi
			invoke GetDlgItem,hwnd,IDC_RPC_RPCALL
			invoke EnableWindow,eax,esi
		.elseif eax==IDC_RPC_FINDN
			mov ebx,1
_FindNWRP:
			invoke lstrlenW,offset FindInfo.szFind
			mov @nFindLen,eax
			invoke SendMessageW,hList2,LB_GETCURSEL,0,1
			add eax,ebx
			mov @nCurIdx,eax
			.while eax<FileInfo2.nLine && eax!=-1
				mov esi,eax
				invoke _IsDisplay,eax
				or eax,eax
				je _NextLineWRP
				invoke _GetStringInList,offset FileInfo2,esi
				mov @pStr,eax
				mov esi,eax
				.while word ptr [esi]
					lea edi,FindInfo.szFind
					mov ecx,@nFindLen
					inc ecx
					repe cmpsw
					.if !ecx
						invoke _GetStringInList,offset FileInfo2,@nCurIdx
						mov esi,@pStr
						sub esi,eax
						shr esi,1
						mov edi,esi
						add edi,@nFindLen
						invoke _SetLineInListbox,@nCurIdx,1
						invoke SendMessageW,hEdit2,EM_SETSEL,esi,edi
						invoke GetDlgItem,hwnd,IDC_RPC_REPLACE
						invoke EnableWindow,eax,TRUE
						jmp _ExWRP
					.endif
					@@:
					add @pStr,2
					mov esi,@pStr
				.endw
				_NextLineWRP:
				add @nCurIdx,ebx
				mov eax,@nCurIdx
			.endw
		.elseif eax==IDC_RPC_FINDP
			mov ebx,-1
			jmp _FindNWRP
		.elseif eax==IDC_RPC_REPLACE
			invoke GetDlgItemTextW,hwnd,IDC_RPC_RPC,offset FindInfo.szReplace,SHORT_STRINGLEN/2
			invoke SendMessageW,hEdit2,EM_GETSEL,addr @nstp,addr @nedp
			mov eax,@nstp
			cmp eax,@nedp
			je _ExWRP
			invoke SendMessageW,hList2,LB_GETCURSEL,0,1
			mov @nCurIdx,eax
			invoke _GetStringInList,offset FileInfo2,@nCurIdx
			mov ebx,eax
			invoke lstrlenW,eax
			add eax,8
			shl eax,3
			mov esi,eax
			invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
			or eax,eax
			je _ExWRP
			mov @pStr,eax
			mov @pTemp,eax
			shr esi,1
			add @pTemp,esi
			invoke lstrcpyW,@pStr,ebx
			mov eax,@nedp
			shl eax,1
			add eax,@pStr
			invoke lstrcpyW,@pTemp,eax
			mov eax,@nstp
			shl eax,1
			add eax,@pStr
			invoke lstrcpyW,eax,offset FindInfo.szReplace
			invoke lstrcatW,@pStr,@pTemp
			invoke _ModifyStringInList,offset FileInfo2,@nCurIdx,@pStr
			invoke HeapFree,hGlobalHeap,0,@pStr
			push @nCurIdx
			push offset FileInfo2
			call dbSimpFunc+_SimpFunc.ModifyLine
			.if eax
				mov eax,IDS_FAILREPLACE
				invoke _GetConstString
				invoke MessageBoxW,hwnd,eax,0,MB_OK or MB_ICONERROR
				jmp _ExWRP
			.endif
			invoke _SetModified,1
			invoke _GetDispLine,@nCurIdx
			.if eax!=-1
				lea ecx,@rect
				invoke SendMessageW,hList2,LB_GETITEMRECT,eax,ecx
				invoke InvalidateRect,hList2,addr @rect,TRUE
			.endif
			mov ebx,1
			jmp _FindNWRP
		.elseif eax==IDC_RPC_RPCALL
			invoke GetDlgItemTextW,hwnd,IDC_RPC_RPC,offset FindInfo.szReplace,SHORT_STRINGLEN/2
			invoke lstrlenW,offset FindInfo.szFind
			mov @nFindLen,eax
			mov @nCurIdx,0
			xor eax,eax
			mov @nTotal,0
			mov @nErrTotal,0
			.while eax<FileInfo2.nLine
				mov esi,eax
				invoke _IsDisplay,eax
				or eax,eax
				je _NextLine2WRP
				invoke _GetStringInList,offset FileInfo2,esi
				mov @pStr,eax
				mov esi,eax
				.while word ptr [esi]
					lea edi,FindInfo.szFind
					mov ecx,@nFindLen
					inc ecx
					repe cmpsw
					.if !ecx
						invoke _GetStringInList,offset FileInfo2,@nCurIdx
						mov esi,@pStr
						sub esi,eax
						mov @nstp,esi
						mov ebx,eax
						invoke lstrlenW,offset FindInfo.szFind
						shl eax,1
						add eax,esi
						mov @nedp,eax
						invoke lstrlenW,ebx
						add eax,8
						shl eax,3
						mov edi,eax
						invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
						or eax,eax
						je _ExWRP
						mov @pStr2,eax
						mov @pTemp,eax
						shr edi,1
						add @pTemp,edi
						invoke lstrcpyW,@pStr2,ebx
						mov eax,@nedp
						add eax,@pStr2
						invoke lstrcpyW,@pTemp,eax
						mov eax,@nstp
						add eax,@pStr2
						invoke lstrcpyW,eax,offset FindInfo.szReplace
						invoke lstrcatW,@pStr2,@pTemp
						invoke _ModifyStringInList,offset FileInfo2,@nCurIdx,@pStr2
						invoke HeapFree,hGlobalHeap,0,@pStr2
						push @nCurIdx
						push offset FileInfo2
						call dbSimpFunc+_SimpFunc.ModifyLine
						.if !eax
							inc @nTotal
						.else
							inc @nErrTotal
						.endif
						mov eax,@nedp
						sub eax,@nstp
						add @pStr,eax
						jmp @F
					.endif
					add @pStr,2
					@@:
					mov esi,@pStr
				.endw
				_NextLine2WRP:
				inc @nCurIdx
				mov eax,@nCurIdx
			.endw
			invoke _SetModified,1
			invoke InvalidateRect,hList2,0,TRUE
			invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,30
			or eax,eax
			je _ExWRP
			mov ebx,eax
			mov eax,IDS_RPCCOMPLETE
			invoke _GetConstString
			invoke wsprintfW,ebx,eax,@nTotal,@nErrTotal
			mov eax,IDS_WINDOWTITLE
			invoke _GetConstString
			invoke MessageBoxW,hwnd,ebx,eax,MB_OK or MB_ICONINFORMATION
		.elseif EAX==IDCANCEL
			invoke DestroyWindow,hwnd
			invoke PostQuitMessage,0
		.endif
	.elseif eax==WM_ACTIVATE
		.if word ptr wParam==WA_CLICKACTIVE
			invoke SetForegroundWindow,hwnd
		.endif
	.elseif eax==WM_INITDIALOG
		invoke SetForegroundWindow,hwnd
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hwnd
		invoke PostQuitMessage,0
	.endif
_ExWRP:
	xor eax,eax
	ret
_WndReplaceProc endp

;
_SummaryFind proc
	invoke DialogBoxParamW,hInstance,IDD_SUMSEARCH,hWinMain,offset _WndSSProc,0
	ret
_SummaryFind endp

;
_WndSSProc proc uses edi esi ebx hwnd,uMsg,wParam,lParam
	LOCAL @pPath,@pBuff,@hRsltFile
	LOCAL @str[SHORT_STRINGLEN]:byte
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if eax==IDC_SS_TEXT+EN_CHANGE*65536
			invoke SendDlgItemMessageW,hwnd,IDC_SS_TEXT,WM_GETTEXTLENGTH,0,0
			.if eax
				mov ebx,TRUE
			.else
				mov ebx,FALSE
			.endif
			invoke GetDlgItem,hwnd,IDC_SS_SEARCH
			invoke EnableWindow,eax,ebx
		.elseif ax==IDC_SS_SEARCH
			invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
			or eax,eax
			je _ErrWSSP
			mov @pPath,eax
			invoke GetTempPathW,MAX_STRINGLEN/2,eax
			or eax,eax
			je _FreeWSSP
;			invoke _DirCatW,@pPath,offset szSearchResult
			invoke lstrcatW,@pPath,offset szSearchResult
			invoke CreateFileW,@pPath,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
			cmp eax,-1
			je _FreeWSSP
			mov @hRsltFile,eax
			invoke VirtualAlloc,0,100000,MEM_COMMIT,PAGE_READWRITE
			.if !eax
				invoke CloseHandle,@hRsltFile
				jmp _FreeWSSP
			.endif
			mov @pBuff,eax
			invoke GetDlgItemTextW,hwnd,IDC_SS_TEXT,addr @str,SHORT_STRINGLEN/2
			invoke IsDlgButtonChecked,hwnd,IDC_SS_MARK
			.if eax==BST_CHECKED
				mov eax,TRUE
			.else
				mov eax,FALSE
			.endif
			invoke _SummarySearch,addr @str,offset FileInfo2,@pBuff,100000,eax
			invoke WriteFile,@hRsltFile,@pBuff,eax,offset dwTemp,0
			invoke CloseHandle,@hRsltFile
			invoke ShellExecuteW,hwnd,offset szSearchOpen,@pPath,NULL,NULL,SW_SHOW
			invoke VirtualFree,@pBuff,0,MEM_RELEASE
			invoke InvalidateRect,hList1,NULL,TRUE
			invoke InvalidateRect,hList2,NULL,TRUE
_FreeWSSP:
			invoke HeapFree,hGlobalHeap,0,@pPath
		.elseif ax==IDCANCEL
			invoke EndDialog,hwnd,0
		.endif
	.elseif eax==WM_INITDIALOG
		.if !lpMarkTable
			invoke GetDlgItem,hwnd,IDC_SS_MARK
			invoke EnableWindow,eax,FALSE
		.endif
		invoke GetDlgItem,hwnd,IDC_SS_TEXT
		invoke SetFocus,eax
	.elseif eax==WM_CLOSE
		invoke EndDialog,hwnd,0
	.endif
_ExWSSP:
	xor eax,eax
	ret
_ErrWSSP:
	XOR EAX,EAX
	ret
_WndSSProc endp

;
_SummarySearch proc uses esi edi ebx _lpszToFind,_lpFI,_lpRslt,_nSizeRslt,_bMark
	local @nLen,@lpRsltTemp,@nLine
	mov edi,_lpRslt
	mov ax,0feffh
	stosw
	mov @lpRsltTemp,edi
	invoke lstrlenW,_lpszToFind
	inc eax
	mov @nLen,eax
	mov ebx,_lpFI
	assume ebx:ptr _FileInfo
	xor eax,eax
	mov @nLine,eax
	.while eax<[ebx].nLine
		mov esi,eax
		invoke _IsDisplay,eax
		or eax,eax
		je @F
		invoke _GetStringInList,ebx,esi
		mov edi,eax
		mov edx,eax
		.while word ptr [edi]
			mov eax,edi
			mov ecx,@nLen
			mov esi,_lpszToFind
			repe cmpsw
			.if !ecx
				.if _bMark
					mov ecx,lpMarkTable
					.if ecx
						add ecx,@nLine
						or byte ptr [ecx],1
					.endif
				.endif
				invoke _DirFileNameW,ebx
				mov ecx,@nLine
				inc ecx
				invoke wsprintfW,@lpRsltTemp,offset szSearchFormat,eax,ecx,edx
				shl eax,1
				add @lpRsltTemp,eax
				mov eax,@lpRsltTemp
				sub eax,_lpRslt
				cmp eax,_nSizeRslt
				jae _ExSSch
				jmp @f
			.endif
			mov edi,eax
			add edi,2
		.endw
		@@:
		inc @nLine
		mov eax,@nLine
	.endw
	assume ebx:nothing
_ExSSch:
	mov eax,@lpRsltTemp
	sub eax,_lpRslt
	ret
_SummarySearch endp

;
_Gotoline proc
	invoke DialogBoxParamW,hInstance,IDD_GOTO,hWinMain,offset _WndGTProc,0
	ret
_Gotoline endp

_WndGTProc proc uses edi esi ebx hwnd,uMsg,wParam,lParam
	LOCAL @szStr[20]:word
	LOCAL @bIsTranslated
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov ecx,wParam
		.if cx==IDC_GT_LINE
			shr ecx,16
			.if cx==EN_CHANGE
				invoke GetDlgItemTextW,hwnd,IDC_GT_LINE,addr @szStr,10
				invoke GetDlgItem,hwnd,IDC_GT_GOTO
				.if !word ptr [@szStr]
					invoke EnableWindow,eax,FALSE
				.else
					invoke EnableWindow,eax,TRUE
				.endif
			.endif
		.elseif cx==IDC_GT_GOTO
			invoke GetDlgItemInt,hwnd,IDC_GT_LINE,addr @bIsTranslated,FALSE
			.if @bIsTranslated && eax<=FileInfo2.nLine && eax
				dec eax
				invoke _SetLineInListbox,eax,0
				invoke EndDialog,hwnd,0
			.else
				invoke SendDlgItemMessageW,hwnd,IDC_GT_LINE,EM_SETSEL,0,-1
			.endif
		.elseif cx==IDC_GT_CANCEL
			invoke EndDialog,hwnd,0
		.endif
	.elseif eax==WM_INITDIALOG
		invoke SendMessageW,hList1,LB_GETCURSEL,0,0
		lea ebx,[eax+1]
		invoke SendMessageW,hList1,LB_GETCOUNT,0,0
		invoke wsprintfW,addr @szStr,offset szLinesFormat,ebx,eax
		invoke SetDlgItemTextW,hwnd,IDC_GT_TOTAL,addr @szStr
	.elseif eax==WM_CLOSE
		invoke EndDialog,hwnd,0
	.endif
	xor eax,eax
	ret
_WndGTProc endp

_SetLineInListbox proc uses ebx _nLine,_bIsReal
	mov ebx,SendMessageW
	assume ebx:ptr arg4
	invoke ebx,hList1,WM_SETREDRAW,FALSE,0
	invoke ebx,hList2,WM_SETREDRAW,FALSE,0
	invoke ebx,hList1,LB_SETCURSEL,_nLine,_bIsReal
	invoke ebx,hList2,LB_SETCURSEL,_nLine,_bIsReal
	invoke ebx,hWinMain,WM_COMMAND,LBN_SELCHANGE*65536+IDC_LIST2,hList2
	assume ebx:nothing
	ret
_SetLineInListbox endp

_Progress proc
	LOCAL @str[100]:byte
	mov edi,lpModifyTable
	.if edi
		mov ecx,FileInfo1.nLine
		xor edx,edx
		.if bOpen
			@@:
				.if byte ptr [edi+ecx-1]
					inc edx
				.endif
			loop @B
		.endif
	.endif
	mov esi,edx
	invoke GetTickCount
	mov ebx,eax
	sub eax,nStartTime
	xor edx,edx
	mov ecx,60000
	div ecx
	mov ecx,eax
	.if nFileOpenTime
		mov eax,ebx
		sub eax,nFileOpenTime
		xor edx,edx
		mov ebx,60000
		div ebx
		mov ebx,eax
	.else
		xor ebx,ebx
	.endif
	
	mov eax,IDS_LINEMODIFIED
	invoke _GetConstString
	invoke wsprintfW,addr @str,eax,ecx,ebx,esi
	invoke MessageBoxW,hWinMain,addr @str,offset szDisplayName,MB_OK or MB_ICONINFORMATION
	ret
_Progress endp
