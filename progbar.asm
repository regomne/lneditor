.data?
bProgBarStopping1		dd		?
bProgBarStopping2		dd		?
nProgBarLine				dd		?
hProgBarWindow			dd		?

.code

_TimerThreadPB proc _lparam
	.while !bProgBarStopping2 && hProgBarWindow
		invoke Sleep,200
		invoke SendDlgItemMessageW,hProgBarWindow,IDC_PRBAR_BAR,PBM_SETPOS,nProgBarLine,0
	.endw
	ret
_TimerThreadPB endp

_WndProgBarProc proc uses edi esi ebx hwnd,uMsg,wParam,lParam
	mov eax,uMsg
	.if eax==WM_COMMAND
		.if wParam==IDC_PRBAR_STOP
			mov bProgBarStopping1,1
			mov bProgBarStopping2,1
			invoke EndDialog,hwnd,0
		.endif
	.elseif eax==WM_INITDIALOG
		mov eax,hwnd
		mov hProgBarWindow,eax
		mov esi,lParam
		.if esi
			.if !_ProgBarInfo.bNoStop[esi]
				invoke SendDlgItemMessageW,hwnd,IDC_PRBAR_STOP,WM_ENABLE,FALSE,0
			.endif
			.if _ProgBarInfo.lpszTitle[esi]
				invoke SetWindowTextW,hwnd,_ProgBarInfo.lpszTitle[esi]
			.endif
		.endif
		.if bProgBarStopping1
			invoke EndDialog,hwnd,0
		.endif
		invoke CreateThread,0,0,offset _TimerThreadPB,0,0,0
	.elseif eax==WM_DESTROY
		mov hProgBarWindow,0
	.endif
	xor eax,eax
	ret
_WndProgBarProc endp