
_MyListData struct
	DrawState	dd		?
	IsDcStored	dd		?
	StoredDC	dd		?
	StoredBmp	dd		?
	IsInside		dd		?
	nCurIdx		dd		?
_MyListData ends

DST_MOVEIN EQU 1
DST_BUTTONDOWN EQU 2
DST_NOTHING EQU 3

.data?
	lpOldListProc			dd		?
	lpOldEditProc			dd		?
	hLineNumberFont		dd		?

.code
;创建新的列表框类
_CreateMyList proc uses edi _hInstance
;使用lpOldListProc与_NewListProc两个全局变量
	local @wce:WNDCLASSEX
	LOCAL @lf:LOGFONTW
	lea edi,@lf
	xor al,al
	mov ecx,sizeof @lf
	rep stosb
	invoke lstrcpyW,addr @lf.lfFaceName,$CTW0("Consolas")
	mov @lf.lfHeight,0
	mov @lf.lfWidth,-11
	mov @lf.lfWeight,190h
	mov @lf.lfPitchAndFamily,22h
	
	invoke CreateFontIndirectW,addr @lf
	mov hLineNumberFont,eax

	invoke GetClassInfoExW,NULL,offset szCList,addr @wce
	push @wce.lpfnWndProc
	pop lpOldListProc
	push offset _NewListProc
	pop @wce.lpfnWndProc
	push _hInstance
	pop @wce.hInstance
	mov @wce.lpszClassName,offset szCNewList
	mov @wce.cbSize,sizeof @wce
	or @wce.style,CS_GLOBALCLASS or CS_DBLCLKS
	mov @wce.cbWndExtra,8
	
	invoke RegisterClassExW,addr @wce

	ret
_CreateMyList endp

;
_CreateMyEdit proc _hInstance
;使用lpOldListProc与_NewListProc两个全局变量
	local @wce:WNDCLASSEX

	invoke GetClassInfoExW,NULL,offset szCEdit,addr @wce
	push @wce.lpfnWndProc
	pop lpOldEditProc
	push offset _NewEditProc
	pop @wce.lpfnWndProc
	push _hInstance
	pop @wce.hInstance
	mov @wce.lpszClassName,offset szCNewEdit
	mov @wce.cbSize,sizeof @wce
	or @wce.style,CS_GLOBALCLASS
	mov @wce.cbWndExtra,8
	
	invoke RegisterClassExW,addr @wce

	ret
_CreateMyEdit endp

_SetListTopIndex proc uses esi _nLine
	mov esi,SendMessageW
	assume esi:ptr arg4
	invoke esi,hList1,WM_SETREDRAW,FALSE,0
	invoke esi,hList2,WM_SETREDRAW,FALSE,0
	invoke esi,hList1,LB_SETTOPINDEX,_nLine,0
	invoke esi,hList2,LB_SETTOPINDEX,_nLine,0
	invoke esi,hList1,WM_SETREDRAW,TRUE,0
	invoke esi,hList2,WM_SETREDRAW,TRUE,0
	assume esi:nothing
	invoke RedrawWindow,hList1,0,0,RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW
	invoke RedrawWindow,hList2,0,0,RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW
	ret
_SetListTopIndex endp

