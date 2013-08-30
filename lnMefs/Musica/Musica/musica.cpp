#include<Windows.h>

#include "\masm32\lneditor\SDK\C++\plugin.h"


void WINAPI InitInfo(LPMEL_INFO2 lpMelInfo)
{
	lpMelInfo->dwInterfaceVersion=TXTINTERFACE_VERSION;
	lpMelInfo->dwCharacteristic=0;
}


MRESULT WINAPI ProcessLine(LPSTREAM_ENTRY lpSE,DWORD dwCharSet)
{
	if(dwCharSet==CS_UNICODE)
		return E_SUCCESS;
	if(memcmp(lpSE->lpStart,".message\t",strlen(".message\t")))
		return E_LINEDENIED;

	DWORD i=0;
	char* p=(char*)lpSE->lpStart;

	i+=strlen(".message\t");

	while(p[i++]!='\t' && i<lpSE->nStringLen);

	while(p[i++]!='\t' && i<lpSE->nStringLen);

	if(p[i]=='\t')
		i++;

	if(i<lpSE->nStringLen)
	{
		lpSE->lpStart=&p[i];
		lpSE->nStringLen-=i;
	}
	return E_SUCCESS;
}