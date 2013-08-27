.code

_Config proc
	invoke DialogBoxParamW,hInstance,IDD_CONFIG,hWinMain,offset _WndConfigProc,0
	ret
_Config endp

;
_WndConfigProc proc uses ebx edi esi,hwnd,uMsg,wParam,lParam
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if eax==IDC_CF_OK
			invoke IsDlgButtonChecked,hwnd,IDC_CF_MODE_DOUBLE
			inc eax
			mov dbConf+_Configs.nEditMode,eax
			invoke GetDlgItemInt,hwnd,IDC_CF_AUTOTIME,offset dwTemp,FALSE
			.if !dwTemp
				mov eax,60
			.endif
			mov dbConf+_Configs.nAutoSaveTime,eax
			invoke IsDlgButtonChecked,hwnd,IDC_CF_LOC_EXE
			inc eax
			mov dbConf+_Configs.nNewLoc,eax
			invoke IsDlgButtonChecked,hwnd,IDC_CF_AC_NOT
			.if eax
				mov dbConf+_Configs.nAutoConvert,0
			.else
				invoke IsDlgButtonChecked,hwnd,IDC_CF_AC_HALF
				inc eax
				mov dbConf+_Configs.nAutoConvert,eax
			.endif
			invoke IsDlgButtonChecked,hwnd,IDC_CF_AUTOOPEN
			mov dbConf+_Configs.bAutoOpen,eax
			invoke IsDlgButtonChecked,hwnd,IDC_CF_AUTOSELECT
			mov dbConf+_Configs.bAutoSelText,eax
			invoke IsDlgButtonChecked,hwnd,IDC_CF_AUTOUPDATE
			mov dbConf+_Configs.bAutoUpdate,eax
			invoke SendDlgItemMessageW,hwnd,IDC_CF_SAVEWITHCODE,CB_GETCURSEL,0,0
			mov ecx,dword ptr [eax*4+dbCodeTable]
			mov dbConf+_Configs.nAutoCode,ecx
			invoke _SaveConfig
			jmp @F
		.elseif eax==IDCANCEL
		@@:
			invoke EndDialog,hwnd,0
		.endif
	.elseif eax==WM_INITDIALOG
		mov eax,dbConf+_Configs.nEditMode
		add eax,IDC_CF_MODE_SINGLE-EM_SINGLE
		invoke CheckRadioButton,hwnd,IDC_CF_MODE_SINGLE,IDC_CF_MODE_DOUBLE,eax
		invoke SetDlgItemInt,hwnd,IDC_CF_AUTOTIME,dbConf+_Configs.nAutoSaveTime,FALSE
		mov eax,dbConf+_Configs.nNewLoc
		add eax,IDC_CF_LOC_CURRENT-NL_CURRENT
		invoke CheckRadioButton,hwnd,IDC_CF_LOC_CURRENT,IDC_CF_LOC_EXE,eax
		mov eax,dbConf+_Configs.nAutoConvert
		add eax,IDC_CF_AC_NOT-AC_NOT
		invoke CheckRadioButton,hwnd,IDC_CF_AC_NOT,IDC_CF_AC_HALF,eax
		invoke CheckDlgButton,hwnd,IDC_CF_AUTOOPEN,dbConf+_Configs.bAutoOpen
		invoke CheckDlgButton,hwnd,IDC_CF_AUTOSELECT,dbConf+_Configs.bAutoSelText
		invoke CheckDlgButton,hwnd,IDC_CF_AUTOUPDATE,dbConf+_Configs.bAutoUpdate
		invoke GetDlgItem,hwnd,IDC_CF_SAVEWITHCODE
		mov ebx,eax
		invoke SendMessageW,ebx,CB_ADDSTRING,0,offset szcdNotConvert
		invoke SendMessageW,ebx,CB_ADDSTRING,0,offset szcdGBK
		invoke SendMessageW,ebx,CB_ADDSTRING,0,offset szcdSJIS
		invoke SendMessageW,ebx,CB_ADDSTRING,0,offset szcdUTF8
		invoke _GetCodeIndex,dbConf+_Configs.nAutoCode
		invoke SendDlgItemMessageW,hwnd,IDC_CF_SAVEWITHCODE,CB_SETCURSEL,eax,0
	.elseif eax==WM_CLOSE
		invoke EndDialog,hwnd,0
	.endif
	xor eax,eax
	ret
_WndConfigProc endp

_TxtFilter proc
	invoke DialogBoxParamW,hInstance,IDD_TXTFILTER,hWinMain,offset _WndFilterProc,0
	ret
_TxtFilter endp

