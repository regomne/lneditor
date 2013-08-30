.data

TW0		'script',		szOptionScriptName
TW0		's',			szOptionScriptNameS
TW0		'code1',		szOptionCode1
TW0		'c1',			szOptionCode1S
TW0		'code2',		szOptionCode2
TW0		'c2',			szOptionCode2S
TW0		'line',		szOptionLine
TW0		'l',			szOptionLineS
TW0		'plugin',		szOptionPlugin
TW0		'p',			szOptionPluginS
TW0		'filter',		szOptionFilter
TW0		'f',			szOptionFilterS
TW0		'import',		szOptionImport
TW0		'i',			szOptionImportS
TW0		'export',		szOptionExport
TW0		'e',			szOptionExportS
TW0		'scdir',		szOptionScDir
TW0		'sd',			szOptionScDirS
TW0		'txtdir',		szOptionTxtDir
TW0		'td',			szOptionTxtDirS
TW0		'newdir',		szOptionNewDir
TW0		'nd',			szOptionNewDirS

TW0		'con',		szOptionConsole
TW0		'help',		szOptionHelp

coCmdOptions\
	_StCmdOption		<offset szOptionScriptName,offset szOptionScriptNameS,0>
	_StCmdOption		<offset szOptionCode1,offset szOptionCode1S,0>
	_StCmdOption		<offset szOptionCode2,offset szOptionCode2S,0>
	_StCmdOption		<offset szOptionLine,offset szOptionLineS,0>
	_StCmdOption		<offset szOptionPlugin,offset szOptionPluginS,0>
	_StCmdOption		<offset szOptionFilter,offset szOptionFilterS,0>
	_StCmdOption		<offset szOptionImport,offset szOptionImportS,0>
	_StCmdOption		<offset szOptionExport,offset szOptionExportS,0>
	_StCmdOption		<offset szOptionScDir,offset szOptionScDirS,0>
	_StCmdOption		<offset szOptionTxtDir,offset szOptionTxtDirS,0>
	_StCmdOption		<offset szOptionNewDir,offset szOptionNewDirS,0>
.code

_GetCmdOption proc uses esi edi ebx _lpName
	LOCAL @lpRslt
	LOCAL @temp
	LOCAL @nLen
	mov edi,lpArgTbl
	mov @lpRslt,0
	.if _lpName
		invoke lstrlenW,_lpName
		shl eax,1
		mov @nLen,eax
	.else
		mov @nLen,0
	.endif
	mov ebx,1
	.while ebx<nArgc
		mov esi,[edi+ebx*4]
		.if @nLen==0
			.if word ptr [esi]!='/'
				mov @lpRslt,esi
				.break
			.endif
			jmp _CtnGCO
		.endif
		cmp word ptr [esi],'/'
		jne _CtnGCO
		add esi,2
		mov edx,esi
		.while word ptr [edx]
			.break .if word ptr [edx]=='='
			add edx,2
		.endw
		mov @temp,edx
		sub edx,esi
		cmp edx,@nLen
		jne _CtnGCO
		invoke crt_memcmp,_lpName,esi,edx
		.if !eax
			mov eax,@temp
			.if word ptr [eax]=='='
				add eax,2
			.endif
			mov @lpRslt,eax
			.break
		.endif
	_CtnGCO:
		inc ebx
	.endw
	mov eax,@lpRslt
	ret
_GetCmdOption endp

_GetCmdOptions proc uses edi ebx _lpOptions
	mov edi,_lpOptions
	assume edi:ptr _StCmdOption
	xor ebx,ebx
	.while ebx<sizeof( _StCmdOptions)/sizeof( _StCmdOption)
		invoke _GetCmdOption,[edi].lpszName
		.if !eax
			invoke _GetCmdOption,[edi].lpszSName
		.endif
		mov [edi].lpszValue,eax
	_CtnGCO:
		add edi,sizeof(_StCmdOption)
		inc ebx
	.endw
	assume edi:nothing
	mov edi,_lpOptions
	.if _StCmdOptions.ScriptName.lpszValue[edi]==0
		invoke _GetCmdOption,0
		mov _StCmdOptions.ScriptName.lpszValue[edi],eax
	.endif
	mov ebx,_StCmdOptions.ScriptName.lpszValue[edi]
	.if ebx!=0
		invoke HeapAlloc,hGlobalHeap,0,MAX_STRINGLEN
		test eax,eax
		jz _ExGCO
		mov _StCmdOptions.ScriptName.lpszValue[edi],eax
		invoke GetFullPathNameW,ebx,MAX_STRINGLEN/2,eax,0
	.endif
_ExGCO:
	ret
_GetCmdOptions endp
;
;_CmdMain proc
;;	mov edi,_lpOptions
;;	invoke _GetCmdOption,offset szOptionHelp
;	ret
;_CmdMain endp