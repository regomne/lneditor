
.code

_InitHashTable proc uses edi esi ebx
	XOR EDI,EDI
	MOV ESI,lpTable1
L002:
	MOV EDX,EDI
	MOV EBX,8
L004:
	TEST DL,1
	JE L009
	SHR EDX,1
	XOR EDX,0EDB88320h
	JMP L010
L009:
	SHR EDX,1
L010:
	DEC EBX
	JNZ L004
	MOV DWORD PTR [ESI],EDX
	ADD ESI,4
	INC EDI
	cmp edi,256
	JL L002
	ret
_InitHashTable endp

_CalHash proc uses esi edi ebx _dSeed,_lpData,_nLen
	mov esi,_lpData
	mov eax,_dSeed
	XOR EDX,EDX
	mov ebx,lpTable1
	cmp _nLen,0
	JLE L014
L003:
	XOR ECX,ECX
	MOV CL,BYTE PTR [EDX+ESI]
	MOV EDI,EAX
	AND EDI,0FFh
	SHR EAX,8
	XOR ECX,EDI
	MOV ECX,DWORD PTR [ECX*4+ebx]
	XOR EAX,ECX
	INC EDX
	CMP EDX,_nLen
	JL L003
L014:
	NOT EAX
	ret
_CalHash endp

_XorBlock proc uses esi edi _lpBuff,_nSize
	xor ecx,ecx
	mov esi,_lpBuff
	mov edi,lpTable1
	.while ecx<_nSize
		mov edx,ecx
		and edx,256*4-1
		mov al,[edi+edx]
		xor [esi+ecx],al
		inc ecx
	.endw
	ret
_XorBlock endp
