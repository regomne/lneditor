;_debug equ 1

ABREAK macro
	ifdef _debug
		int 3
	endif
endm

TIMER macro
	rdtsc
	mov dbTimesTemp,eax
	mov dword ptr [dbTimesTemp+4],edx
endm

TIMERE macro
	rdtsc
	sub eax,dbTimesTemp
	sbb edx,dword ptr [dbTimesTemp+4]
endm

.data?
	dbTimesTemp	dd		2	dup(?)
	dbTimes		dd		64	dup(?)
	
	szTimes		db		32	dup(?)

		
;		TIMERE
;		invoke wsprintfW,offset szTimes,$CTW0("%d %d"),edx,eax
;		invoke MessageBoxW,hWinMain,offset szTimes,0,0
