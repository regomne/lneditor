
.data?
	_BrowseFolderTmp dd ?
.const
;	_szDirInfo db 'ÇëÑ¡ÔñÄ¿Â¼£º',0
	TW0		'Please Select Directory:',	_szDirInfo

.code

_BrowseFolderCallBack proc hwnd,uMsg,lParam,lpData
	local @szBuffer[MAX_STRINGLEN]:byte
	mov eax,uMsg
	.if eax==BFFM_INITIALIZED
		invoke SendMessageW,hwnd,BFFM_SETSELECTIONW,TRUE,_BrowseFolderTmp
	.elseif eax==BFFM_SELCHANGED
		invoke SHGetPathFromIDListW,lParam,addr @szBuffer
		invoke SendMessageW,hwnd,BFFM_SETSTATUSTEXTW,0,addr @szBuffer
	.endif
	xor eax,eax
	ret
_BrowseFolderCallBack endp
;
_BrowseFolder proc _hwnd,_lpszBuffer
	local @stBrowseInfo:BROWSEINFO
	local @stMalloc
	local @pidlParent,@dwReturn
	
	pushad
	invoke CoInitialize,NULL
	invoke SHGetMalloc,addr @stMalloc
	.if eax==E_FAIL
		mov @dwReturn,FALSE
		jmp @F
	.endif
	invoke RtlZeroMemory,addr @stBrowseInfo,sizeof @stBrowseInfo
	push _hwnd
	pop @stBrowseInfo.hwndOwner
	push _lpszBuffer
	pop _BrowseFolderTmp
	mov @stBrowseInfo.lpfn,offset _BrowseFolderCallBack
	mov @stBrowseInfo.lpszTitle,offset _szDirInfo
	mov @stBrowseInfo.ulFlags,BIF_RETURNONLYFSDIRS OR BIF_STATUSTEXT
	invoke SHBrowseForFolderW,addr @stBrowseInfo
	mov @pidlParent,eax
	.if eax!=NULL
		invoke SHGetPathFromIDListW,eax,_lpszBuffer
		mov eax,TRUE
	.else
		mov eax,FALSE
	.endif
	
	mov @dwReturn,eax
	mov eax,@stMalloc
	mov eax,[eax]
	invoke (IMalloc ptr [eax]).Free,@stMalloc,@pidlParent
	mov eax,@stMalloc
	mov eax,[eax]
	invoke (IMalloc ptr [eax]).Release,@stMalloc
	
	@@:
	invoke CoUninitialize
	popad
	mov eax,@dwReturn
	ret
_BrowseFolder endp