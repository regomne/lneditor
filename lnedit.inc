;	include windows.inc
	include masm32.inc
	include gdi32.inc
	include user32.inc
	include kernel32.inc
	include Comctl32.inc
	include comdlg32.inc
	include shell32.inc
	include oleaut32.inc
	include msvcrt.inc
	include version.inc
	include shlwapi.inc
	include ntdll.inc
;	include ntddk.inc
	include urlmon.inc
	include macros.asm
	include strings.mac
	include ole32.inc
	include msimg32.inc
	
	includelib masm32.lib
	includelib gdi32.lib
	includelib user32.lib
	includelib kernel32.lib
	includelib Comctl32.lib
	includelib comdlg32.lib
	includelib shell32.lib
	includelib oleaut32.lib
	includelib version.lib
	includelib ntdll.lib
	includelib shlwapi.lib
	includelib advapi32.lib
	includelib ole32.lib
	includelib msimg32.lib
	includelib urlmon.lib
	
ifdef _LN_ZLIBDLL
	includelib bin\zdll.lib
else
	includelib bin\zlib.lib
	
;	includelib uuid.lib
;	includelib msvcrt.lib
;	includelib msvcprt.lib
;;	includelib "D:\WinDDK\7600.16385.1\lib\Mfc\i386\mfc42u.lib"
;;	includelib "D:\WinDDK\7600.16385.1\lib\Mfc\i386\mfcs42u.lib"
;;	includelib "D:\WinDDK\7600.16385.1\lib\wxp\i386\winspool.lib"
;;	includelib "D:\WinDDK\7600.16385.1\lib\wxp\i386\olepro32.lib"
;;	includelib "D:\WinDDK\7600.16385.1\lib\atl\i386\atlthunk.lib"
;	includelib oldnames.lib
endif
	
	include rsrc.inc


TOTAL_STRINGNUM	EQU		100
SHORT_STRINGLEN	EQU		64
MAX_MELCOUNT		EQU		50

UNICODE			EQU		1

IDC_LIST1			EQU		1001
IDC_LIST2			EQU		1002
IDC_EDIT1			EQU		1003
IDC_EDIT2			EQU		1004
IDC_STATUS			EQU		1005
IDC_TIMER			EQU		1

LI_MARGIN_WIDTH	EQU		2
LI_FRAME_WIDTH		EQU		2

REC_MARKTABLE			EQU		1
REC_CHARSET				EQU		2
REC_LINEPOS				EQU		3

WM_LBUPDATE		EQU		WM_USER+2

;Extend larger memory
LM_NONE			EQU		0
LM_HALF				EQU		1
LM_ONE				EQU		2

;Type of GenWindowTitle
GWT_FILENAME1		EQU		1
GWT_FILENAME2		EQU		2
GWT_VERSION			EQU		3
GWT_MODIFIED		EQU		4

arg4 typedef proto :dword,:dword,:dword,:dword

;main file
_WinMain 			proto
_WndMainProc 		proto :dword,:dword,:dword,:dword
_InitWindow 			proto :dword
_LoadSingleMel		proto :dword,:dword
_LoadMel			proto :dword
_LoadMef			proto :dword
_TryMatch			proto :dword
_SelfMatch			proto :dword
_SelfPreProc			proto
_RestoreFunc			proto :dword
_BackupFunc			proto :dword
_GetSimpFunc			proto :dword,:dword

;choosemel dialogbox
_WndCMProc			proto :dword,:dword,:dword,:dword
_GetMelInfo			proto :dword,:dword,:dword

;wildchar support
_WildcharMatchW		proto :dword,:dword
_CharMatchW			proto

