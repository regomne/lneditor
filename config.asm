.code

;载入lnedit.ini
_LoadConfig proc uses ebx
	LOCAL @s[32]:byte
	
	invoke HeapAlloc,hGlobalHeap,0,MAX_STRINGLEN
	or eax,eax
	je _NomemLC
	mov lpszConfigFile,eax
	invoke GetFullPathNameW,offset szcfFileName,MAX_STRINGLEN/2,eax,0
	
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,SHORT_STRINGLEN
	or eax,eax
	je _NomemLC
	mov dbConf+_Configs.lpDefaultMel,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,SHORT_STRINGLEN
	or eax,eax
	je _NomemLC
	mov dbConf+_Configs.lpDefaultMef,eax
		
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
	or eax,eax
	je _NomemLC
	mov dbConf+_Configs.lpInitDir1,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
	or eax,eax
	je _NomemLC
	mov dbConf+_Configs.lpInitDir2,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,SHORT_STRINGLEN
	or eax,eax
	je _NomemLC
	mov dbConf+_Configs.lpNewScDir,eax
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
	or eax,eax
	je _NomemLC
	mov dbConf+_Configs.lpPrevFile,eax
	xor ebx,ebx
	.while ebx<4
		invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
		or eax,eax
		je _NomemLC
		mov [ebx*4+4+offset dbConf+_Configs.TxtFilter],eax
		inc ebx
	.endw
	invoke HeapAlloc,hGlobalHeap,HEAP_ZERO_MEMORY,MAX_STRINGLEN
	or eax,eax
	je _NomemLC
	mov dbConf+_Configs.lpBackName,eax
	invoke CreateFileW,lpszConfigFile,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax==-1
		invoke GetLastError
		.if eax!=ERROR_FILE_NOT_FOUND
			mov eax,IDS_CANTOPENCONFIG
			invoke _GetConstString
			invoke MessageBoxW,0,eax,0,MB_OK or MB_ICONERROR
			invoke ExitProcess,0
		.endif
		invoke lstrcpyW,dbConf+_Configs.lpNewScDir,offset szNewScDir
		invoke _SaveConfig
	.else
		invoke CloseHandle,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfEM,dbConf+_Configs.nEditMode,lpszConfigFile
		mov dbConf+_Configs.nEditMode,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfAST,dbConf+_Configs.nAutoSaveTime,lpszConfigFile
		mov dbConf+_Configs.nAutoSaveTime,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfNSSL,dbConf+_Configs.nNewLoc,lpszConfigFile
		mov dbConf+_Configs.nNewLoc,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfACD,dbConf+_Configs.nAutoCode,lpszConfigFile
		mov dbConf+_Configs.nAutoCode,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfAO,dbConf+_Configs.bAutoOpen,lpszConfigFile
		mov dbConf+_Configs.bAutoOpen,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfSCL,dbConf+_Configs.bSaveInChLine,lpszConfigFile
		mov dbConf+_Configs.bSaveInChLine,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfASL,dbConf+_Configs.bAutoSelText,lpszConfigFile
		mov dbConf+_Configs.bAutoSelText,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfAC,dbConf+_Configs.nAutoConvert,lpszConfigFile
		mov dbConf+_Configs.nAutoConvert,eax
		invoke GetPrivateProfileIntW,offset szcfSett,offset szcfAutoUpdate,dbConf+_Configs.bAutoUpdate,lpszConfigFile
		mov dbConf+_Configs.bAutoUpdate,eax
		
		invoke GetPrivateProfileStringW,offset szcfSett,offset szcfDM,NULL,dbConf+_Configs.lpDefaultMel,SHORT_STRINGLEN/2,lpszConfigFile
		invoke GetPrivateProfileStringW,offset szcfSett,offset szcfID1,NULL,dbConf+_Configs.lpInitDir1,MAX_STRINGLEN/2,lpszConfigFile
		invoke GetPrivateProfileStringW,offset szcfSett,offset szcfID2,NULL,dbConf+_Configs.lpInitDir2,MAX_STRINGLEN/2,lpszConfigFile
		invoke GetPrivateProfileStringW,offset szcfSett,offset szcfNSD,NULL,dbConf+_Configs.lpNewScDir,SHORT_STRINGLEN/2,lpszConfigFile
		invoke GetPrivateProfileStringW,offset szcfSett,offset szcfPF,NULL,dbConf+_Configs.lpPrevFile,MAX_STRINGLEN/2,lpszConfigFile
		
		invoke GetPrivateProfileIntW,offset szcfTxtFlt,offset szcfAlwaysFlt,0,lpszConfigFile
		mov dbConf+_Configs.bAlwaysFilter,eax
		xor ebx,ebx
		.while ebx<4
			invoke GetPrivateProfileIntW,offset szcfTxtFlt,[ebx*8+offset dbConfigsOfTxtFilter],0,lpszConfigFile
			mov byte ptr dbConf+_Configs.TxtFilter[ebx],al
			invoke GetPrivateProfileStringW,offset szcfTxtFlt,[ebx*8+offset dbConfigsOfTxtFilter+4],NULL,\
				[ebx*4+4+offset dbConf+_Configs.TxtFilter],MAX_STRINGLEN/2,lpszConfigFile
			inc ebx
		.endw
		invoke GetPrivateProfileIntW,offset szcfTxtFlt,offset szcfAlwaysFltPlugin,0,lpszConfigFile
		mov dbConf+_Configs.bAlwaysFilterPlugin,eax
		invoke GetPrivateProfileIntW,offset szcfTxtFlt,offset szcfFltPluginOn,0,lpszConfigFile
		mov dbConf+_Configs.bFilterPluginOn,eax
		invoke GetPrivateProfileStringW,offset szcfTxtFlt,offset szcfFltPlugin,NULL,dbConf+_Configs.lpDefaultMef,SHORT_STRINGLEN/2,lpszConfigFile
		
		invoke GetPrivateProfileStringW,offset szcfUI,offset szcfBP,NULL,dbConf+_Configs.lpBackName,MAX_STRINGLEN/2,lpszConfigFile
		
		invoke GetPrivateProfileStringW,offset szcfUI,offset szcfTCS,NULL,addr @s,32,lpszConfigFile
		invoke StrToIntExW,addr @s,1,offset dbConf+_Configs.TextColorSelected
		invoke GetPrivateProfileStringW,offset szcfUI,offset szcfTCD,NULL,addr @s,32,lpszConfigFile
		invoke StrToIntExW,addr @s,1,offset dbConf+_Configs.TextColorDefault
		invoke GetPrivateProfileStringW,offset szcfUI,offset szcfTCE,NULL,addr @s,32,lpszConfigFile
		invoke StrToIntExW,addr @s,1,offset dbConf+_Configs.TextColorEdit
		invoke GetPrivateProfileStringW,offset szcfUI,offset szcfLC,NULL,addr @s,32,lpszConfigFile
		invoke StrToIntExW,addr @s,1,offset dbConf+_Configs.LineColor
		invoke GetPrivateProfileStringW,offset szcfUI,offset szcfHCD,NULL,addr @s,32,lpszConfigFile
		invoke StrToIntExW,addr @s,1,offset dbConf+_Configs.HiColorDefault
		invoke GetPrivateProfileStringW,offset szcfUI,offset szcfHCM,NULL,addr @s,32,lpszConfigFile
		invoke StrToIntExW,addr @s,1,offset dbConf+_Configs.HiColorMarked
		
		invoke GetPrivateProfileStructW,offset szcfUI,offset szcfLF,offset dbConf+_Configs.listFont,sizeof LOGFONT+32,lpszConfigFile
		invoke GetPrivateProfileStructW,offset szcfUI,offset szcfEF,offset dbConf+_Configs.editFont,sizeof LOGFONT+32,lpszConfigFile
		invoke GetPrivateProfileStructW,offset szcfUI,offset szcfWL,offset dbConf+_Configs.windowRect,(sizeof RECT)*6,lpszConfigFile
	.endif
	ret
