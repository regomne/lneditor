INTERFACE_VER			EQU		00030000h

MAX_STRINGLEN			equ		1024
;错误代码
E_ERROR					EQU		-1
E_NOMEM				EQU		1
E_OVERMEM				EQU		2
E_NOTENOUGHBUFF		EQU		3
E_FILEACCESSERROR		EQU		4
E_FATALERROR			EQU		5
E_WRONGFORMAT			EQU		6
E_FILECREATEERROR		EQU		7
E_FILEREADERROR			EQU		8
E_FILEWRITEERROR			EQU		9
E_INVALIDPARAMETER		EQU		0aH
E_PLUGINERROR			EQU		0bH
E_ANALYSISFAILED			EQU		0CH

E_LINENOTEXIST			EQU		100h
E_LINETOOLONG			EQU		101h
E_CODEFAILED				EQU		102H
E_LINENOTMATCH			EQU		103H
E_LINEDENIED				EQU		104H

WLT_CUSTOM				EQU		10000H
WLT_LOADMELERR			EQU		10001h
WLT_BATCHEXPERR		EQU		10002H
WLT_BATCHIMPERR		EQU		10003H

;Return Information of GetText
RI_SUC_LINEONLY			EQU		1	;文本已提取到内存中，需要主程序将其添加到列表框中
;RI_SUC_LISTADDED			EQU		2	;文本已添加到列表框中
;RI_SUC_THLINE			EQU		3	;已创建线程负责将文本提取到内存中，请在主窗口中处理对应消息将其添加到列表框
;RI_SUC_THLIST			EQU		4	;已创建线程负责将文本添加到列表框中，请在主窗口中处理结束消息

RI_FAIL_FORMAT			EQU		100h	;脚本格式不符
RI_FAIL_MEM				EQU		101h	;内存错误
RI_FAIL_ERRORCS			EQU		102h	;无法接受用户设置的编码
RI_FAIL_UNK				EQU		0ffffh	;未知错误

;Match Result
MR_YES					EQU		5
MR_MAYBE				EQU		3
MR_NO					EQU		0
MR_ERR					EQU		-1

;Memory type for strings
MT_EVERYSTRING			EQU		3
MT_POINTERONLY			EQU		4

;nCharSet域
CS_UNKNOWN			EQU		0
CS_GBK					EQU		936
CS_SJIS					EQU		932
CS_BIG5					EQU		950
CS_UTF8					EQU		65001
CS_UNICODE				EQU		-1

;nStringType域
ST_CUSTOM				EQU		0
ST_ENDWITHZERO			EQU		1
ST_PASCAL2				EQU		2
ST_PASCAL4				EQU		3
ST_TXTENDA				EQU		10h
ST_TXTENDW				EQU		11h

;文件信息
_FileInfo struct
	;以下域由主程序传入插件
	szName				db		MAX_STRINGLEN	dup(?)	;文件名(含路径)
	hFile				dd		?						;文件句柄
	
	lpStream				dd		?						;文件直接读入内存后的指针
	;以下域由插件负责填写
	nMemoryType			dd		?						
	;存储类型详细含义见文档。
	lpTextIndex			dd		?						;纯文本字符串索引表指针。
	lpStreamIndex			dd		?						;可选，原始脚本字符串索引表指针。若为POINTERONLY存储类型，此项必须。
	nStringType			dd		?						;字符串类型。如C字符串、PASCAL字符串等。
	nStreamSize			dd		?						;文件长度。跟随脚本编辑随时更新。
	nLine				dd		?						;文本行数。
;	nLineLen				dd		?						;可选，若使用定长字符串存储，本项须指示字符串长度。独立内存字符串亦可使用。
	
	bReadOnly			dd		?						;指定该文件是否为只读（是否在列表框左侧）
	nCharSet				dd		?						;指示将此文件中字符串解释为何种字符集，用户可以设定，否则插件可自行填写。
	
	lpCustom				dd		?						;插件自行使用。
	Reserved				dd		2		dup(?)
_FileInfo ends

