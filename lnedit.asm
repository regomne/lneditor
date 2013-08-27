.586
.model flat,stdcall
option casemap:none

include windows.inc

include plugin.inc
include config.inc
include lnedit.inc
include macros.inc
include com.inc
include cppimp.inc

include globalvars.asm

include _browsefolder.asm
include _CreateDIBitmap.asm
include progbar.asm
include config.asm
include wildchar.asm
include log.asm
include choosemel.asm
include menufile.asm
include menuedit.asm
include menuview.asm
include menuasm.asm
include menuopt.asm
include defaultedit.asm
include record.asm
include update.asm

include misc.asm
include misc2.asm
include newUI.asm
include cmdmode.asm


.code

assume fs:nothing
start proc
;
invoke GetModuleHandleW,NULL
mov hInstance,eax
invoke InitCommonControls
invoke LoadIconW,hInstance,500
mov hIcon,eax
invoke HeapCreate,0,7ff00h,0
or eax,eax
je _FinalMemErr
mov hGlobalHeap,eax
invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,TOTAL_STRINGNUM*MAX_STRINGLEN
.if !eax
	_FinalMemErr:
	invoke MessageBoxW,0,offset szMemErr,0,MB_OK OR MB_ICONERROR
	jmp _FinalExit
.endif
mov lpStrings,eax
xor ebx,ebx
.while ebx<TOTAL_STRINGNUM
	mov eax,ebx
	shl eax,8
	add eax,lpStrings
	invoke LoadStringW,hInstance,ebx,eax,MAX_STRINGLEN/2
	inc ebx
.endw

invoke _CppInitialize

invoke GetCommandLineW
invoke CommandLineToArgvW,eax,offset nArgc
mov lpArgTbl,eax
mov eax,fs:[30h]
mov ecx,[eax+10h]
lea esi,[ecx+56]
xor eax,eax
mov ax,UNICODE_STRING.woLength[esi]
add eax,2
invoke HeapAlloc,hGlobalHeap,0,eax
test eax,eax
jz _FinalMemErr
mov lpszImagePath,eax
invoke lstrcpyW,eax,UNICODE_STRING.Buffer[esi]
xor eax,eax
mov ax,UNICODE_STRING.woLength[esi]
add eax,lpszImagePath
.while word ptr [eax]!='\'
	sub eax,2
.endw
mov word ptr [eax+2],0

invoke _GetCmdOption,offset szOptionConsole
mov ebx,eax
invoke _GetCmdOption,offset szOptionHelp
.if eax || ebx
	or nUIStatus,UIS_CONSOLE
.endif

invoke _OpenLog
invoke _LoadConfig
invoke _GetCmdOptions,offset coCmdOptions

ifndef _LN_NOCONSOLE
.if nUIStatus & UIS_CONSOLE
	invoke _CmdMain
.else
endif
	invoke _WinMain
ifndef _LN_NOCONSOLE
.endif
endif
_FinalExit:
invoke ExitProcess,0
invoke compress,1,1,1,1

start endp

;
_WinMain proc
	local @stWndClass:WNDCLASSEX
	local @stMsg:MSG
	LOCAL @str[MAX_STRINGLEN]:byte
	mov ecx,sizeof @stWndClass
	lea edi,@stWndClass
	xor eax,eax
	rep stosb
	
	invoke LoadCursorW,0,IDC_ARROW
	
	
	mov @stWndClass.hCursor,eax
	push hInstance
	pop @stWndClass.hInstance
	mov @stWndClass.cbSize,sizeof WNDCLASSEX
	mov @stWndClass.style,CS_HREDRAW OR CS_VREDRAW or CS_DBLCLKS 
	mov @stWndClass.lpfnWndProc,offset _WndMainProc
	push hIcon
	pop @stWndClass.hIcon
	invoke GetStockObject,NULL_BRUSH
	mov @stWndClass.hbrBackground,eax
	mov eax,IDS_CLASSNAME
	invoke _GetConstString
	mov ebx,eax
	mov @stWndClass.lpszClassName,eax
	invoke RegisterClassExW,addr @stWndClass
	
	invoke LoadMenuW,hInstance,IDR_MMENU_CHS
	mov hMenu,eax
	mov esi,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,64
	.if !eax
		mov edi,offset szNULL
		jmp @F
	.endif
	mov edi,eax
	invoke _GenWindowTitle,edi,GWT_VERSION
	@@:
	invoke GetTickCount
	mov nStartTime,eax
	invoke CreateWindowExW,WS_EX_CLIENTEDGE or WS_EX_ACCEPTFILES,ebx,edi,\
		WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX,\
		dbConf+_Configs.windowRect[WRI_MAIN]+RECT.left,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.top,\
		dbConf+_Configs.windowRect[WRI_MAIN]+RECT.right,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.bottom,NULL,esi,hInstance,NULL
	mov hWinMain,eax
	.if edi!=offset szNULL
		invoke HeapFree,hGlobalHeap,0,edi
	.endif
	invoke ShowWindow,hWinMain,SW_SHOWNORMAL
	invoke UpdateWindow,hWinMain
	
	.while TRUE
		invoke GetMessageW,addr @stMsg,NULL,0,0
		.break .if eax==0
		invoke TranslateMessage,addr @stMsg
		invoke DispatchMessageW,addr @stMsg
	.endw
	
	ret