_NewListProc proc uses ebx esi edi,hwnd,uMsg,wParam,lParam
	local @hbmp,@hcdc,@rect:RECT,@cx,@cy,@hmdc
	mov eax,uMsg
	.if eax==WM_MOUSEMOVE
		invoke GetWindowLongW,hwnd,4
		mov ebx,eax
		invoke SendMessageW,hwnd,LB_ITEMFROMPOINT,0,lParam
		assume ebx:ptr _MyListData
		cmp eax,[ebx].nCurIdx
		je _ExNLP
		mov edi,eax
		mov eax,[ebx].nCurIdx
		mov @cx,eax
		invoke SendMessageW,hwnd,LB_GETITEMRECT,[ebx].nCurIdx,addr @rect
		mov [ebx].nCurIdx,edi
		invoke InvalidateRect,hwnd,addr @rect,TRUE
		invoke SendMessageW,hwnd,LB_GETITEMRECT,edi,addr @rect
		invoke InvalidateRect,hwnd,addr @rect,TRUE
		
		mov esi,hwnd
		.if esi==hList1
			mov esi,hList2
		.else
			mov esi,hList1
		.endif
		invoke GetWindowLongW,esi,4
		mov ecx,[ebx].nCurIdx
		mov ebx,eax
		mov [ebx].nCurIdx,ecx
		invoke SendMessageW,esi,LB_GETITEMRECT,@cx,addr @rect
		mov [ebx].nCurIdx,edi
		invoke InvalidateRect,esi,addr @rect,TRUE
		invoke SendMessageW,esi,LB_GETITEMRECT,edi,addr @rect
		invoke InvalidateRect,esi,addr @rect,TRUE
		
		
		.if ![ebx].IsInside
			mov [ebx].IsInside,1
			sub esp,sizeof TRACKMOUSEEVENT
			mov esi,esp
			assume esi:ptr TRACKMOUSEEVENT
			mov [esi].cbSize,sizeof TRACKMOUSEEVENT
			mov [esi].dwFlags,TME_LEAVE
			mov eax,hwnd
			mov [esi].hwndTrack,eax
			mov [esi].dwHoverTime,0
			invoke TrackMouseEvent,esi
			assume esi:nothing
			add esp,sizeof TRACKMOUSEEVENT
		.endif
		assume ebx:nothing
		
	.elseif eax==WM_ERASEBKGND
		invoke GetWindowLongW,hwnd,4
		mov ebx,eax
		assume ebx:ptr _MyListData
		.if ![ebx].IsDcStored
			invoke GetClientRect,hwnd,addr @rect
			mov eax,@rect.bottom
			sub eax,@rect.top
			mov @cy,eax
			mov eax,@rect.right
			sub eax,@rect.left
			mov @cx,eax
;			invoke ClientToScreen,hwnd,addr @rect
;			invoke ScreenToClient,hWinMain,addr @rect
;			invoke GetDC,hWinMain
;			mov @hmdc,eax
			
			invoke CreateCompatibleDC,wParam
			mov @hcdc,eax
			invoke CreateCompatibleBitmap,wParam,@cx,@cy
			mov @hbmp,eax
			mov [ebx].StoredBmp,eax
			invoke SelectObject,@hcdc,@hbmp
			mov esi,eax
			invoke BitBlt,@hcdc,0,0,@cx,@cy,wParam,0,0,SRCCOPY
;			invoke SelectObject,@hcdc,esi
;			invoke ReleaseDC,hWinMain,@hmdc
			mov [ebx].IsDcStored,1
			mov eax,@hcdc
			mov [ebx].StoredDC,eax
		.endif
		assume ebx:nothing
		mov eax,TRUE
		ret
	.elseif eax==WM_MOUSEWHEEL
		invoke SendMessageW,hList2,LB_GETTOPINDEX,0,0
		mov ebx,eax
		mov eax,wParam
		test eax,080000000h
		.if ZERO?
			or ebx,ebx
			je _ExNLP
			.if ebx<3
				mov ebx,3
			.endif
			sub ebx,3
		.else
			add ebx,3
		.endif
		invoke _SetListTopIndex,ebx
		xor eax,eax
		ret
	.elseif eax==WM_VSCROLL
		invoke SendMessageW,hList1,WM_SETREDRAW,FALSE,0
		invoke CallWindowProcW,lpOldListProc,hList1,uMsg,wParam,lParam
		invoke SendMessageW,hList1,WM_SETREDRAW,TRUE,0
		invoke RedrawWindow,hList1,0,0,RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW
		
		invoke SendMessageW,hList2,WM_SETREDRAW,FALSE,0
		invoke CallWindowProcW,lpOldListProc,hList2,uMsg,wParam,lParam
		invoke SendMessageW,hList2,WM_SETREDRAW,TRUE,0
		invoke RedrawWindow,hList2,0,0,RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW
		jmp _ExNLP
