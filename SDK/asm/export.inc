
;Internal String Len
SHORT_STRINGLEN		EQU		64

;Export Functions
_GetConstString 		proto
_Int2Str				proto :dword,:dword,:dword
_DisplayStatus			proto :dword,:dword
_GetStringInList		proto :dword,:dword

_SelfMatch			proto :dword

_GetText				proto :dword,:dword
_SaveText			proto :dword
_ModifyLine			proto :dword,:dword
_SetLine				proto :dword,:dword

;Help Match String 
_GetStringInTxt		proto :dword,:dword,:dword,:dword
_WildcharMatchW		proto :dword,:dword

;
_ReplaceInMem		proto :dword,:dword,:dword,:dword,:dword
_OutputMessage		proto :dword,:dword,:dword,:dword
