
VT_PRODUCTNAME		EQU		1
VT_PRODUCTVER			EQU		2
VT_FILEDESC				EQU		3
VT_FORMAT				EQU		4

.data
	TW0		'\\StringFileInfo',		szVerStringInfo
	TW0		'\\080404B0',			szVerLangCH
	TW0		'\\ProductName',		szVerProductName
	TW0		'\\ProductVersion',		szVerProductVer
	TW0		'\\FileDescription',		szVerFileDesc
	TW0		'\\Format',			szVerFormat
	TW0		'Undefined',			szUndefined

.code

;选择插件对话框
;返回值：与_TryMatch相同
_WndCMProc proc uses ebx edi esi,hwnd,uMsg,wParam,lParam
	LOCAL @pStr
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if ax==IDC_CM_MELLIST
			shr eax,16
			.if ax==LBN_SELCHANGE
				invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
				or eax,eax
				je _ExWCMP
				mov @pStr,eax
				invoke SendMessageW,lParam,LB_GETCURSEL,0,0
				invoke SendMessageW,lParam,LB_GETITEMDATA,eax,0
				cmp eax,-1
				je @F
				mov edx,sizeof _MelInfo
				mul edx
				add eax,lpMels
				@@:
				mov ebx,eax
				invoke _GetMelInfo,ebx,@pStr,VT_PRODUCTNAME
				invoke SendDlgItemMessageW,hwnd,IDC_CM_MELNAME,WM_SETTEXT,0,@pStr
				invoke _GetMelInfo,ebx,@pStr,VT_PRODUCTVER
				invoke SendDlgItemMessageW,hwnd,IDC_CM_VER,WM_SETTEXT,0,@pStr
				invoke _GetMelInfo,ebx,@pStr,VT_FORMAT
				invoke SendDlgItemMessageW,hwnd,IDC_CM_FORMAT,WM_SETTEXT,0,@pStr
				invoke _GetMelInfo,ebx,@pStr,VT_FILEDESC
				invoke SendDlgItemMessageW,hwnd,IDC_CM_DESC,WM_SETTEXT,0,@pStr
				invoke HeapFree,hGlobalHeap,0,@pStr
			.endif
		.elseif ax==IDC_CM_OK
			invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_GETCURSEL,0,0
			invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_GETITEMDATA,eax,0
			mov ebx,eax
			invoke SendDlgItemMessageW,hwnd,IDC_CM_REM,BM_GETCHECK,0,0
			.if eax==BST_CHECKED
				mov eax,ebx
				mov edx,sizeof _MelInfo
				mul edx
				add eax,lpMels
				mov dbConf+_Configs.lpDefaultMel,eax
			.endif
			invoke EndDialog,hwnd,ebx
		.elseif ax==IDCANCEL
			invoke EndDialog,hwnd,-2
		.endif
	.elseif eax==WM_INITDIALOG
;		invoke GetDlgItem,hwnd,IDC_CM_MELLIST
;		invoke EnableWindow,eax,FALSE
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
		.if !eax
			invoke EndDialog,hwnd,-3
		.endif
		mov @pStr,eax
		invoke _GetMelInfo,-1,@pStr,VT_PRODUCTNAME
		invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_ADDSTRING,0,@pStr
		invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_SETITEMDATA,eax,-1
		.if lParam
			mov esi,lParam
			.while dword ptr [esi]!=-1
				lodsd
				mov edx,sizeof _MelInfo
				mul dx
				add eax,lpMels
				invoke _GetMelInfo,eax,@pStr,VT_PRODUCTNAME
				invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_ADDSTRING,0,@pStr
				invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_SETITEMDATA,eax,[esi-4]
			.endw
		.else
			mov esi,lpMels
			xor ebx,ebx
			.while ebx<nMels
				invoke _GetMelInfo,esi,@pStr,VT_PRODUCTNAME
				invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_ADDSTRING,0,@pStr
				lea ecx,[eax-1]
				invoke SendDlgItemMessageW,hwnd,IDC_CM_MELLIST,LB_SETITEMDATA,eax,ecx
				add esi,sizeof _MelInfo
				inc ebx
			.endw
		.endif
		invoke HeapFree,hGlobalHeap,0,@pStr
	.elseif eax==WM_CLOSE
		invoke EndDialog,hwnd,-2
	.endif
_ExWCMP:
	xor eax,eax
	ret
_WndCMProc endp

;
_GetMelInfo proc uses esi ebx _lpMel,_lpszTitle,_nType
	LOCAL @lpVer,@puLen,@pStr,@pMelPath
	LOCAL @szResType[128]:byte
	.if _lpMel==-1
		mov eax,_nType
		add eax,IDS_INNERNAME-VT_PRODUCTNAME
		invoke _GetConstString
		invoke lstrcpyW,_lpszTitle,eax
		ret
	.endif
	mov esi,_lpMel
	assume esi:ptr _MelInfo
	invoke lstrlenW,lpszImagePath
	shl eax,1
	add eax,SHORT_STRINGLEN+12
	invoke HeapAlloc,hGlobalHeap,0,eax
	test eax,eax
	jz _FileNameGMT
	mov @pMelPath,eax
	invoke lstrcpyW,eax,lpszImagePath
	invoke lstrcatW,@pMelPath,offset szDLLDir2
	invoke lstrcatW,@pMelPath,addr [esi].szName
	invoke GetFileVersionInfoSizeW,@pMelPath,0
	.if !eax
_FreeGMI:
		invoke HeapFree,hGlobalHeap,0,@pMelPath
		jmp _FileNameGMT
	.endif
	
	mov ebx,eax
	invoke HeapAlloc,hGlobalHeap,0,eax
	test eax,eax
	jz _FreeGMI
	mov @lpVer,eax
	invoke GetFileVersionInfoW,@pMelPath,0,ebx,@lpVer
	mov ebx,eax
	invoke HeapFree,hGlobalHeap,0,@pMelPath
	.if !eax
		invoke HeapFree,hGlobalHeap,0,@lpVer
		jmp _FileNameGMT
	.endif
	
	assume esi:nothing
	
	lea ebx,@szResType
	invoke lstrcpyW,ebx,offset szVerStringInfo
	invoke lstrcatW,ebx,offset szVerLangCH
	mov ecx,_nType
	.if ecx==VT_PRODUCTNAME
		invoke lstrcatW,ebx,offset szVerProductName
	.elseif ecx==VT_PRODUCTVER
		invoke lstrcatW,ebx,offset szVerProductVer
	.elseif ecx==VT_FILEDESC
		invoke lstrcatW,ebx,offset szVerFileDesc
	.elseif ecx==VT_FORMAT
		invoke lstrcatW,ebx,offset szVerFormat
	.endif
	invoke VerQueryValueW,@lpVer,addr @szResType,addr @pStr,addr @puLen
	mov ebx,eax
	invoke HeapFree,hGlobalHeap,0,@lpVer
	test ebx,ebx
	jz _FileNameGMT
	invoke lstrcpyW,_lpszTitle,@pStr
	ret
_FileNameGMT:
	.if word ptr [esi]
		invoke lstrcpyW,_lpszTitle,esi
	.else
		invoke lstrcpyW,_lpszTitle,offset szUndefined
	.endif
	ret
_GetMelInfo endp