_WinMain endp

;
_WndMainProc proc uses ebx edi esi,hwnd,uMsg,wParam,lParam
	local @stPs:PAINTSTRUCT
	local @stRect:RECT
	local @hdc,@hFile,@nPlugin
	LOCAL @szStr[SHORT_STRINGLEN]:byte
	LOCAL @opParas:_OpenParameters
;	LOCAL @dt:DRAWTEXTPARAMS

	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		mov ecx,eax
		movzx eax,ax
		shr ecx,16
		or ecx,lParam
		.if ZERO?
			.if eax==IDM_OPEN
				mov esi,eax
				.if bOpen
					invoke _CloseScript
					cmp eax,-1
					je _ExMain
				.endif
				lea edi,@opParas
				mov ecx,sizeof @opParas/4
				xor eax,eax
				rep stosd
				mov @opParas.Plugin,-2
				mov @opParas.Filter,-1
				mov eax,IDS_OPENTITLE1
				invoke _GetConstString
				mov ecx,eax
				invoke _OpenFileDlg,offset szOpenFilter,addr @opParas.ScriptName,dbConf+_Configs.lpInitDir1,ecx,addr @opParas.Plugin
				or eax,eax
				je _ExMain
_FillParamMain:
				.if @opParas.Line==0
					invoke _ReadRec,@opParas.ScriptName,REC_LINEPOS,0
					mov @opParas.Line,eax
				.endif
				invoke _ReadRec,@opParas.ScriptName,REC_CHARSET,0
				.if @opParas.Code1==0
					mov @opParas.Code1,eax
				.endif
				.if @opParas.Code2==0
					mov @opParas.Code2,ecx
				.endif
				mov ebx,@opParas.Plugin
				cmp ebx,-2
				jne _ForcePluginMain
_BeginOpenMain:
				invoke _TryMatch,@opParas.ScriptName
				mov ebx,eax
_ForcePluginMain:
				invoke lstrcpyW,dbConf+_Configs.lpInitDir1,@opParas.ScriptName
				invoke _DirBackW,dbConf+_Configs.lpInitDir1
				.if ebx==-3
					mov eax,IDS_ERRMATCH
					invoke _GetConstString
					invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
					invoke HeapFree,hGlobalHeap,0,@opParas.ScriptName
					jmp _ExMain
				.ELSEif ebx==-2
					mov eax,IDS_NOMATCH
					invoke _GetConstString
					invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
					invoke HeapFree,hGlobalHeap,0,@opParas.ScriptName
					jmp _ExMain
				.elseif ebx==-1
					invoke _SelfPreProc
					mov @opParas.Plugin,ebx
					jmp _Open2Main
				.endif
				xor eax,eax
				mov ax,sizeof _MelInfo
				mul bx
				add eax,lpMels
				mov edi,eax
				assume edi:ptr _MelInfo
				invoke _RestoreFunc,lpOriFuncTable
				invoke _GetSimpFunc,[edi].hModule,offset dbSimpFunc
				.if !eax
					mov eax,IDS_ERREXDLL
					invoke _GetConstString
					invoke wsprintfW,addr @szStr,eax,edi
					invoke MessageBoxW,hWinMain,addr @szStr,0,MB_OK or MB_ICONERROR
					invoke HeapFree,hGlobalHeap,0,@opParas.ScriptName
					jmp _ExMain
				.endif
				mov nCurMel,ebx
				mov @opParas.Plugin,ebx
				invoke GetProcAddress,[edi].hModule,offset szFPreProc
				assume edi:nothing
				.if eax
					push lpPreData
					call eax
				.endif
_Open2Main:
				mov eax,esi
				lea ecx,@opParas
				push ecx
				sub eax,IDM_OPEN
				call [eax*4+offset dbFunc]
				invoke HeapFree,hGlobalHeap,0,@opParas.ScriptName
				jmp _ExMain
			.elseif eax==IDM_LOAD
				mov esi,eax
				mov eax,IDS_OPENTITLE2
				invoke _GetConstString
				invoke _OpenFileDlg,offset szOpenFilter,offset FileInfo2.lpszName,dbConf+_Configs.lpInitDir2,eax,0
				or eax,eax
				je _ExMain