_NomemLC:
	mov eax,IDS_NOMEM
	invoke _GetConstString
	invoke MessageBoxW,0,eax,0,MB_OK or MB_ICONERROR
	invoke ExitProcess,0
_LoadConfig endp

;
_WriteSetting proc _name,_value
	invoke WritePrivateProfileStringW,offset szcfSett,_name,_value,lpszConfigFile
	ret
_WriteSetting endp

_WriteUI proc _name,_value
	invoke WritePrivateProfileStringW,offset szcfUI,_name,_value,lpszConfigFile
	ret
_WriteUI endp

;创建lnedit.ini，把默认配置保存进去
_SaveConfig proc uses ebx
	LOCAL @s[32]:byte
	invoke _Int2Str,dbConf+_Configs.nEditMode,addr @s,FALSE
	invoke _WriteSetting,offset szcfEM,addr @s
	invoke _Int2Str,dbConf+_Configs.nAutoSaveTime,addr @s,FALSE
	invoke _WriteSetting,offset szcfAST,addr @s
	invoke _Int2Str,dbConf+_Configs.nNewLoc,addr @s,FALSE
	invoke _WriteSetting,offset szcfNSSL,addr @s
	invoke _Int2Str,dbConf+_Configs.nAutoCode,addr @s,FALSE
	invoke _WriteSetting,offset szcfACD,addr @s
	invoke _Int2Str,dbConf+_Configs.bAutoOpen,addr @s,FALSE
	invoke _WriteSetting,offset szcfAO,addr @s
	invoke _Int2Str,dbConf+_Configs.bSaveInChLine,addr @s,FALSE
	invoke _WriteSetting,offset szcfSCL,addr @s
	invoke _Int2Str,dbConf+_Configs.bAutoSelText,addr @s,FALSE
	invoke _WriteSetting,offset szcfASL,addr @s
	invoke _Int2Str,dbConf+_Configs.nAutoConvert,addr @s,FALSE
	invoke _WriteSetting,offset szcfAC,addr @s
	invoke _Int2Str,dbConf+_Configs.bAutoUpdate,addr @s,FALSE
	invoke _WriteSetting,offset szcfAutoUpdate,addr @s
	invoke _WriteSetting,offset szcfDM,dbConf+_Configs.lpDefaultMel
	invoke _WriteSetting,offset szcfID1,dbConf+_Configs.lpInitDir1
	invoke _WriteSetting,offset szcfID2,dbConf+_Configs.lpInitDir2
	invoke _WriteSetting,offset szcfNSD,dbConf+_Configs.lpNewScDir
	invoke _WriteSetting,offset szcfPF,dbConf+_Configs.lpPrevFile
	
	invoke _Int2Str,dbConf+_Configs.bAlwaysFilter,addr @s,FALSE
	invoke WritePrivateProfileStringW,offset szcfTxtFlt,offset szcfAlwaysFlt,addr @s,lpszConfigFile
	xor ebx,ebx
	.while ebx<4
		movzx ecx,byte ptr dbConf+_Configs.TxtFilter[ebx]
		invoke _Int2Str,ecx,addr @s,FALSE
		invoke WritePrivateProfileStringW,offset szcfTxtFlt,[ebx*8+offset dbConfigsOfTxtFilter],addr @s,lpszConfigFile
		invoke WritePrivateProfileStringW,offset szcfTxtFlt,[ebx*8+offset dbConfigsOfTxtFilter+4],[ebx*4+4+offset dbConf+_Configs.TxtFilter],lpszConfigFile
		inc ebx
	.endw
	invoke _Int2Str,dbConf+_Configs.bAlwaysFilterPlugin,addr @s,FALSE
	invoke WritePrivateProfileStringW,offset szcfTxtFlt,offset szcfAlwaysFltPlugin,addr @s,lpszConfigFile
	invoke _Int2Str,dbConf+_Configs.bFilterPluginOn,addr @s,FALSE
	invoke WritePrivateProfileStringW,offset szcfTxtFlt,offset szcfFltPluginOn,addr @s,lpszConfigFile
	invoke WritePrivateProfileStringW,offset szcfTxtFlt,offset szcfFltPlugin,dbConf+_Configs.lpDefaultMef,lpszConfigFile
	
	invoke _WriteUI,offset szcfBP,dbConf+_Configs.lpBackName
	invoke _Int2Str,dbConf+_Configs.TextColorSelected,addr @s,TRUE
	invoke _WriteUI,offset szcfTCS,addr @s
	invoke _Int2Str,dbConf+_Configs.TextColorDefault,addr @s,TRUE
	invoke _WriteUI,offset szcfTCD,addr @s
	invoke _Int2Str,dbConf+_Configs.TextColorEdit,addr @s,TRUE
	invoke _WriteUI,offset szcfTCE,addr @s
	invoke _Int2Str,dbConf+_Configs.LineColor,addr @s,TRUE
	invoke _WriteUI,offset szcfLC,addr @s
	invoke _Int2Str,dbConf+_Configs.HiColorDefault,addr @s,TRUE
	invoke _WriteUI,offset szcfHCD,addr @s
	invoke _Int2Str,dbConf+_Configs.HiColorMarked,addr @s,TRUE
	invoke _WriteUI,offset szcfHCM,addr @s
	
	invoke WritePrivateProfileStructW,offset szcfUI,offset szcfLF,offset dbConf+_Configs.listFont,sizeof LOGFONT+32,lpszConfigFile
	invoke WritePrivateProfileStructW,offset szcfUI,offset szcfEF,offset dbConf+_Configs.editFont,sizeof LOGFONT+32,lpszConfigFile
	invoke WritePrivateProfileStructW,offset szcfUI,offset szcfWL,offset dbConf+_Configs.windowRect,(sizeof RECT)*6,lpszConfigFile
	ret
_SaveConfig endp

;转换整数到字符串
_Int2Str proc _nInt,_lpsz,_bHex
	push _nInt
	.if !_bHex
		push offset szToStr
	.else
		push offset szToStrH
	.endif
	push _lpsz
	call wsprintfW
	ret
_Int2Str endp
