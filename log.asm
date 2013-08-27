
.data
TW0		'log.txt',		szLogFileName
dbUBOM		db		0ffh,0feh
TW0		'[%s] %s',	szWltMB
TW0		"[%s]\t%d/%d/%d %02d:%02d:%02d\t",	szWltTime
TW0		'Unknown error.',	szWltUnkError

TW0		'Can\-t load %s. %s\n',	szWltLoadMelErr
TW0		'This is not an available MEL.',szWltEMel1
TW0		'Version too low.',szWltEMel2

TW0		'Update: %s %s\n',	szWltUpdateErr
TW0		'Can\-t download the list file.',		szWltEUpdate1
TW0		'Can\-t download the file:',			szWltEUpdate2
TW0		'File check failed:',			szWltEUpdate3
TW0		'Can\-t access orignal file:',	szWltEUpdate4
TW0		'File updated:',			szWltEUpdateSuccess

TW0		'An error has occurred while importing %s. %s\n',	szWltBImpErr
TW0		'Line %d can\-t be committed to the plugin.',	szWltBImpErr2
TW		'File do not match the plugin ',	szWltEImp1
TW0		'or errors occurred when match.',		__fagaef
TW0		'Can\-t make the new Mark Table cuz nomem.',	szWltEImp2

TW0		'Can\-t load the file.',	szWltEFileLoad
TW0		'Can\-t get text in the file.',	szWltEGetText
TW0		'Can\-t save the file.',	szWltESaveText
TW0		'Can\-t make the string list from the stream.',	szWltEMakeList


TW0		'Not enough memory.',szWltEMem1
TW0		'Mem access error.',	szWltEMem2
TW0		'There is not enough buff.',	szWltEMem3
TW0		'File access error.',		szWltEFileAccess
TW0		'Fatal Error.',	szWltEFatal
TW0		'Wrong format.',	szWltEFormat
TW0		'Can\-t create/open file.',	szWltEFileCreate
TW0		'Can\-t read file.',	szWltEFileRead
TW0		'Can\-t write file.',	szWltEFileWrite

TW0		'Invalid parameter.',	szWltEPara
TW0		'An error has occurred in the plugin.',	szWltEPlugin
TW0		'Failed to analysis the script.',	szWltEAnaFailed

TW0		'The line is not exist.',	szWltELineExist
TW0		'The line is too long',	szWltELineLong
TW0		'The Code Page operation failed',	szWltECode
TW0		'Lines in left and right is not match.',	szWltELineMatch
TW0		'The line is denied by plugin.',		szWltELineDenied


.data
align 4
pWltError1	dd	0,offset szWltEMem1,offset szWltEMem2,offset szWltEMem3,offset szWltEFileAccess,offset szWltEFatal,offset szWltEFormat
			dd	offset szWltEFileCreate,offset szWltEFileRead,offset szWltEFileWrite,offset szWltEPara,offset szWltEPlugin,offset szWltEAnaFailed
pWltError2	dd	offset szWltELineExist,offset szWltELineLong,offset szWltECode,offset szWltELineMatch,offset szWltELineDenied

.code

_OpenLog proc
	invoke CreateFileW,offset szLogFileName,GENERIC_WRITE,FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	mov hLogFile,eax
	.if eax==-1
		invoke CreateFileW,offset szLogFileName,GENERIC_WRITE,FILE_SHARE_READ or FILE_SHARE_WRITE,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
		.if eax==-1 && !(nUIStatus&UIS_CONSOLE)
			mov eax,IDS_LOGFILEOPENNOT
			invoke _GetConstString
			invoke MessageBoxW,0,eax,0,MB_OK or MB_ICONERROR
			ret
		.endif
		mov hLogFile,eax
		invoke WriteFile,eax,offset dbUBOM,2,offset dwTemp,0
	.endif
	invoke SetFilePointer,hLogFile,0,0,FILE_END
	ret
_OpenLog endp

_GetGeneralErrorString proc _nType
	mov ecx,_nType
	.if ecx==-1
		mov eax,offset szWltUnkError
		ret
	.endif
	.if ecx<100h
		lea edx,pWltError1
		mov eax,[edx+ecx*4]
	.else
		lea edx,pWltError2
		sub ecx,100h
		mov eax,[edx+ecx*4]
	.endif
	ret