_LoadMain:
				invoke lstrcpyW,dbConf+_Configs.lpInitDir2,FileInfo2.lpszName
				invoke _DirBackW,dbConf+_Configs.lpInitDir2
				mov eax,esi
			.endif
			sub eax,IDM_OPEN
			call [eax*4+offset dbFunc]
			jmp _ExMain
			
		.elseif eax==IDC_LIST1 || eax==IDC_LIST2
			cmp bOpen,0
			je _ExMain
			invoke SendMessageW,lParam,LB_GETCOUNT,0,0
			or eax,eax
			je _ExMain
			mov eax,wParam
			shr eax,16
			.if eax==LBN_SELCHANGE
				mov esi,lParam
				.if esi==hList1
					mov edi,hList2
				.else
					mov edi,hList1
				.endif
				invoke SendMessageW,esi,LB_GETCURSEL,0,0
				mov ebx,eax
				invoke SendMessageW,hList1,WM_SETREDRAW,FALSE,0
				invoke SendMessageW,hList2,WM_SETREDRAW,FALSE,0
				invoke SendMessageW,edi,LB_SETCURSEL,ebx,0
				invoke SendMessageW,esi,LB_GETTOPINDEX,0,0
				invoke SendMessageW,edi,LB_SETTOPINDEX,eax,0
				invoke SendMessageW,hList1,WM_SETREDRAW,TRUE,0
				invoke SendMessageW,hList2,WM_SETREDRAW,TRUE,0
				invoke RedrawWindow,hList1,0,0,RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW
				invoke RedrawWindow,hList2,0,0,RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW
				invoke _GetRealLine,ebx
				.if eax!=-1 && eax<FileInfo1.nLine
					invoke _SetTextToEdit,eax
				.endif
			.endif
		.elseif eax==IDC_EDIT2
			mov eax,wParam
			shr eax,16
			.if eax==EN_CHANGE
				invoke GetClientRect,hEdit2,addr @stRect
				invoke RedrawWindow,hEdit2,addr @stRect,0,RDW_ERASE OR RDW_INVALIDATE
			.endif
		.endif
		
	.elseif eax==WM_DRAWITEM
		mov edi,lParam
		assume edi:ptr DRAWITEMSTRUCT
		.if [edi].CtlType==ODT_LISTBOX
			invoke _DrawListItem,edi
		.endif
		assume edi:nothing
		JMP _Ex2Main
		
	.elseif eax==WM_MEASUREITEM
		mov edi,lParam
		assume edi:ptr MEASUREITEMSTRUCT
		.if [edi].CtlType==ODT_LISTBOX
			invoke _GetRealLine,[edi].itemID
			invoke _CalHeight,eax
			mov [edi].itemHeight,eax
		.endif
		assume edi:nothing
		jmp _Ex2Main
		
	.elseif eax==WM_SETFOCUS
		.if bOpen
			invoke SetFocus,hEdit2
		.endif
		
	.elseif eax==WM_ERASEBKGND
		.if !hBackDC
			invoke CreateCompatibleDC,wParam
			mov hBackDC,eax
			invoke CreateCompatibleBitmap,wParam,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.right,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.bottom
			mov hBackBmp,eax
			invoke SelectObject,hBackDC,hBackBmp
			
			invoke _IsRelativePath,dbConf+_Configs.lpBackName
			.if eax
				invoke lstrlenW,lpszImagePath
				lea ebx,[eax*2]
				invoke lstrlenW,dbConf+_Configs.lpBackName
				lea ebx,[ebx+eax*2+10]
				invoke HeapAlloc,hGlobalHeap,0,ebx
				or eax,eax
				je _PaintMain
				mov ebx,eax
				invoke lstrcpyW,ebx,lpszImagePath
				invoke lstrcatW,ebx,dbConf+_Configs.lpBackName
				invoke _ShowPic,hBackDC,ebx
				mov esi,eax
				invoke HeapFree,hGlobalHeap,0,ebx
				test esi,esi
				je _PaintMain
			.else
				invoke _ShowPic,hBackDC,dbConf+_Configs.lpBackName
				or eax,eax
				je _PaintMain
			.endif
			invoke SendMessageW,hList1,WM_LBUPDATE,0,0
			invoke SendMessageW,hList2,WM_LBUPDATE,0,0
		.endif
		invoke BitBlt,wParam,0,0,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.right,dbConf+_Configs.windowRect[WRI_MAIN]+RECT.bottom,hBackDC,0,0,SRCCOPY
		mov eax,1
		ret
