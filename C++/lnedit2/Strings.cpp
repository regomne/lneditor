#include <windows.h>

//the const unicode strings for asm.

extern "C" 
{
	//extern const WCHAR szPatQuotes[]=L"(?:[（「『]|(　+))(.*)(?(1).*|[）」』])";
	extern const WCHAR szPatQuotes[]=L"[（「『　]+(.*?)(([）」』]+)|$|(%K%P))";
}
