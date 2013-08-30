
.data?
	hInstance		dd		?
	hIcon			dd		?
	hMenu			dd		?
	hGlobalHeap		dd		?
	
	hBackDC			dd		?	;´°¿ÚµÄ±³¾°dc
	hBackBmp		dd		?	;´°¿ÚµÄ±³¾°Í¼Æ¬¾ä±ú
	
	lpszConfigFile	dd		?	;ÅäÖÃÎÄ¼þµÄÈ«Â·¾¶
	lpszImagePath	dd		?
	lpArgTbl		dd		?
	nArgc			dd		?
	
	lpStrings		dd		?	;È«¾Ö³£Á¿×Ö·û´®±íÖ¸Õë
	lpMels			dd		?	;ÎÄ±¾ÌáÈ¡²å¼þÐÅÏ¢±íÖ¸Õë
	lpMefs			dd		?	;¹ýÂË²å¼þÐÅÏ¢±íÖ¸Õë
	lpUndo			dd		?	;³·ÏúÁÐ±íÖ¸Õë
	lpPreData		dd		?	;´«µÝ¸øPreProcº¯ÊýµÄ_PreData½á¹¹Ö¸Õë
	lpOriFuncTable	dd		?	;Ô­Ê¼µÄ²Ëµ¥º¯ÊýµØÖ·±í£¬°üÀ¨_FunctionsºÍ_SimpFunc
	
	lpMarkTable		dd		?	;¶ÔÃ¿ÐÐµÄ±ê¼Ç±í£¬´æ´¢ÔÚrecordÎÄ¼þÖÐ
	lpDisp2Real		dd		?	;ÏÔÊ¾³öÀ´µÄÐÐÓëÊµ¼ÊÐÐÊýµÄ¶ÔÓ¦±í
	lpModifyTable	dd		?	;±¾´Î±à¼­ÐÞ¸Ä¹ýµÄÐÐµÄ±ê¼Ç±í
	nStartTime		dd		?	;Æô¶¯±à¼­Æ÷ÒÔÀ´µÄÊ±¼ä
	nFileOpenTime	dd		?	;±¾ÎÄ¼þ´ò¿ªÒÔÀ´µÄÊ±¼ä
	
	nMels			dd		?	;ÎÄ±¾ÌáÈ¡²å¼þµÄÊýÁ¿
	nMefs			dd		?	;ÎÄ±¾¹ýÂË²å¼þµÄÊýÁ¿
	nCurMel			dd		?	;µ±Ç°Ê¹ÓÃµÄÎÄ±¾ÌáÈ¡²å¼þ±àºÅ£¨ÔÚlpMelsÖÐµÄÎ»ÖÃ£©
	nCurIdx			dd		?	;µ±Ç°±à¼­ÐÐ
	
	bOpen			dd		?	;±à¼­Æ÷ÊÇ·ñ´ò¿ªÁËÎÄ¼þ
	bModified		dd		?	;ÎÄ¼þ±¾´Î´ò¿ªÊÇ·ñ±»ÐÞ¸Ä¹ý
	nUIStatus		dd		?	;UI×´Ì¬,UIS_XXX

	hLogFile		dd		?	;ÈÕÖ¾ÎÄ¼þ¾ä±ú
	
;µ±Ç°ÎÄ¼þÐÅÏ¢
	FileInfo1			_FileInfo	<>
	FileInfo2			_FileInfo	<>
;
	FindInfo			_FindInfo	<>
	
;´°¿Ú¾ä±ú
	hWinMain		dd		?
	hList1			dd		?
	hList2			dd		?
	hEdit1			dd		?
	hEdit2			dd		?
	hStatus			dd		?
;	hCode1O			dd		?
;	hCode1N			dd		?
;	hCode2O			dd		?
;	hCode2N			dd		?

;¿ØÖÆÌ¨¾ä±ú
	hStdInput		dd		?
	hStdOutput		dd		?

;×ÖÌå¾ä±ú
	hFontList		dd		?
	hFontEdit		dd		?
	
;Å¶ºÇºÇ
	dwTemp			dd		?
	gszTemp			db		512	dup (?)
	gszTemp2		db		512	dup (?)

.data
	nCurMef			dd		-1	;µ±Ç°Ê¹ÓÃµÄ¹ýÂËÆ÷Ë÷Òý
	hRegSelText		dd		-1	;Æ¥ÅäÎÄ±¾¿òÑ¡ÇøµÄ¾ä±ú