_PaintMain:
		invoke GetClientRect,hwnd,addr @stRect
		invoke GetStockObject,WHITE_BRUSH
		invoke FillRect,hBackDC,addr @stRect,eax
	.elseif eax==WM_PAINT
		invoke BeginPaint,hwnd,addr @stPs
		mov @hdc,eax
		invoke EndPaint,hwnd,addr @stPs
		
	.elseif eax==WM_CTLCOLORLISTBOX
		invoke GetStockObject,NULL_BRUSH
		ret
	.elseif eax==WM_CTLCOLOREDIT
		invoke SetTextColor,wParam,dbConf+_Configs.TextColorEdit
		invoke SetBkMode,wParam,TRANSPARENT
		invoke GetStockObject,NULL_BRUSH
		ret
		
	.elseif eax==WM_TIMER
		.if wParam==IDC_TIMER
			invoke _SaveScript
		.endif
		
	.elseif eax==WM_DROPFILES
		.if bOpen
			invoke _CloseScript
			cmp eax,-1
			je _ExMain
		.endif
		
		lea edi,@opParas
		mov ecx,sizeof @opParas/4
		xor eax,eax
		rep stosd
		mov @opParas.Plugin,-2
		mov @opParas.Filter,-1
		.if dbConf+_Configs.nEditMode==EM_SINGLE
			@@:
			invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
			test eax,eax
			jz _ErrDrop
			mov @opParas.ScriptName,eax
			invoke DragQueryFileW,wParam,0,eax,MAX_STRINGLEN/2
			mov esi,IDM_OPEN
			jmp _FillParamMain
		.elseif dbConf+_Configs.nEditMode==EM_DOUBLE
			sub esp,sizeof POINT
			invoke DragQueryPoint,wParam,esp
			push hwnd
			call ChildWindowFromPoint
			cmp eax,hList1
			je @B
			mov ecx,FileInfo1.lpszName
			.if eax==hList2 && word ptr [ecx]
				invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
				test eax,eax
				jz _ErrDrop
				mov FileInfo2.lpszName,eax
				invoke DragQueryFileW,wParam,0,FileInfo2.lpszName,MAX_STRINGLEN/2
				mov esi,IDM_LOAD
				jmp _LoadMain
			.endif
		.endif
	_ErrDrop:
		mov eax,IDS_CANTOPENFILE
		invoke _GetConstString
		invoke MessageBoxW,hWinMain,eax,0,MB_ICONERROR
	
	.elseif eax==WM_CREATE
		mov nUIStatus,UIS_GUI OR UIS_IDLE
		mov eax,hwnd
		mov hWinMain,eax
		invoke _InitWindow,hwnd
;		invoke CreateThread,0,0,offset _LoadMel,0,0,0
;		mov @hFile,eax
		invoke _LoadMel,0
		invoke _LoadMef,0
		.if dbConf+_Configs.bAutoUpdate
			invoke CreateThread,0,0,offset _UpdateThd,0,0,0
		.endif
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,sizeof _PreData
		or eax,eax
		je @B
		mov lpPreData,eax
		assume eax:ptr _PreData
		push hGlobalHeap
		pop [eax].hGlobalHeap
		push lpszConfigFile
		pop [eax].lpszConfigFile
		mov [eax].lpConfigs,offset dbConf
		mov [eax].lpMenuFuncs,offset dbFunc
		mov [eax].lpSimpFuncs,offset dbSimpFunc
		mov [eax].lpTxtFuncs,offset dbTxtFunc
		mov [eax].lpHandles,offset hWinMain
		mov [eax].lpCmdOptions,offset coCmdOptions
		assume eax:nothing
		
		invoke HeapAlloc,hGlobalHeap,0,sizeof _Functions+sizeof _SimpFunc+sizeof _TxtFunc
		or eax,eax
		je @B
		mov lpOriFuncTable,eax
		invoke _BackupFunc,eax
		
		lea edi,@opParas
		mov ecx,sizeof @opParas/4
		xor eax,eax
		rep stosd
		mov @opParas.Plugin,-2
		mov @opParas.Filter,-1
		
		mov nCurMel,-1
		lea edi,coCmdOptions
		.if _StCmdOptions.ScriptName.lpszValue[edi]
			invoke HeapAlloc,hGlobalHeap,0,MAX_STRINGLEN
			test eax,eax
			jz _ExMain
			mov @opParas.ScriptName,eax
			invoke lstrcpyW,eax,_StCmdOptions.ScriptName.lpszValue[edi]
			.if _StCmdOptions.Plugin.lpszValue[edi]
				invoke _FindPlugin,_StCmdOptions.Plugin.lpszValue[edi],1
				.if eax!=-2
					mov @opParas.Plugin,eax
				.endif
			.endif
			.if _StCmdOptions.Filter.lpszValue[edi]
				invoke _FindPlugin,_StCmdOptions.Filter.lpszValue[edi],2
				.if eax!=-2
					mov @opParas.Filter,eax
				.endif
			.endif
			.if _StCmdOptions.Code1.lpszValue[edi]
				invoke StrToIntExW,_StCmdOptions.Code1.lpszValue[edi],1,addr @opParas.Code1
				.if !eax
					mov @opParas.Code1,0
				.endif
			.endif
			.if _StCmdOptions.Code2.lpszValue[edi]
				invoke StrToIntExW,_StCmdOptions.Code2.lpszValue[edi],1,addr @opParas.Code2
				.if !eax
					mov @opParas.Code2,0
				.endif
			.endif
			.if _StCmdOptions.Line.lpszValue[edi]
				invoke StrToIntExW,_StCmdOptions.Line.lpszValue[edi],1,addr @opParas.Line
				.if !eax
					mov @opParas.Line,0
				.endif
			.endif
		
			mov esi,IDM_OPEN
			jmp _FillParamMain
		.elseif dbConf+_Configs.nEditMode==EM_SINGLE && dbConf+_Configs.bAutoOpen
			mov eax,dbConf+_Configs.lpPrevFile
			.if word ptr [eax]
				invoke GetFileAttributesW,eax
				cmp eax,-1
				jz _ExMain
				invoke lstrlenW,dbConf+_Configs.lpPrevFile
				add eax,5
				shl eax,1
				invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,eax
				test eax,eax
				jz _ExMain
				mov @opParas.ScriptName,eax
				invoke lstrcpyW,eax,dbConf+_Configs.lpPrevFile