;插件特征
MIC_CUSTOMEDIT			EQU		00000001H	;非标准插件，重载了_Functions中的函数
MIC_CUSTOMTXTPROC		EQU		00000002H	;纯文本专用插件（重载了TXT过滤函数）
MIC_NOPREREAD			EQU		00000004H	;不需要预先将文件读入内存
MIC_CUSTOMGUI			EQU		00000008H	;更改了界面
MIC_CUSTOMCONFIG		EQU		00000010H	;自定义选项

MIC_NOBATCHEXP			EQU		00010000H	;不支持批量导出
MIC_NOBATCHIMP			EQU		00020000H	;不支持批量导入
MIC_NOHALFANGLE		EQU		00040000H	;不支持半角字符

_MelInfo2 struct
	nInterfaceVer			dd		?			;接口版本
	nCharacteristic		dd		?			;插件特征信息
_MelInfo2 ends

;菜单项的处理函数，其中OpenScript之前经过了一些处理，其余均为直接调用。均可被插件重载。
_Functions struct
	OpenScript			dd		?	;10001
	LoadScript			dd		?
	SaveScript			dd		?
	SaveAs				dd		?
	CloseScipt			dd		?
	SetCode				dd		?
	ExportTxt				dd		?
	ImportTxt			dd		?
	Exit					dd		?
	dd	?
	Undo				dd		?
	Redo				dd		?
	Modify				dd		?
	PrevLine				dd		?
	NextLine				dd		?
	MarkLine				dd		?
	PrevMark			dd		?
	NextMark			dd		?
	Find					dd		?
	Replace				dd		?
	SummaryFind			dd		?
	GotoLine				dd		?
	dd	?
	SetFont				dd		?
	SetBackground		dd		?
	CustomUI			dd		?
	RecoverUI			dd		?
	dd	?
	ExportAll				dd		?
	ImportAll				dd		?
	SummaryFindAll		dd		?
	dd	?
	Config				dd		?
	dd	?
	About				dd		?
	dd	?
	ToFull				dd		?
	ToHalf				dd		?
	UnmarkAll			dd		?
	Progress				dd		?		;10040
	TxtFilter				dd		?
	Reserved				dd		10		dup(?)
_Functions ends

;由插件实现简易功能的函数
_SimpFunc struct
	GetText		dd		?	;将脚本中的纯文本按FileInfo结构要求写入
	SaveText		dd		?	;可选，保存文件，如果不实现则通过lpStream和nStreamSize默认保存
	ModifyLine	dd		?	;将修改的行写入脚本
	SetLine		dd		?	;可选，内存中的一行文本被该函数处理之后再显示到编辑框中
	RetLine		dd		?	;可选，编辑框中的一行文本被该函数处理之后再写回内存中
	Release		dd		?	;可选，释放自行分配的内存（只允许此功能）
	GetStr		dd		?	;从Stream指定位置获取字符串
_SimpFunc ends

;纯文本脚本的专用处理函数，可由插件重载
_TxtFunc	struct
	IsLineAdding	dd		?	;在默认GetText函数中调用
	TrimLineHead	dd		?	;在默认GetText函数中调用
_TxtFunc ends

_Handles struct
	hWinMain	dd		?
	hList1		dd		?
	hList2		dd		?
	hEdit1		dd		?
	hEdit2		dd		?
	hStatus		dd		?
_Handles ends

;向插件中的预处理函数传递的结构
_PreData struct
	hGlobalHeap		dd		?	;全局堆
	
	lpszConfigFile		dd		?	;配置文件名，包含全路径
	lpConfigs			dd		?	;配置
	
	lpMenuFuncs		dd		?	;菜单函数表指针，指向_Functions结构
	lpSimpFuncs		dd		?	;简易处理函数表指针，指向_SimpFunc结构
	lpTxtFuncs		dd		?	;纯文本处理函数表指针，指向_TxtFunc结构
	
	lpHandles		dd		?	;窗口句柄列表指针，指向_Handles结构
_PreData ends

_TextFilter struct
	bInclude			db		?
	bExclude			db		?
	bTrimHead		db		?
	bTrimTail			db		?
	lpszInclude		dd		?
	lpszExclude		dd		?
	lpszTrimHead		dd		?
	lpszTrimTail		dd		?
_TextFilter ends