.data
	szNULL			dd		0
	TW0			'Multiline Editor',	szDisplayName
	TW0			'lnedit',			szInnerName
	TW0			'defaultedit',		szDefaultPluginName
	TW0			' v2.1',			szDisplayVer
	TW0			'2.1.2.698',		szFullVer
	szMemErr		dw		'N','o','t',' ','e','n','o','u','g','h',' ','m','e','m','o','r','y','!',0
	szOpenFilter		dw		'A','l','l',' ','F','i','l','e','s','(','*','.','*',')',0,'*','.','*',0,0
	szTxtFilter		dw		'T','X','T',' ','F','i','l','e','(','*','.','t','x','t',')',0,'*','.','t','x','t',0,0
	TW			'Image File\{*.bmp;*.jpg,*.',		szImageFilter
	TW0			'gif\}\0*.bmp;*.jpg;*.gif\0'
	TW0			'mel',			szDLLDir
	TW0			'mel\\',		szDLLDir2
	TW0			'*.mel',		szMelFile
	TW0			'*.mef',		szMefFile
	szTxt			dw		'.','t','x','t',0
	TW0			'Rec',			szRecDir
	TW0			'.rec',			szRecExt
	
	TW0			'.\\NewSC',		szNewScDir
	TW0			'rsltln.txt',		szSearchResult
	TW0			'%s\t\t%d\t%s\r\n',	szSearchFormat
	TW0			'open',			szSearchOpen
	
	szCList			dw		'l','i','s','t','b','o','x',0
	szCEdit			dw		'e','d','i','t',0
	szCStatic			dw		's','t','a','t','i','c',0
	TW0			'combobox',		szCCombobox
	szCNewEdit		dw		'e','d','i','t','A','m','a','f',0
	szCNewList		dw		'l','i','s','t','A','m','a','f',0
	
	szFInitInfo		db		'InitInfo',0
	szFMatch			db		'Match',0
	szFPreProc		db		'PreProc',0
	szFGetText		db		'GetText',0
	szFSaveText		db		'SaveText',0
	szFModifyLine	db		'ModifyLine',0
	szFSetLine		db		'SetLine',0
	szFRetLine		db		'RetLine',0
	szFRelease		db		'Release',0
	szFGetStr		db		'GetStr',0
	
	szFProcessLine	db		'ProcessLine',0

.data
	TW0		'%d',		szToStr
	TW0		'0x%08X',		szToStrH
	TW0		' - ',			szGang
	TW0		'* ',			szXing
	TW0		'%d/%d',		szLinesFormat
	TW0		'\r\n',		szCRSymbol


.data
;Function Table
	dbFunc		dd	offset _OpenScript2
				dd	offset _LoadScript
				dd	offset _SaveScript
				dd	offset _SaveAs
				dd	offset _CloseScript
				dd	offset _SetCode
				dd	offset _ExportTxt
				dd	offset _ImportTxt
				dd	offset _Exit
				dd	0
				dd	offset _Undo
				dd	offset _Redo
				dd	offset _Modify
				dd	offset _PrevLine
				dd	offset _NextLine
				dd	offset _MarkLine
				dd	offset _PrevMark
				dd	offset _NextMark
				dd	offset _Find
				dd	offset _Replace
				dd	offset _SummaryFind
				dd	offset _Gotoline
				dd	0
				dd	offset _SetFont
				dd	offset _SetBackground
				dd	offset _CustomUI
				dd	offset _RecoverUI
				dd	0
				dd	offset _ExportAll
				dd	offset _ImportAll
				dd	offset _SummaryFindAll
				dd	0
				dd	offset _Config
				dd	0
				dd	offset _About
				dd	0
				dd	offset _ToFull
				dd	offset _ToHalf
				dd	offset _UnmarkAll
				dd	offset _Progress			;10040
				dd	offset _TxtFilter
				dd	10	dup(0)
	
	dbSimpFunc	dd	offset _GetText
				dd	offset _SaveText
				dd	offset _ModifyLine
				dd	offset _SetLine
				dd	0
				dd	0
				dd	offset _GetStringFromStmPtr
				
	dbTxtFunc	dd	0
				dd	0
				
	dbMelInfo2	_MelInfo2		<INTERFACE_VER,0>