;				invoke WaitForSingleObject,@hFile,INFINITE
;				invoke CloseHandle,@hFile
				mov esi,IDM_OPEN
				jmp _FillParamMain
			.endif
		.endif
		
	.elseif eax==WM_CLOSE
		.if bOpen
			invoke lstrlenW,FileInfo1.lpszName
			inc eax
			shl eax,1
			invoke HeapAlloc,hGlobalHeap,0,eax
			mov ebx,eax
			.if ebx
				invoke lstrcpyW,ebx,FileInfo1.lpszName
			.endif
		.else
			xor ebx,ebx
		.endif
		invoke _CloseScript
		cmp eax,-1
		je _ExMain
		.if ebx
			invoke lstrcpyW,dbConf+_Configs.lpPrevFile,ebx
		.else
			mov dbConf+_Configs.lpPrevFile,offset szNULL
		.endif
		invoke _SaveConfig
		invoke DestroyWindow,hwnd
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProcW,hwnd,uMsg,wParam,lParam
		ret
	.endif
	
_ExMain:
	xor eax,eax
	ret
_Ex2Main:
	mov eax,TRUE
	ret
_WndMainProc endp

;创建子窗口
_InitWindow proc hwnd
	invoke _CreateMyList,hInstance
	.if !eax
		invoke ExitProcess,0
	.endif
	invoke _CreateMyEdit,hInstance
	.if !eax
		invoke ExitProcess,0
	.endif
	invoke CreateWindowExW,WS_EX_LEFT,offset szCNewList,0,\
		WS_CHILD OR WS_VISIBLE OR WS_VSCROLL or LBS_NOTIFY OR LBS_NODATA or LBS_OWNERDRAWVARIABLE,\
		dbConf+_Configs.windowRect[WRI_LIST1]+RECT.left,dbConf+_Configs.windowRect[WRI_LIST1]+RECT.top,\
		dbConf+_Configs.windowRect[WRI_LIST1]+RECT.right,dbConf+_Configs.windowRect[WRI_LIST1]+RECT.bottom,hwnd,IDC_LIST1,hInstance,NULL
	mov hList1,eax
	invoke CreateWindowExW,WS_EX_LEFT,offset szCNewList,0,\
		WS_CHILD OR WS_VISIBLE OR WS_VSCROLL or LBS_NOTIFY OR LBS_NODATA or LBS_OWNERDRAWVARIABLE,\
		dbConf+_Configs.windowRect[WRI_LIST2]+RECT.left,dbConf+_Configs.windowRect[WRI_LIST2]+RECT.top,\
		dbConf+_Configs.windowRect[WRI_LIST2]+RECT.right,dbConf+_Configs.windowRect[WRI_LIST2]+RECT.bottom,hwnd,IDC_LIST2,hInstance,NULL
	mov hList2,eax
	invoke CreateWindowExW,WS_EX_LEFT,offset szCNewEdit,0,\
		WS_CHILD OR WS_VISIBLE or WS_VSCROLL OR ES_AUTOVSCROLL or ES_MULTILINE or ES_NOHIDESEL ,\
		dbConf+_Configs.windowRect[WRI_EDIT1]+RECT.left,dbConf+_Configs.windowRect[WRI_EDIT1]+RECT.top,\
		dbConf+_Configs.windowRect[WRI_EDIT1]+RECT.right,dbConf+_Configs.windowRect[WRI_EDIT1]+RECT.bottom,hwnd,IDC_EDIT1,hInstance,NULL
	mov hEdit1,eax
	invoke CreateWindowExW,WS_EX_LEFT,offset szCNewEdit,0,\
		WS_CHILD OR WS_VISIBLE or WS_VSCROLL  or ES_MULTILINE or ES_NOHIDESEL ,\
		dbConf+_Configs.windowRect[WRI_EDIT2]+RECT.left,dbConf+_Configs.windowRect[WRI_EDIT2]+RECT.top,\
		dbConf+_Configs.windowRect[WRI_EDIT2]+RECT.right,dbConf+_Configs.windowRect[WRI_EDIT2]+RECT.bottom,hwnd,IDC_EDIT2,hInstance,NULL
	mov hEdit2,eax
	invoke CreateWindowExW,WS_EX_LEFT,offset szCStatic,0,WS_CHILD,\; OR WS_VISIBLE ,\
		dbConf+_Configs.windowRect[WRI_STATUS]+RECT.left,dbConf+_Configs.windowRect[WRI_STATUS]+RECT.top,\
		dbConf+_Configs.windowRect[WRI_STATUS]+RECT.right,dbConf+_Configs.windowRect[WRI_STATUS]+RECT.bottom,hwnd,IDC_STATUS,hInstance,NULL
	mov hStatus,eax

	invoke CreateFontIndirectW,offset dbConf+_Configs.listFont
	mov hFontList,eax
	invoke CreateFontIndirectW,offset dbConf+_Configs.editFont
	mov hFontEdit,eax
	.if eax
		invoke SendMessageW,hEdit1,WM_SETFONT,hFontEdit,TRUE
		invoke SendMessageW,hEdit2,WM_SETFONT,hFontEdit,TRUE
	.endif
	ret