;			mov bScrolling,FALSE
;		.endif
	.elseif eax==WM_MOUSELEAVE
		invoke GetWindowLongW,hwnd,4
		mov ebx,eax
		assume ebx:ptr _MyListData
		mov [ebx].IsInside,0
		mov eax,[ebx].nCurIdx
		mov @cx,eax
		invoke SendMessageW,hwnd,LB_GETITEMRECT,[ebx].nCurIdx,addr @rect		
		mov [ebx].nCurIdx,-2
		invoke InvalidateRect,hwnd,addr @rect,TRUE
		
		mov esi,hwnd
		.if esi==hList1
			mov esi,hList2
		.else
			mov esi,hList1
		.endif
		invoke SendMessageW,esi,LB_GETITEMRECT,@cx,addr @rect		
		invoke GetWindowLongW,esi,4
		mov ebx,eax
		mov [ebx].nCurIdx,-2
		invoke InvalidateRect,esi,addr @rect,TRUE
		
		assume ebx:nothing
	.elseif eax==WM_LBUTTONDBLCLK
		invoke SendMessageW,hList1,LB_GETCOUNT,0,0
		mov ebx,eax
		invoke SendMessageW,hList2,LB_GETCOUNT,0,0
		.if !ebx
			invoke SendMessageW,hWinMain,WM_COMMAND,IDM_OPEN,0
		.elseif !eax
			invoke SendMessageW,hWinMain,WM_COMMAND,IDM_LOAD,0
		.else
			invoke _MarkLine
		.endif
		invoke SetFocus,hEdit2
	.elseif eax==WM_LBUPDATE
		invoke GetWindowLongW,hwnd,4
		mov ebx,eax
		assume ebx:ptr _MyListData
		invoke GetClientRect,hwnd,addr @rect
		mov eax,@rect.bottom
		sub eax,@rect.top
		mov @cy,eax
		mov eax,@rect.right
		sub eax,@rect.left
		mov @cx,eax
		mov ecx,hwnd
		.if ecx==hList1
			mov eax,WRI_LIST1
		.elseif ecx==hList2
			mov eax,WRI_LIST2
		.endif
		invoke BitBlt,[ebx].StoredDC,0,0,@cx,@cy,hBackDC,dbConf+_Configs.windowRect[eax]+RECT.left,dbConf+_Configs.windowRect[eax]+RECT.top,SRCCOPY
		assume ebx:nothing
	.elseif eax==WM_RBUTTONUP
		invoke SendMessageW,hwnd,LB_ITEMFROMPOINT,0,lParam
		.if ax!=-1
			invoke SendMessageW,hWinMain,WM_COMMAND,IDM_MODIFY,0
		.endif
	.elseif eax==LB_GETCURSEL
		invoke CallWindowProcW,lpOldListProc,hwnd,LB_GETCURSEL,0,0
		.if lParam && eax!=-1
			invoke _GetRealLine,eax
		.endif
		ret
	.elseif eax==LB_SETCURSEL
		mov eax,wParam
		.if lParam
			invoke _GetDispLine,eax
		.endif
		invoke CallWindowProcW,lpOldListProc,hwnd,LB_SETCURSEL,eax,0
		ret
	.elseif eax==WM_CREATE
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,sizeof _MyListData
		.if !eax
			invoke SendMessageW,hwnd,WM_DESTROY,0,0
			ret
		.endif
		assume eax:ptr _MyListData
		mov [eax].nCurIdx,-2
		assume eax:nothing
		invoke SetWindowLongW,hwnd,4,eax
	.elseif eax==WM_DESTROY
		invoke GetWindowLongW,hwnd,4
		invoke HeapFree,hGlobalHeap,0,eax
	.endif
_Ex2NLP:
	invoke CallWindowProcW,lpOldListProc,hwnd,uMsg,wParam,lParam
	ret
_ExNLP:
	xor eax,eax
	ret
_NewListProc endp

_GetDecimalBit proc
	cmp eax,10
	jb _b1
	cmp eax,100
	jb _b2
	cmp eax,1000
	jb _b3
	cmp eax,10000
	jb _b4
	cmp eax,100000
	jb _b5
	cmp eax,1000000
	jb _b6
	cmp eax,10000000
	jb _b7
	cmp eax,100000000
	jb _b8
	cmp eax,1000000000
	jb _b9
	mov eax,10
	ret
_b1:
	mov eax,1
	ret
_b2:
	mov eax,2
	ret
_b3:
	mov eax,3
	ret
_b4:
	mov eax,4
	ret
_b5:
	mov eax,5
	ret
_b6:
	mov eax,6
	ret
_b7:
	mov eax,7
	ret
_b8:
	mov eax,8
	ret
_b9:
	mov eax,9
	ret
_GetDecimalBit endp

