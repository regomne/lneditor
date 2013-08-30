
REG_COUNT			EQU		16
REG_MAX_GROUPS		EQU		8

_RegInitA proto :dword,:dword,:dword
_RegReleaseA proto :dword
_RegReplaceA proto :dword,:dword,:dword,:dword,:dword
_RegReleaseStringA proto :dword
_IsRegMatchA proto :dword,:dword
_RegMatchA proto :dword,:dword,:dword,:dword

_RegInitW proto :dword,:dword,:dword
_RegReleaseW proto :dword
_RegReplaceW proto :dword,:dword,:dword,:dword,:dword
_RegReleaseStringW proto :dword
_IsRegMatchW proto :dword,:dword
_RegMatchW proto :dword,:dword,:dword,:dword

_CppInitialize proto

externdef szPatQuotes:dword

_RegexpRange struct
	nStart			dd		?
	nEnd			dd		?
_RegexpRange ends

_RegexpResult struct
	bIsMatched		dd		?
	rBase			_RegexpRange	<>
	nGroups			dd		?
	rGroups			_RegexpRange	REG_MAX_GROUPS	dup(<>)
_RegexpResult ends