_InitWindow endp

_LoadSingleMel proc uses edi esi ebx _lpMel,_lpName
	invoke _DirFileNameW,_lpName
	mov edi,eax
	mov ebx,eax
	invoke lstrlenW,edi
	.if eax>=SHORT_STRINGLEN/2
		mov eax,E_ERROR
		jmp _ExLSM
	.endif
	invoke LoadLibraryW,_lpName
	mov esi,_lpMel
	assume esi:ptr _MelInfo
	.if eax
		mov [esi].hModule,eax
		invoke lstrcpyW,esi,edi
		invoke GetProcAddress,[esi].hModule,offset szFMatch
		.if !eax
		_BadMel:
			invoke FreeLibrary,[esi].hModule
			invoke _WriteLog,WLT_LOADMELERR,offset szInnerName,edi,offset szWltEMel1
			mov eax,E_ERROR
			jmp _ExLSM
		.endif
		mov [esi].pMatch,eax
		invoke GetProcAddress,[esi].hModule,offset szFInitInfo
		or eax,eax
		je _BadMel
		mov edi,eax
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,sizeof _MelInfo2
		.if !eax
			invoke _WriteLog,WLT_LOADMELERR,offset szInnerName,ebx,offset szWltEMem1
			mov eax,E_ERROR
			jmp _ExLSM
		.endif
		mov [esi].lpMelInfo2,eax
		push eax
		call edi
		mov ecx,[esi].lpMelInfo2
		mov eax,_MelInfo2.nInterfaceVer[ecx]
		shr eax,16
		.if eax!=(INTERFACE_VER shr 16)
			invoke _WriteLog,WLT_LOADMELERR,offset szInnerName,ebx,offset szWltEMel2
			mov eax,E_ERROR
			jmp _ExLSM
		.endif
		xor eax,eax
	.else
		mov eax,E_ERROR
	.endif
_ExLSM:
	ret
_LoadSingleMel endp

;载入所有文本提取插件，每个插件使用一个MelInfo结构，依次储存在lpMels里面
_LoadMel proc uses edi esi ebx _lParam
	LOCAL @szStr[MAX_STRINGLEN]:byte
	LOCAL @stFindData:WIN32_FIND_DATAW
	LOCAL @hFind
	LOCAL @lpOldDir
	
	invoke GetModuleFileNameW,0,addr @szStr,MAX_STRINGLEN/2
	invoke _DirBackW,addr @szStr
	invoke _DirCatW,addr @szStr,offset szDLLDir
	invoke HeapAlloc,hGlobalHeap,0,MAX_STRINGLEN
	.if !eax
		mov eax,E_NOMEM
		ret
	.endif
	mov @lpOldDir,eax
	invoke GetCurrentDirectoryW,MAX_STRINGLEN/2,eax
	invoke SetCurrentDirectoryW,addr @szStr
	mov lpMels,0
	.if eax
		invoke FindFirstFileW,offset szMelFile,addr @stFindData
		.if eax!=INVALID_HANDLE_VALUE
			mov @hFind,eax
			invoke VirtualAlloc,0,MAX_MELCOUNT*sizeof _MelInfo,MEM_COMMIT,PAGE_READWRITE
			.if !eax
				mov eax,IDS_FAILLOADMEL
				invoke _GetConstString
				invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
				jmp _Ex2LM
			.endif
			mov lpMels,eax
			mov esi,eax
			xor ebx,ebx
			assume esi:ptr _MelInfo
			.repeat
				invoke _LoadSingleMel,esi,addr @stFindData.cFileName
				.if !eax
					add esi,sizeof _MelInfo
					inc ebx
				.endif
				invoke FindNextFileW,@hFind,addr @stFindData
			.until eax==FALSE || ebx>=MAX_MELCOUNT-1
			mov nMels,ebx
_Ex2LM:
			invoke FindClose,@hFind
			assume esi:nothing
		.endif
	.endif
_ExLM:
	invoke SetCurrentDirectoryW,@lpOldDir
	invoke HeapFree,hGlobalHeap,0,@lpOldDir
	xor eax,eax
	ret
_LoadMel endp