;Misc
_GetConstString 		proto
_LoadConfig			proto
_SaveConfig			proto
_Int2Str				proto :dword,:dword,:dword
_OpenFileDlg			proto :dword,:dword,:dword,:dword,:dword
_SaveFileDlg			proto :dword,:dword,:dword,:dword
_memcpy				proto
_DirBackW			proto :dword
_DirFileNameW		proto :dword
_DirCatW				proto :dword,:dword
_DirCmpW			proto :dword,:dword
_DirModifyExtendName proto :dword,:dword
_ClearAll				proto :dword
_LoadFile				proto :dword,:dword,:dword
_SaveOrNot			proto
_AddLinesToList		proto :dword,:dword,:dword
_SetTextToEdit		proto :dword
_GenName2			proto :dword,:dword
_DisplayStatus		proto :dword,:dword
_SaveFile				proto :dword
_SetModified			proto :dword
_SetOpenState		proto :dword
_ShowPic				proto :dword,:dword
_GetStringInList		proto :dword,:dword
_GenWindowTitle		proto :dword,:dword
_ConvertFA			proto :dword,:dword
_CalHeight			proto :dword
_Dev	proto

;Misc2
_MakeStringListFromStream	proto :dword
_GetStringFromStmPtr	proto :dword,:dword,:dword
_RecodeFile			proto :dword,:dword,:dword
_GetMelInfo2			proto :dword
_GetCodeIndex		proto :dword
_AddCodeCombo		proto :dword
_GetDispLine			proto :dword
_GetRealLine			proto :dword
_IsDisplay				proto :dword
_MatchFilter			proto :dword,:dword
_ResetHideTable		proto :dword
_UpdateHideTable		proto :dword
_CalcCenterIndex		proto :dword,:dword
_MakeFile			proto :dword
_MakePath			proto :dword
_CalcCheckSum		proto :dword,:dword
_FindPlugin			proto :dword,:dword
_IsRelativePath		proto :dword

;Record
_ReadRec			proto :dword,:dword,:dword
_WriteRec			proto


;Menu Function
_OpenScript			proto
_OpenScript2			proto :dword
_OpenSingleScript		proto :dword,:dword,:dword
_LoadScript			proto
_SaveScript			proto
_SaveAs				proto
_CloseScript			proto
_SetCode				proto
_WndCodeProc		proto :dword,:dword,:dword,:dword
_ExportTxt			proto
_ExportSingleTxt		proto :dword,:dword
_ImportTxt			proto
_Exit					proto

;edit menu
_Undo				proto
_Redo				proto
_Modify				proto
_ModifyStringInList	proto :dword,:dword,:dword
_PrevLine				proto
_NextLine			proto
_NextLineWithCenter	proto
_MarkLine			proto
_ToFull				proto
_ToHalf				proto
_UnmarkAll			proto
_PrevMark			proto
_NextMark			proto
_Find				proto
_CreateFindWindow	proto :dword
_WndFindProc		proto :dword,:dword,:dword,:dword
_Replace				proto
_CreateReplaceWindow	proto :dword
_WndReplaceProc		proto :dword,:dword,:dword,:dword
_SummarySearch		proto :dword,:dword,:dword,:dword,:dword
_SummaryFind		proto
_WndSSProc			proto :dword,:dword,:dword,:dword
_Gotoline			proto
_WndGTProc		proto :dword,:dword,:dword,:dword
_SetLineInListbox		proto :dword,:dword
_Progress				proto

;UI menu
_SetFont				proto
_WndFontProc		proto :dword,:dword,:dword,:dword
_SetBackground		proto
_CustomUI			proto
_RecoverUI			proto

;assemble menu
_ExportAll			proto
_ExportAllToTxt		proto :dword,:dword,:dword,:dword,:dword,:dword
_WndExpAllProc		proto :dword,:dword,:dword,:dword
_ImportAll			proto
_ImportAllToTxt		proto :dword,:dword,:dword,:dword,:dword,:dword
_WndImpAllProc		proto :dword,:dword,:dword,:dword
_SummaryFindAll		proto
_Config				proto
_WndConfigProc		proto :dword,:dword,:dword,:dword
_TxtFilter				proto
_WndFilterProc			proto :dword,:dword,:dword,:dword
_About				proto
_WndAboutProc		proto :dword,:dword,:dword,:dword