;画列表框
_DrawListItem proc uses edi ebx _lpDIS
	LOCAL @cx,@cy
	LOCAL @rect:RECT
	LOCAL @bf:BLENDFUNCTION
	LOCAL @hmdc,@hBmp,@hOldBmp
	LOCAL @hmdc2,@hBmp2,@hOldBmp2
	LOCAL @nRealLine
	LOCAL @szStr[12]:word
	mov dword ptr @bf,0

	mov edi,_lpDIS
	assume edi:ptr DRAWITEMSTRUCT
	cmp [edi].itemID,-1
	je _ExDLI
	cmp [edi].itemAction,ODA_FOCUS
	je _ExDLI
	invoke _GetRealLine,[edi].itemID
	cmp eax,-1
	je _ExDLI
	mov @nRealLine,eax
	invoke GetWindowLongW,[edi].hwndItem,4
	mov ebx,eax
	assume ebx:ptr _MyListData
	mov eax,[edi].rcItem.right
	sub eax,[edi].rcItem.left
	mov @cx,eax
	mov eax,[edi].rcItem.bottom
	sub eax,[edi].rcItem.top
	mov @cy,eax
	invoke CreateCompatibleDC,[edi].hdc
	mov @hmdc,eax
	invoke CreateCompatibleBitmap,[edi].hdc,@cx,@cy
	mov @hBmp,eax
	invoke CreateCompatibleDC,[edi].hdc
	mov @hmdc2,eax
	invoke CreateCompatibleBitmap,[edi].hdc,@cx,@cy
	mov @hBmp2,eax
	invoke SelectObject,@hmdc,@hBmp
	mov @hOldBmp,eax
	invoke SelectObject,@hmdc2,@hBmp2
	mov @hOldBmp2,eax
	mov @rect.left,0
	mov @rect.top,LI_FRAME_WIDTH
	mov eax,@cx
	mov @rect.right,eax
	mov eax,@cy
	sub eax,LI_FRAME_WIDTH
	mov @rect.bottom,eax
	invoke BitBlt,@hmdc,0,0,@cx,@cy,[ebx].StoredDC,[edi].rcItem.left,[edi].rcItem.top,SRCCOPY
	invoke BitBlt,@hmdc2,0,0,@cx,@cy,[ebx].StoredDC,[edi].rcItem.left,[edi].rcItem.top,SRCCOPY
	mov eax,lpMarkTable
	.if eax
		add eax,@nRealLine
		.if byte ptr [eax] &1 ;标记状态
			invoke CreateSolidBrush,dbConf+_Configs.HiColorMarked
			push eax
			invoke FillRect,@hmdc2,addr @rect,eax
			call DeleteObject
			mov @bf.SourceConstantAlpha,130
			invoke AlphaBlend,@hmdc,0,0,@cx,@cy,@hmdc2,0,0,@cx,@cy,dword ptr @bf
		.endif
	.endif
	mov eax,[ebx].nCurIdx
	.if eax==[edi].itemID ;悬停状态
		mov ecx,[edi].itemState
		and ecx,ODS_SELECTED
		mov eax,dbConf+_Configs.HiColorDefault
		.if !ZERO?
			invoke _DarkenColor,eax
		.endif
		@@:
		invoke CreateSolidBrush,eax
		push eax
		invoke FillRect,@hmdc2,addr @rect,eax
		call DeleteObject
		invoke SelectObject,@hmdc2,hLineNumberFont
		mov eax,[edi].itemID
		inc eax
		invoke wsprintfW,addr @szStr,offset szToStr,eax
		invoke SetBkMode,@hmdc2,TRANSPARENT
		invoke lstrlenW,addr @szStr
		mov edx,11
		push eax
		mul edx
		add eax,LI_MARGIN_WIDTH
		mov edx,@rect.right
		sub edx,eax
		lea ecx,@szStr
		push ecx
		mov eax,@rect.bottom
		sub eax,18
		push eax
		push edx
		push @hmdc2
		call TextOutW