;载入所有文本过滤插件
_LoadMef proc uses edi esi ebx _lParam
	LOCAL @szStr[MAX_STRINGLEN]:byte
	LOCAL @stFindData:WIN32_FIND_DATAW
	LOCAL @hFind
	
	invoke GetModuleFileNameW,0,addr @szStr,MAX_STRINGLEN/2
	invoke _DirBackW,addr @szStr
	invoke _DirCatW,addr @szStr,offset szDLLDir
	invoke SetCurrentDirectoryW,addr @szStr
	mov lpMefs,0
	.if eax
		invoke FindFirstFileW,offset szMefFile,addr @stFindData
		.if eax!=INVALID_HANDLE_VALUE
			mov @hFind,eax
			invoke VirtualAlloc,0,MAX_MELCOUNT*sizeof _MefInfo,MEM_COMMIT,PAGE_READWRITE
			.if !eax
				mov eax,IDS_FAILLOADMEL
				invoke _GetConstString
				invoke MessageBoxW,hWinMain,eax,0,MB_OK or MB_ICONERROR
				jmp _Ex2LM
			.endif
			mov lpMefs,eax
			mov esi,eax
			xor ebx,ebx
			assume esi:ptr _MefInfo
			.repeat
				lea edi,@stFindData.cFileName
				invoke lstrlenW,edi
				cmp eax,SHORT_STRINGLEN/2
				jae _CtnLM
				invoke LoadLibraryW,edi
				.if eax
					mov [esi].hModule,eax
					invoke lstrcpyW,esi,edi
					invoke GetProcAddress,[esi].hModule,offset szFInitInfo
					.if !eax
					_BadMel:
						invoke FreeLibrary,[esi].hModule
						invoke _WriteLog,WLT_LOADMELERR,offset szInnerName,edi,offset szWltEMel1
						jmp _CtnLM
					.endif
					mov edi,eax
					invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,sizeof _MefInfo2
					.if !eax
						lea ecx,@stFindData.cFileName
						invoke _WriteLog,WLT_LOADMELERR,offset szInnerName,ecx,offset szWltEMem1
						jmp _CtnLM
					.endif
					mov [esi].lpMefInfo2,eax
					push eax
					call edi
					mov ecx,[esi].lpMefInfo2
					mov eax,_MefInfo2.nInterfaceVer[ecx]
					shr eax,16
					.if eax!=(TXTINTERFACE_VER shr 16)
						lea ecx,@stFindData.cFileName
						invoke _WriteLog,WLT_LOADMELERR,offset szInnerName,ecx,offset szWltEMel2
						jmp _CtnLM
					.endif
					invoke GetProcAddress,[esi].hModule,offset szFProcessLine
					.if !eax
						lea edi,@stFindData.cFileName
						jmp _BadMel
					.endif
					mov [esi].ProcessLine,eax
				.endif
				add esi,sizeof _MefInfo
				inc ebx
_CtnLM:
				invoke FindNextFileW,@hFind,addr @stFindData
			.until eax==FALSE || ebx>=MAX_MELCOUNT-1
			mov nMefs,ebx
_Ex2LM:
			invoke FindClose,@hFind
			assume esi:nothing
		.endif
	.endif
_ExLM:
	
	xor eax,eax
	ret
_LoadMef endp

;对每个插件进行匹配，返回值：
;大于等于0即为匹配成功的插件的索引值，-1为内置匹配成功，-2为匹配失败，-3为匹配过程中发生错误
_TryMatch proc uses edi esi ebx _lpszName
	LOCAL @pFunc[MAX_MELCOUNT]:dword
	LOCAL @pstr
	push _HandlerTM
	push fs:[0]
	mov fs:[0],esp
	cmp lpMels,0
	je _SelfMatchTM
	mov edi,dbConf+_Configs.lpDefaultMel
	.if edi && word ptr [edi]
		invoke _FindPlugin,edi,1
		mov ebx,ecx
		.if eax!=-1 && eax!=-2
			mov esi,eax
			assume esi:ptr _MelInfo
			push _lpszName
			call [esi].pMatch
			.if eax==MR_NO
				invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
				mov @pstr,eax
				mov eax,IDS_NOTDEFMEL
				invoke _GetConstString
				invoke wsprintfW,@pstr,eax,edi
				mov eax,IDS_WINDOWTITLE
				invoke _GetConstString
				invoke MessageBoxW,hWinMain,@pstr,eax,MB_YESNO or MB_DEFBUTTON2
				mov esi,eax
				invoke HeapFree,hGlobalHeap,0,@pstr
				cmp esi,IDNO
				je _lbl1
			.endif
			assume esi:nothing
			mov eax,ebx
			jmp _ExTM
		.endif
	.endif
_lbl1:
	lea esi,@pFunc
	mov edi,esi
	or eax,-1
	mov ecx,MAX_MELCOUNT
	rep stosd
	xor ebx,ebx
	mov edi,lpMels
	assume edi:ptr _MelInfo
	.while ebx<nMels
		push _lpszName
		call [edi].pMatch
		.if eax==MR_YES
			mov eax,ebx
			jmp _ExTM
		.elseif eax==MR_MAYBE
			mov [esi],ebx
			add esi,4
		.endif
		inc ebx
		add edi,sizeof _MelInfo
	.endw
	assume edi:nothing
	lea esi,@pFunc
	.if dword ptr [esi]!=-1
		invoke DialogBoxParamW,hInstance,IDD_CHOOSEMEL,hWinMain,offset _WndCMProc,esi
	.else