;log
_WriteLog			proto :dword,:dword,:dword,:dword
_OutputMessage		proto :dword,:dword,:dword,:dword
_OpenLog			proto

;default edit
_GetText				proto :dword,:dword
_SaveText			proto :dword
_ModifyLine			proto :dword,:dword
_GetStringInTxt		proto :dword,:dword,:dword
_SetLine				proto :dword,:dword
_ReplaceInMem		proto :dword,:dword,:dword,:dword,:dword

;UI Maker
_ZoomRect			proto :dword,:dword
_LightenColor			proto :dword
_DarkenColor			proto :dword
_SetListTopIndex		proto :dword

;Progress Bar
_WndProgBarProc		proto :dword,:dword,:dword,:dword

;Update
_UpdateThd			proto :dword
_CheckFile			proto :dword,:dword

;cmdmode
_GetCmdOption		proto :dword
_GetCmdOptions		proto :dword
_CmdMain			proto

;zlib
ifdef _LN_ZLIBDLL
compress				proto C :dword,:dword,:dword,:dword
uncompress			proto C :dword,:dword,:dword,:dword
else
compress				proto :dword,:dword,:dword,:dword
uncompress			proto :dword,:dword,:dword,:dword
endif

;System Struct
OFNOTIFY STRUCT
	hdr				NMHDR		<>
	lpOFN			dd		?
	pszFile			dd		?
OFNOTIFY ends



;查找替换信息
_FindInfo struct
	szFind				db		SHORT_STRINGLEN	dup(?)
	szReplace			db		SHORT_STRINGLEN	dup(?)
	hFindWindow			dd		?
_FindInfo ends

;插件信息
_MelInfo struct
	szName				db		SHORT_STRINGLEN	dup(?)	;插件文件名
	hModule				dd		?							;插件句柄
	pMatch				dd		?							;插件的匹配函数指针
	lpMelInfo2			dd		?							;插件详细信息指针
_MelInfo ends

;过滤插件信息
_MefInfo struct
	szName				db		SHORT_STRINGLEN	dup(?)	;
	hModule				dd		?
	dwResv				dd		?
	lpMefInfo2			dd		?
	ProcessLine			dd		?
	RecoverLine			dd		?
_MefInfo ends

;打开脚本时的参数
_OpenParameters struct
	ScriptName		dd		?
	Code1			dd		?
	Code2			dd		?
	Line				dd		?
	Plugin			dd		?
	Filter			dd		?
_OpenParameters ends

;打开过的脚本的记录文件的文件头
_FileRec struct
	szMagic			dd		?	;"MREC"
	nVer				dd		?	;版本
	nPos				dd		?	;上次退出时所在行
	nCharSet1		dd		?	;左列使用的字符集
	nCharSet2		dd		?	;右列使用的字符集
	Reserverd		dd		?
	nOffsetMT		dd		?	;MarkTable的文件偏移
	nLenMT			dd		?	;MarkTable大小，等同于行数
	nOffsetMelName	dd		?	;所使用的插件的名字的偏移，未实装
	nOffsetResv		dd		5	dup(?)
_FileRec ends

_ProgBarInfo struct
	lpszTitle			dd		?
	bNoStop			dd		?
_ProgBarInfo ends

_UpdateFileInfo struct
	lpszName		dd		?
	ftMTime			FILETIME	<>
	nCheckSum		dd		?	;只使用低16bit
	nFlags			dd		?
	nReserved		dd		?
_UpdateFileInfo ends


PUBLIC		hGlobalHeap
PUBLIC		hStdOutput
PUBLIC		hStdInput
public		nUIStatus

public		lpPreData
public		dbConf

public		lpMels
public		nMels
public		nCurMel

public		dbSimpFunc

public		coCmdOptions
public		lpszConfigFile

public		FileInfo1

public		dwTemp