.data
;Global Configs
	dbConf			dd			EM_SINGLE
					dd			120
					dd			NL_CURRENT
					DD			AC_NOT
					dd			CS_GBK
					
					dd			TRUE
					dd			FALSE
					dd			TRUE
					dd			TRUE
					
					dd			NULL
					dd			NULL
					dd			NULL
					dd			NULL
					dd			NULL
					
					dd			FALSE
					dd			FALSE
					dd			FALSE
					dd			NULL
					_TextFilter	<>
					
					dd			NULL
					dd			000040ffh
					dd			00000000h
					dd			00000000h
					dd			00ff0000h
					dd			00ffcc99h
					dd			0000ff12h
					LOGFONT	<-14,0,0,0,190h,0,0,0,86h,3,2,4,22h,'®_oÅ–Ñž'>
					db	32	dup(0)
					LOGFONT	<-14,0,0,0,190h,0,0,0,86h,3,2,4,22h,'®_oÅ–Ñž'>
					db	32	dup(0)
;					LOGFONT	<-12,0,0,0,190h,0,0,0,86h,3,2,0,22h,'‹[SO'>
;					LOGFONT	<-12,0,0,0,190h,0,0,0,86h,3,2,0,22h,'‹[SO'>
					
					RECT		<CW_USEDEFAULT,CW_USEDEFAULT,800,600>
					RECT		<10,15,370,400>
					RECT		<410,15,370,400>
					RECT		<20,440,700,40>
					RECT		<20,500,700,40>
					RECT		<20,420,700,15>
;					;ÒÔÏÂÊÇËÄ¸ö±àÂë¿ò
;					RECT		<30,10,140,12>
;					RECT		<0,0,0,0>
;					RECT		<430,10,140,12>
;					RECT		<620,10,140,12>
	
.data
	TW0		'lnedit.ini',		szcfFileName
	
	TW0		'Settings',			szcfSett
	TW0		'TXTFilter',		szcfTxtFlt
	TW0		'UserInterface',	szcfUI
	
	TW0		'EditMode',			szcfEM
	TW0		'AutoSaveTime',		szcfAST
	TW0		'AutoCode',			szcfACD
	TW0		'NewScSaveLoc',		szcfNSSL
	TW0		'SaveInChangingLine',	szcfSCL
	TW0		'AutoSelectText',	szcfASL
	TW0		'AutoConvert',		szcfAC
	TW0		'AutoOpenOldFile',	szcfAO
	TW0		'AutoUpdate',		szcfAutoUpdate
	
	TW0		'DefaultMel',		szcfDM
	TW0		'InitDir1',			szcfID1
	TW0		'InitDir2',			szcfID2
	TW0		'NewScDir',			szcfNSD
	TW0		'OldFileName',		szcfPF
	
	TW0		'TextColorS',		szcfTCS
	TW0		'TextColorD',		szcfTCD
	TW0		'TextColorE',		szcfTCE
	TW0		'LineColor',		szcfLC
	TW0		'ListboxFont',		szcfLF
	TW0		'HighlightColorDefault',	szcfHCD
	TW0		'HighlightColorMarked',	szcfHCM
	TW0		'EditFont',			szcfEF
	TW0		'BackPicture',		szcfBP
	TW0		'WindowsLoc',		szcfWL
	
	TW0		'AlwaysFilter',		szcfAlwaysFlt
	TW0		'IncludeOn',		szcfInOn
	TW0		'IncludePattern',	szcfInPtn
	TW0		'ExcludeOn',		szcfExOn
	TW0		'ExcludePattern',	szcfExPtn
	TW0		'TrimHeadOn',		szcfHeadOn
	TW0		'TrimHeadPattern',	szcfHeadPtn
	TW0		'TrimTailOn',		szcfTailOn
	TW0		'TrimTailPattern',	szcfTailPtn
	
	TW0		'AlwaysFilterPlugin',	szcfAlwaysFltPlugin
	TW0		'FilterPluginOn',	szcfFltPluginOn
	TW0		'FilterPlugin',		szcfFltPlugin
	
	dbConfigsOfTxtFilter	dd	offset szcfInOn,offset szcfInPtn
						dd	offset szcfExOn,offset szcfExPtn
						dd	offset szcfHeadOn,offset szcfHeadPtn
						dd	offset szcfTailOn,offset szcfTailPtn

.data
	TW0		'Not Convert',		szcdNotConvert
	
	TW0		'UNKNOWN(0)',		szcdDefault
	TW0		'GBK(936)',			szcdGBK
	TW0		'Shift-JIS(932)',	szcdSJIS
	TW0		'BIG5(950)',		szcdBig5
	TW0		'UTF-8(65001)',		szcdUTF8
	TW0		'UNICODE(-1)',		szcdUnicode
	
	dbCodeTable		dd		0,936,932,950,65001,-1