_SelfMatchTM:
		invoke _SelfMatch,_lpszName
		.if eax==MR_YES
			or eax,-1
		.else
			invoke DialogBoxParamW,hInstance,IDD_CHOOSEMEL,hWinMain,offset _WndCMProc,0;此参数存储显示在列表中的插件序号，为0则全部显示
		.endif
	.endif
_ExTM:
	pop fs:[0]
	pop ecx
	ret
_HandlerTM:
	mov eax,[esp+0ch]
	mov [eax+0b8h],offset _ExTM
	mov dword ptr [eax+0b0h],-3
	xor eax,eax
	retn 0ch
_TryMatch endp

;内置匹配函数
_SelfMatch proc uses esi edi ebx _lpszName
	LOCAL @hFile,@lpBuff
	LOCAL @buff[8]:byte
	invoke CreateFileW,_lpszName,GENERIC_READ,FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax==-1
		ret
	.endif
	mov @hFile,eax
	invoke ReadFile,@hFile,addr @buff,4,offset dwTemp,0
	or eax,eax
	je _ErrSM
	cmp word ptr [@buff],0feffh
	je _OKSM
	mov eax,dword ptr [@buff]
	and eax,0ffffffh
	cmp eax,0bfbbefh
	je _OKSM
	invoke GetFileSizeEx,@hFile,addr @buff
	invoke SetFilePointer,@hFile,0,0,FILE_BEGIN
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,512
	or eax,eax
	je _ErrSM
	mov @lpBuff,eax
	mov eax,dword ptr @buff
	.if eax>512
		mov eax,512
	.endif
	invoke ReadFile,@hFile,@lpBuff,eax,offset dwTemp,0
	.if !eax
		invoke HeapFree,hGlobalHeap,0,@lpBuff
		jmp _ErrSM
	.endif
	mov edi,@lpBuff
	mov ecx,511
	xor ebx,ebx
	@@:
	.if word ptr [edi]==0a0dh
		inc ebx
		jmp @F
	.endif
	inc edi
	loop @B
	@@:
	invoke HeapFree,hGlobalHeap,0,@lpBuff
	or ebx,ebx
	je _NOSM
_OKSM:
	invoke CloseHandle,@hFile
	mov eax,MR_YES
	jmp _ExSM
_NOSM:
	invoke CloseHandle,@hFile
	mov eax,MR_NO
	jmp _ExSM
_ErrSM:
	invoke CloseHandle,@hFile
	mov eax,MR_ERR
_ExSM:
	ret
_SelfMatch endp

;内置预处理函数，把所有可重载函数恢复为默认
_SelfPreProc proc
	invoke _RestoreFunc,lpOriFuncTable
	mov nCurMel,-1
	ret
_SelfPreProc endp

;所有可重载函数恢复为默认
_RestoreFunc proc uses esi edi _lpFT
	mov esi,_lpFT
	lea edi,dbFunc
	mov ecx,sizeof _Functions
	invoke _memcpy
	lea edi,dbSimpFunc
	mov ecx,sizeof _SimpFunc
	invoke _memcpy
	lea edi,dbTxtFunc
	mov ecx,sizeof _TxtFunc
	invoke _memcpy
	ret
_RestoreFunc endp

_BackupFunc proc uses esi edi _lpFT
	mov edi,_lpFT
	lea esi,dbFunc
	mov ecx,sizeof _Functions
	invoke _memcpy
	lea esi,dbSimpFunc
	mov ecx,sizeof _SimpFunc
	invoke _memcpy
	lea esi,dbTxtFunc
	mov ecx,sizeof _TxtFunc
	invoke _memcpy
	ret
_BackupFunc endp

;重载SimpFunc的几个函数
_GetSimpFunc proc uses edi ebx _hModule,_pSF
	mov edi,_pSF
	assume edi:ptr _SimpFunc
	invoke GetProcAddress,_hModule,offset szFGetText
	.if eax
		mov [edi].GetText,eax
	.endif
	invoke GetProcAddress,_hModule,offset szFModifyLine
	.if eax
		mov [edi].ModifyLine,eax
	.endif
	invoke GetProcAddress,_hModule,offset szFSaveText
	.if eax
		mov [edi].SaveText,eax
	.endif
	invoke GetProcAddress,_hModule,offset szFSetLine
	mov [edi].SetLine,eax
	invoke GetProcAddress,_hModule,offset szFRetLine
	mov [edi].RetLine,eax
	invoke GetProcAddress,_hModule,offset szFRelease
	mov [edi].Release,eax
	
	invoke GetProcAddress,_hModule,offset szFGetStr
	.if eax
		mov [edi].GetStr,eax
	.endif
	assume edi:nothing
	mov eax,1
	ret
_FailGSF:
	xor eax,eax
	ret
_GetSimpFunc endp


end start