;		invoke TextOutW,@hmdc2,edx,eax,addr @szStr,ecx
		
		mov @bf.SourceConstantAlpha,130
		invoke AlphaBlend,@hmdc,0,0,@cx,@cy,@hmdc2,0,0,@cx,@cy,dword ptr @bf
	.else ;非悬停
		mov ecx,[edi].itemState
		and ecx,ODS_SELECTED
		.if !ZERO?
			invoke _DarkenColor,dbConf+_Configs.HiColorDefault
			jmp @B
		.endif
		mov eax,lpMarkTable
		.if eax
			add eax,@nRealLine
			.if !(byte ptr [eax]&1) ;是否被过滤掉
				invoke GetStockObject,WHITE_BRUSH
				invoke FillRect,@hmdc2,addr @rect,eax
				mov @bf.SourceConstantAlpha,100
				invoke AlphaBlend,@hmdc,0,0,@cx,@cy,@hmdc2,0,0,@cx,@cy,dword ptr @bf
			.endif
		.endif
	.endif
	assume ebx:nothing

	invoke SelectObject,@hmdc,hFontList
	invoke SetBkMode,@hmdc,TRANSPARENT
	mov eax,[edi].itemState
	and eax,ODS_SELECTED
	.if ZERO?
		invoke SetTextColor,@hmdc,dbConf+_Configs.TextColorDefault
	.else					
		invoke SetTextColor,@hmdc,dbConf+_Configs.TextColorSelected
	.endif
	.if [edi].CtlID==IDC_LIST1
		invoke _GetStringInList,offset FileInfo1,@nRealLine
	.else
		invoke _GetStringInList,offset FileInfo2,@nRealLine
	.endif
	.if eax
		mov ebx,eax
		sub @rect.top,LI_FRAME_WIDTH
		add @rect.bottom,LI_FRAME_WIDTH
		invoke _ZoomRect,addr @rect,LI_MARGIN_WIDTH
		invoke DrawTextW,@hmdc,ebx,-1,addr @rect,DT_HIDEPREFIX or DT_LEFT or DT_WORDBREAK
		invoke _ZoomRect,addr @rect,LI_MARGIN_WIDTH*-1
	.endif
	mov eax,[edi].itemState
	and eax,ODS_SELECTED
	.if !ZERO?
		invoke CreatePen,PS_SOLID,LI_FRAME_WIDTH,dbConf+_Configs.LineColor
		mov ebx,eax
		invoke SelectObject,@hmdc,ebx
		invoke _ZoomRect,addr @rect,LI_FRAME_WIDTH/2
		invoke MoveToEx,@hmdc,@rect.left,@rect.top,NULL
		invoke LineTo,@hmdc,@rect.right,@rect.top
		invoke LineTo,@hmdc,@rect.right,@rect.bottom
		invoke LineTo,@hmdc,@rect.left,@rect.bottom
		sub @rect.top,LI_FRAME_WIDTH/2
		invoke LineTo,@hmdc,@rect.left,@rect.top
		
		invoke DeleteObject,ebx
	.endif
	invoke BitBlt,[edi].hdc,[edi].rcItem.left,[edi].rcItem.top,@cx,@cy,@hmdc,0,0,SRCCOPY
	invoke SelectObject,@hmdc,@hOldBmp
	invoke SelectObject,@hmdc2,@hOldBmp2
	invoke DeleteDC,@hmdc
	invoke DeleteObject,@hBmp
	invoke DeleteDC,@hmdc2
	invoke DeleteObject,@hBmp2
	assume edi:nothing
_ExDLI:
	ret
_DrawListItem endp

_ZoomRect proc uses edi _lpRect,_nPix
	mov edi,_lpRect
	assume edi:ptr RECT
	mov eax,_nPix
	add [edi].left,eax
	add [edi].top,eax
	sub [edi].right,eax
	sub [edi].bottom,eax
	assume edi:nothing
	ret
_ZoomRect endp

;
_LightenColor proc _color
	mov ecx,_color
	mov eax,ecx
	not cl
	shr cl,1
	add al,cl
	shr ecx,8
	not cl
	shr cl,1
	add ah,cl
	shr ecx,8
	not cl
	shr cl,1
	shl ecx,16
	add eax,ecx
	and eax,0ffffffh
	ret
_LightenColor endp

_DarkenColor proc _color
	mov ecx,_color
	mov eax,ecx
	not cl
	shr cl,1
	sub al,cl
	shr ecx,8
	not cl
	shr cl,1
	sub ah,cl
	shr ecx,8
	not cl
	shr cl,1
	shl ecx,16
	sub eax,ecx
	and eax,0ffffffh
	ret
_DarkenColor endp

