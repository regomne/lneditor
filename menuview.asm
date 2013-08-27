.code

;
_SetFont proc
	invoke DialogBoxParamW,hInstance,IDD_FONT,hWinMain,offset _WndFontProc,0
	ret
_SetFont endp

;
_WndFontProc proc uses ebx edi esi,hwnd,uMsg,wParam,lParam
	LOCAL @cf:CHOOSEFONT
	LOCAL @cc:CHOOSECOLOR
	LOCAL @custcolor[16]:COLORREF
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if eax==IDC_FONT_LISTF
			lea esi,dbConf+_Configs.listFont
			lea ebx,hFontList
			@@:
			lea edi,@cf
			mov ecx,sizeof @cf
			xor eax,eax
			rep stosb
			mov @cf.lStructSize,sizeof @cf
			mov @cf.lpLogFont,esi
			mov @cf.Flags,CF_TTONLY or CF_INITTOLOGFONTSTRUCT or CF_NOVERTFONTS or CF_SCREENFONTS
			invoke ChooseFontW,addr @cf
			.if eax
				invoke CreateFontIndirectW,esi
				.if eax
					mov [ebx],eax
					.if ebx==offset hFontEdit
						mov ebx,eax
						invoke SendMessageW,hEdit1,WM_SETFONT,ebx,FALSE
						invoke SendMessageW,hEdit2,WM_SETFONT,ebx,FALSE
					.endif
					jmp _RefreshWFP
				.endif
			.endif
		.elseif eax==IDC_FONT_EDITF
			lea esi,dbConf+_Configs.editFont
			lea ebx,hFontEdit
			jmp @B
		.elseif eax==IDC_FONT_LISTCD
			lea esi,dbConf+_Configs.TextColorDefault
			@@:
			lea edi,@cc
			mov ecx,sizeof @cc
			xor eax,eax
			rep stosb
			lea edi,@custcolor
			mov ecx,16
			mov eax,0ffffffh
			rep stosd
			mov eax,[esi]
			mov @cc.rgbResult,eax
			mov @cc.lStructSize,sizeof @cc
			mov eax,hwnd
			mov @cc.hwndOwner,eax
			lea eax,@custcolor
			mov @cc.lpCustColors,eax 
			mov @cc.Flags,CC_FULLOPEN or CC_RGBINIT
			invoke ChooseColorW,addr @cc
			.if eax
				mov eax,@cc.rgbResult
				mov [esi],eax
_RefreshWFP:
				invoke SendMessageW,hList1,WM_SETREDRAW,FALSE,0
				invoke SendMessageW,hList2,WM_SETREDRAW,FALSE,0
				mov ebx,FileInfo1.nLine
				.while ebx
					invoke _CalHeight,ebx
					push eax
					invoke SendMessageW,hList1,LB_SETITEMHEIGHT,ebx,eax
					push ebx
					push LB_SETITEMHEIGHT
					push hList2
					call SendMessageW
					dec ebx
				.endw
				invoke SendMessageW,hList1,WM_SETREDRAW,TRUE,0
				invoke SendMessageW,hList2,WM_SETREDRAW,TRUE,0
				invoke InvalidateRect,hList1,0,TRUE
				invoke InvalidateRect,hList2,0,TRUE
				invoke InvalidateRect,hEdit1,0,TRUE
				invoke InvalidateRect,hEdit2,0,TRUE
			.endif
		.elseif eax==IDC_FONT_LISTCS
			lea esi,dbConf+_Configs.TextColorSelected
			jmp @B
		.elseif eax==IDC_FONT_EDITC
			lea esi,dbConf+_Configs.TextColorEdit
			jmp @B
		.elseif eax==IDCANCEL
			invoke EndDialog,hwnd,0
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hwnd,0
	.endif
	xor eax,eax
	ret
_WndFontProc endp

;
_SetBackground proc
	LOCAL @lpStr
	mov eax,IDS_SELECTBKGND
	invoke _GetConstString
	invoke _OpenFileDlg,offset szImageFilter,addr @lpStr,offset szNULL,eax,0
	or eax,eax
	je _ExSBG
	invoke lstrcpyW,dbConf+_Configs.lpBackName,@lpStr
	invoke HeapFree,hGlobalHeap,0,@lpStr
	invoke DeleteDC,hBackDC
	invoke DeleteObject,hBackBmp
	mov hBackDC,0
	invoke RedrawWindow,hWinMain,0,0,RDW_ERASE or RDW_INVALIDATE
_ExSBG:
	ret
_SetBackground endp

;
_CustomUI proc
	invoke _Dev
	ret
_CustomUI endp

;
_RecoverUI proc
	invoke _Dev
	ret
_RecoverUI endp