_GetGeneralErrorString endp

_GetLogString proc uses ebx _nType,_lpszName,para1,para2
	LOCAL @nowtime:SYSTEMTIME
	LOCAL @lpszLog
	invoke HeapAlloc,hGlobalHeap,0,MAX_STRINGLEN
	test eax,eax
	jz _ExGLS
	mov @lpszLog,eax
	.if hLogFile!=-1 && hLogFile
		invoke GetLocalTime,addr @nowtime
		xor eax,eax
		xor ecx,ecx
		mov cx,@nowtime.wSecond
		push ecx
		mov ax,@nowtime.wMinute
		push eax
		mov cx,@nowtime.wHour
		push ecx
		mov ax,@nowtime.wYear
		push eax
		mov cx,@nowtime.wDay
		push ecx
		mov ax,@nowtime.wMonth
		push eax
		push _lpszName
		push offset szWltTime
		push @lpszLog
		call wsprintfW
		add esp,36
		mov ecx,@lpszLog
		lea ebx,[ecx+eax*2]
		mov eax,_nType
		.if eax<10000h
			invoke _GetGeneralErrorString,_nType
			mov para1,eax
			invoke lstrcpyW,ebx,eax
			invoke lstrcatW,ebx,offset szCRSymbol
			invoke lstrlenW,para1
		.elseif eax==WLT_CUSTOM
			invoke lstrcpyW,ebx,para1
		.elseif eax==WLT_BATCHIMPERR
			invoke wsprintfW,ebx,offset szWltBImpErr,para1,para2
		.elseif EAX==WLT_LOADMELERR
			invoke wsprintfW,ebx,offset szWltLoadMelErr,para1,para2
		.elseif eax==WLT_UPDATEERR
			invoke wsprintfW,ebx,offset szWltUpdateErr,para1,para2
		.endif
	.endif
	mov eax,@lpszLog
_ExGLS:
	ret
_GetLogString endp

_OutputMessage proc _nType,_lpszName,para1,para2
	LOCAL @szStr[MAX_STRINGLEN]:byte
	.if nUIStatus & UIS_CONSOLE
		.if _nType<10000h
			invoke _GetGeneralErrorString,_nType
			invoke lstrcpyW,addr @szStr,eax
			invoke lstrcatW,addr @szStr,offset szCRSymbol
			invoke lstrlenW,addr @szStr
			invoke WriteConsoleW,hStdOutput,addr @szStr,eax,offset dwTemp,0
		.endif
	.else ;UIS_WINDOW
		.if nUIStatus & UIS_BUSY
			invoke _WriteLog,_nType,_lpszName,para1,para2
		.else ;UIS_IDLE
			mov eax,_nType
			.if eax<10000h
				invoke _GetGeneralErrorString,_nType
				invoke lstrcpyW,addr @szStr,eax
			.elseif eax==WLT_CUSTOM
				invoke lstrcpyW,addr @szStr,para1
			.elseif eax==WLT_LOADMELERR
				invoke wsprintfW,addr @szStr,offset szWltLoadMelErr,para1,para2
			.elseif eax==WLT_BATCHIMPERR
				invoke wsprintfW,addr @szStr,offset szWltBImpErr,para1,para2
			.elseif eax==WLT_UPDATEERR
				invoke wsprintfW,addr @szStr,offset szWltUpdateErr,para1,para2
			.endif
			invoke MessageBoxW,hWinMain,addr @szStr,_lpszName,MB_OK or MB_ICONINFORMATION
		.endif
	.endif
	ret
_OutputMessage endp

_WriteLog proc uses ebx _nType,_lpszName,para1,para2
	invoke _GetLogString,_nType,_lpszName,para1,para2
	mov ebx,eax
	.if ebx
		invoke lstrlenW,ebx
		shl eax,1
		invoke WriteFile,hLogFile,ebx,eax,offset dwTemp,0
		invoke HeapFree,hGlobalHeap,0,ebx
	.endif
	ret
_WriteLog endp