_WndFilterProc proc uses ebx edi esi,hwnd,uMsg,wParam,lParam
	LOCAL @szStr[MAX_STRINGLEN]:byte
	mov eax,uMsg
	.if eax==WM_COMMAND
		mov eax,wParam
		.if ax==IDC_TF_OK
			invoke IsDlgButtonChecked,hwnd,IDC_TF_ALWAYSAPPLY
			mov dbConf+_Configs.bAlwaysFilter,eax
			invoke IsDlgButtonChecked,hwnd,IDC_TF_INON
			mov byte ptr _Configs.TxtFilter.bInclude[dbConf],al
			invoke IsDlgButtonChecked,hwnd,IDC_TF_EXON
			mov byte ptr dbConf+_Configs.TxtFilter.bExclude,al
			invoke IsDlgButtonChecked,hwnd,IDC_TF_HEADON
			mov byte ptr dbConf+_Configs.TxtFilter.bTrimHead,al
			invoke IsDlgButtonChecked,hwnd,IDC_TF_TAILON
			mov byte ptr dbConf+_Configs.TxtFilter.bTrimTail,al
			invoke GetDlgItemTextW,hwnd,IDC_TF_INPTN,dbConf+_Configs.TxtFilter.lpszInclude,MAX_STRINGLEN/2
			invoke GetDlgItemTextW,hwnd,IDC_TF_EXPTN,dbConf+_Configs.TxtFilter.lpszExclude,MAX_STRINGLEN/2
			invoke GetDlgItemTextW,hwnd,IDC_TF_HEADPTN,dbConf+_Configs.TxtFilter.lpszTrimHead,MAX_STRINGLEN/2
			invoke GetDlgItemTextW,hwnd,IDC_TF_TAILPTN,dbConf+_Configs.TxtFilter.lpszTrimTail,MAX_STRINGLEN/2
			invoke IsDlgButtonChecked,hwnd,IDC_TF_USEPLUGIN
			mov dbConf+_Configs.bFilterPluginOn,eax
			invoke IsDlgButtonChecked,hwnd,IDC_TF_ALWAYSPLUGIN
			mov dbConf+_Configs.bAlwaysFilterPlugin,eax
			
			.if dbConf+_Configs.bFilterPluginOn
				invoke SendDlgItemMessageW,hwnd,IDC_TF_PLUGINCOMBO,CB_GETCURSEL,0,0
				mov nCurMef,eax
				mov ecx,sizeof _MefInfo
				mul ecx
				add eax,lpMefs
				invoke lstrcpyW,dbConf+_Configs.lpDefaultMef,eax
			.else
				mov nCurMef,-1
			.endif
			
			.if bOpen
				invoke _GetMelInfo2,nCurMel
				mov ebx,eax
				.if _MelInfo2.nCharacteristic[ebx]
					mov ecx,TRUE
				.else
					mov ecx,FALSE
				.endif
				invoke _RecodeFile,offset FileInfo1,TRUE,ecx
				.if eax
				_FilterErr:
					mov eax,IDS_FILTERPLUGINERR2
				_FilterErr2:
					invoke _GetConstString
					invoke MessageBoxW,hwnd,eax,0,MB_ICONERROR
					invoke PostMessageW,hWinMain,WM_COMMAND,IDM_CLOSE,0
					jmp _ExitF
				.endif
				.if _MelInfo2.nCharacteristic[ebx]
					mov ecx,TRUE
				.else
					mov ecx,FALSE
				.endif
				invoke _RecodeFile,offset FileInfo2,TRUE,ecx
				test eax,eax
				jnz _FilterErr
				mov eax,FileInfo1.nLine
				.if eax!=FileInfo2.nLine
					mov eax,IDS_FILTERPLUGINERR1
					jmp _FilterErr2
				.endif
				.if FileInfo1.nMemoryType==MT_POINTERONLY
					invoke _MakeStringListFromStream,offset FileInfo1
					test eax,eax
					jnz _FilterErr
					invoke _MakeStringListFromStream,offset FileInfo2
					test eax,eax
					jnz _FilterErr
				.endif
			.endif
			
			invoke SendMessageW,hList1,LB_GETCURSEL,0,1
			mov nCurIdx,eax
			
			invoke _ResetHideTable,offset FileInfo1
			invoke _UpdateHideTable,offset FileInfo1
			
			invoke SendMessageW,hList1,LB_RESETCONTENT,0,0
			invoke SendMessageW,hList2,LB_RESETCONTENT,0,0
			
			mov bProgBarStopping1,0
			mov bProgBarStopping2,0
			invoke _AddLinesToList,offset FileInfo1,hList1,offset bProgBarStopping1
			invoke _AddLinesToList,offset FileInfo2,hList2,offset bProgBarStopping2
			jmp _ExitF
		.elseif ax==IDC_TF_USEPLUGIN
			invoke IsDlgButtonChecked,hwnd,IDC_TF_USEPLUGIN
			mov ebx,eax
			invoke GetDlgItem,hwnd,IDC_TF_ALWAYSPLUGIN
			invoke EnableWindow,eax,ebx
			invoke GetDlgItem,hwnd,IDC_TF_PLUGINCOMBO
			invoke EnableWindow,eax,ebx
		.elseif ax==IDC_TF_PLUGINCOMBO
			shr eax,16
			.if ax==CBN_SELCHANGE
				invoke SendDlgItemMessageW,hwnd,IDC_TF_PLUGINCOMBO,CB_GETCURSEL,0,0
				mov ecx,sizeof _MefInfo
				mul ecx
				add eax,lpMefs
				lea ecx,@szStr
				invoke _GetMelInfo,eax,ecx,VT_FILEDESC
				invoke SetDlgItemTextW,hwnd,IDC_TF_PLUGINDESC,addr @szStr
			.endif
		.endif
		cmp ax,IDC_TF_CANCEL
		je _ExitF
	.elseif eax==WM_INITDIALOG
		invoke CheckDlgButton,hwnd,IDC_TF_ALWAYSAPPLY,dbConf+_Configs.bAlwaysFilter
		movzx eax,byte ptr dbConf+_Configs.TxtFilter.bInclude
		invoke CheckDlgButton,hwnd,IDC_TF_INON,eax
		movzx eax,byte ptr dbConf+_Configs.TxtFilter.bExclude
		invoke CheckDlgButton,hwnd,IDC_TF_EXON,eax
		movzx eax,byte ptr dbConf+_Configs.TxtFilter.bTrimHead
		invoke CheckDlgButton,hwnd,IDC_TF_HEADON,eax
		movzx eax,byte ptr dbConf+_Configs.TxtFilter.bTrimTail
		invoke CheckDlgButton,hwnd,IDC_TF_TAILON,eax
		invoke SetDlgItemTextW,hwnd,IDC_TF_INPTN,dbConf+_Configs.TxtFilter.lpszInclude
		invoke SetDlgItemTextW,hwnd,IDC_TF_EXPTN,dbConf+_Configs.TxtFilter.lpszExclude
		invoke SetDlgItemTextW,hwnd,IDC_TF_HEADPTN,dbConf+_Configs.TxtFilter.lpszTrimHead
		invoke SetDlgItemTextW,hwnd,IDC_TF_TAILPTN,dbConf+_Configs.TxtFilter.lpszTrimTail
		
		invoke GetDlgItem,hwnd,IDC_TF_PLUGINCOMBO
		mov ebx,eax
		mov edi,lpMefs
		.while word ptr [edi]
			invoke _GetMelInfo,edi,addr @szStr,VT_PRODUCTNAME
			invoke SendMessageW,ebx,CB_ADDSTRING,0,addr @szStr
			
			add edi,sizeof _MefInfo
		.endw
		invoke SendMessageW,ebx,CB_SETCURSEL,0,0
		mov edi,dbConf+_Configs.lpDefaultMef
		.if word ptr [edi]
			invoke _FindPlugin,edi,2
			.if eax!=-2 && eax!=-1
				mov esi,ecx
				lea ecx,@szStr
				invoke _GetMelInfo,eax,ecx,VT_FILEDESC
				invoke SetDlgItemTextW,hwnd,IDC_TF_PLUGINDESC,addr @szStr
				invoke SendMessageW,ebx,CB_SETCURSEL,esi,0
			.endif
		.endif
		invoke CheckDlgButton,hwnd,IDC_TF_USEPLUGIN,dbConf+_Configs.bFilterPluginOn
		invoke CheckDlgButton,hwnd,IDC_TF_ALWAYSPLUGIN,dbConf+_Configs.bAlwaysFilterPlugin
		.if !dbConf+_Configs.bFilterPluginOn
			invoke GetDlgItem,hwnd,IDC_TF_ALWAYSPLUGIN
			invoke EnableWindow,eax,FALSE
			invoke GetDlgItem,hwnd,IDC_TF_PLUGINCOMBO
			invoke EnableWindow,eax,FALSE
		.endif
	.elseif eax==WM_CLOSE
	_ExitF:
		invoke EndDialog,hwnd,0
	.endif
	xor eax,eax
	ret
_WndFilterProc endp