;
_NewEditProc proc uses ebx esi edi,hwnd,uMsg,wParam,lParam
	LOCAL @hmdc,@hbmp,@holdbmp,@rect:RECT,@bf:BLENDFUNCTION
	LOCAL @hmdc2,@hbmp2,@holdbmp2
	.if uMsg==WM_ERASEBKGND
		.if hBackDC
			mov eax,hwnd
			.if eax==hEdit1
				mov ebx,WRI_EDIT1
			.elseif eax==hEdit2
				mov ebx,WRI_EDIT2
			.endif
			invoke CreateCompatibleDC,wParam
			mov @hmdc,eax
			invoke CreateCompatibleBitmap,wParam,dbConf+_Configs.windowRect[ebx]+RECT.right,dbConf+_Configs.windowRect[ebx]+RECT.bottom
			mov @hbmp,eax
			invoke SelectObject,@hmdc,@hbmp
			mov @holdbmp,eax
			invoke CreateCompatibleDC,wParam
			mov @hmdc2,eax
			invoke CreateCompatibleBitmap,wParam,dbConf+_Configs.windowRect[ebx]+RECT.right,dbConf+_Configs.windowRect[ebx]+RECT.bottom
			mov @hbmp2,eax
			invoke SelectObject,@hmdc2,@hbmp2
			mov @holdbmp2,eax
			mov @rect.left,0
			mov @rect.top,0
			mov eax,dbConf+_Configs.windowRect[ebx]+RECT.right
			mov @rect.right,eax
			mov eax,dbConf+_Configs.windowRect[ebx]+RECT.bottom
			mov @rect.bottom,eax
			invoke GetStockObject,WHITE_BRUSH
			invoke FillRect,@hmdc2,addr @rect,eax
			invoke BitBlt,@hmdc,0,0,dbConf+_Configs.windowRect[ebx]+RECT.right,dbConf+_Configs.windowRect[ebx]+RECT.bottom,hBackDC,\
				dbConf+_Configs.windowRect[ebx]+RECT.left,dbConf+_Configs.windowRect[ebx]+RECT.top,SRCCOPY
			.if bOpen
				mov dword ptr @bf,0
				mov @bf.SourceConstantAlpha,120
				invoke AlphaBlend,@hmdc,0,0,dbConf+_Configs.windowRect[ebx]+RECT.right,dbConf+_Configs.windowRect[ebx]+RECT.bottom,@hmdc2,\
					0,0,dbConf+_Configs.windowRect[ebx]+RECT.right,dbConf+_Configs.windowRect[ebx]+RECT.bottom,dword ptr @bf
			.endif
			invoke BitBlt,wParam,0,0,dbConf+_Configs.windowRect[ebx]+RECT.right,dbConf+_Configs.windowRect[ebx]+RECT.bottom,@hmdc,\
				0,0,SRCCOPY
			invoke SelectObject,@hmdc,@holdbmp
			invoke DeleteDC,@hmdc
			invoke DeleteObject,@hbmp
			invoke DeleteDC,@hmdc2
			invoke DeleteObject,@hbmp2
			mov eax,1
			ret
		.endif
	.endif
	.if bOpen
	mov eax,uMsg
	.if eax==WM_KEYDOWN
		mov eax,wParam
		.if eax==VK_RETURN
			mov eax,hwnd
			.if eax==hEdit2
				invoke SendMessageW,hWinMain,WM_COMMAND,IDM_MODIFY,0
			.endif
		.elseif eax==VK_NEXT
			invoke SendMessageW,hWinMain,WM_COMMAND,IDM_NEXTTEXT,0
			RET
		.elseif eax==VK_PRIOR
			invoke SendMessageW,hWinMain,WM_COMMAND,IDM_PREVTEXT,0
			RET
		.elseif eax==VK_INSERT
			invoke _MarkLine
		.elseif eax==VK_UP
			invoke GetKeyState,VK_CONTROL
			and eax,8000h
			.if !ZERO?
				invoke _PrevMark
			.endif
		.elseif eax==VK_DOWN
			invoke GetKeyState,VK_CONTROL
			and eax,8000h
			.if !ZERO?
				invoke _NextMark
			.endif
		.elseif eax==46h;F key
			invoke GetKeyState,VK_CONTROL
			and eax,8000h
			.if !ZERO?
				invoke SendMessageW,hWinMain,WM_COMMAND,IDM_FIND,0
			.endif
		.elseif eax==53h
			invoke GetKeyState,VK_CONTROL
			and eax,8000h
			.if !ZERO?
				invoke SendMessageW,hWinMain,WM_COMMAND,IDM_SAVE,0
			.endif
		.endif
	.elseif eax==WM_MOUSEWHEEL
		invoke SendMessageW,hList2,WM_MOUSEWHEEL,wParam,lParam
	.elseif eax==WM_CHAR
		cmp wParam,VK_RETURN
		je _ExNEP
		mov eax,hwnd
		cmp eax,hEdit1
		jne @F
		cmp wParam,3
		jne _ExNEP
	.endif
	.endif
	@@:
	invoke CallWindowProcW,lpOldEditProc,hwnd,uMsg,wParam,lParam
	ret
_ExNEP:
	xor eax,eax
	ret
_NewEditProc endp
