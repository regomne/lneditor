.code

_PreScan proc uses esi edi ebx _lpFile,_nSize,_lpAinSegs
	LOCAL @pEnd
	LOCAL @nNums
	mov esi,_lpFile
	mov ebx,_lpAinSegs
	assume ebx:ptr _AinSegs
	mov eax,esi
	add eax,_nSize
	mov @pEnd,eax
	.while esi<@pEnd
		lodsd
		.if eax=='SREV'
			mov [ebx].Version.lpAddr,esi
			mov [ebx].Version.nSize,4
			add esi,4
		.elseif eax=='EDOC'
			lodsd
			mov [ebx].Code.lpAddr,esi
			mov [ebx].Code.nSize,eax
			add esi,eax
		.elseif eax=='CNUF'
			mov [ebx].Function.lpAddr,esi
			lodsd
			push ebx
			mov ebx,eax
			xor al,al
			or ecx,-1
			mov edi,esi
			.while ebx
				add edi,4
				repne scasb
				add edi,24
				mov edx,[edi-8]
				.while edx
					repne scasb
					add edi,12
					dec edx
				.endw
				dec ebx
			.endw
			pop ebx			
			mov ecx,edi
			sub ecx,esi
			mov esi,edi
			add ecx,4
			mov [ebx].Function.nSize,ecx
		.ELSEIF EAX=='BOLG'
			mov [ebx].GlobalVar.lpAddr,esi
			lodsd
			push ebx
			mov ebx,eax
			mov edi,esi
			xor al,al
			or ecx,-1
			.while ebx
				repne scasb
				add edi,12
				dec ebx
			.endw
			pop ebx
			mov ecx,edi
			sub ecx,esi
			add ecx,4
			mov [ebx].GlobalVar.nSize,ecx
			mov esi,edi
		.ELSEIF EAX=='TESG'
			mov [ebx].GlobalSet.lpAddr,esi
			lodsd
			shl eax,2
			lea eax,[eax+eax*2]
			add esi,eax
			add eax,4
			mov [ebx].GlobalSet.nSize,eax
		.ELSEIF EAX=='TRTS'
			mov [ebx].Structs.lpAddr,esi
			lodsd
			push ebx
			mov ebx,eax
			mov edi,esi
			or ecx,-1
			xor eax,eax
			.while ebx
				repne scasb
				add edi,12
				mov edx,[edi-4]
				.while edx
					dec edx
					repne scasb
					add edi,12
				.endw
				dec ebx
			.endw
			pop ebx
			mov ecx,edi
			sub ecx,esi
			mov esi,edi
			add ecx,4
			mov [ebx].Structs.nSize,ecx
		.ELSEIF EAX=='0GSM'
			lodsd
			mov [ebx].Message0.lpAddr,esi
			mov [ebx].Message0.nSize,eax
			add esi,eax
		.ELSEIF EAX=='NIAM'
			mov [ebx].Main.lpAddr,esi
			mov [ebx].Main.nSize,4
			add esi,4
		.ELSEIF EAX=='FGSM'
			mov [ebx].MessageFunc,esi
			mov [ebx].MessageFunc,4
			add esi,4
		.ELSEIF EAX=='0LLH'
			mov [ebx].HLL,esi
			lodsd
			push ebx
			mov ebx,eax
			mov edi,esi
			xor eax,eax
			.while ebx
				repne scasb
				mov edx,[edi]
				add edi,4
				.while edx
					repne scasb
					add edi,8
					push edx
					mov edx,[edi-4]
					.while edx
						repne scasb
						add edi,4
						dec edx
					.endw
					pop edx
					dec edx
				.endw
				dec ebx
			.endw
			pop ebx
			mov ecx,edi
			sub ecx,esi
			mov esi,edi
			add ecx,4
			mov [ebx].HLL.nSize,ecx
		.ELSEIF EAX=='0IWS'
			mov [ebx].SwitchData.lpAddr,esi
			lodsd
			mov edi,eax
			.while edi
				add esi,12
				mov edx,[esi-4]
				shl edx,3
				add esi,edx
				dec edi
			.endw
			mov ecx,esi
			sub ecx,[ebx].SwitchData.lpAddr
			mov [ebx].SwitchData.nSize,ecx
		.ELSEIF EAX=='REVG'
			mov [ebx].GameVersion.lpAddr,esi
			mov [ebx].GameVersion.nSize,4
			add esi,4
		.ELSEIF EAX=='LBLS'
			mov [ebx].SLBL.lpAddr,esi
			lodsd
			mov edx,eax
			xor eax,eax
			or ecx,-1
			mov edi,esi
			.while edx
				repne scasb
				add edi,4
				dec edx
			.endw
			mov ecx,edi
			sub ecx,esi
			add ecx,4
			mov [ebx].SLBL.nSize,ecx
			mov esi,edi
		.ELSEIF EAX=='0RTS'
			mov [ebx].Strings.lpAddr,esi
			lodsd
			mov edx,eax
			mov edi,esi
			xor eax,eax
			or ecx,-1
			.while edx
				repne scasb
				dec edx
			.endw
			lea ecx,[edi+4]
			sub ecx,esi
			mov [ebx].Strings.nSize,ecx
			mov esi,edi
		.ELSEIF EAX=='MANF'
			mov [ebx].FileName.lpAddr,esi
			lodsd
			mov edx,eax
			mov edi,esi
			xor eax,eax
			or ecx,-1
			.while edx
				repne scasb
				dec edx
			.endw
			lea ecx,[edi+4]
			sub ecx,esi
			mov [ebx].FileName.nSize,ecx
			mov esi,edi
		.ELSEIF EAX=='PMJO'
			mov [ebx].Onjump.lpAddr,esi
			mov [ebx].Onjump.nSize,4
			add esi,4
		.ELSEIF EAX=='TCNF'
			lodsd
			mov [ebx].FuctionType.lpAddr,esi
			mov [ebx].FuctionType.nSize,eax
			add esi,eax
		.ELSEIF EAX=='CYEK'
			mov [ebx].KeyC.lpAddr,esi
			mov [ebx].KeyC.nSize,4
			add esi,4
		.else
			mov eax,1
			ret
		.endif
	.endw
	assume edi:nothing
	xor eax,eax
	ret
_PreScan endp