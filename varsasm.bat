@echo off
rem Set asm env vars.
set "WINDDKDIR=D:\WinDDK\7600.16385.1"
set "WINXPDDKDIR=E:\Software\VC6\2600"
set "MASMPATH=\masm32"
set "COMPILERPATH=C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\bin" rem Need ml.exe and link.exe in VC++10
set "ADDITIONALDLLPATH=C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE" rem Need mspdb100.dll and so on
set "WINSDKPATH=C:\Program Files (x86)\Windows Kits\8.0\bin\x86" rem Need rc.exe

set "LNEDITDIR=%CD%"

if not exist "%WINDDKDIR%" goto ErrPath
if not exist "%MASMPATH%"  goto ErrPath
if not exist "%COMPILERPATH%"  goto ErrPath
if not exist "%WINSDKPATH%"  goto ErrPath

set "LIB=%WINDDKDIR%\lib\wxp\i386;%WINDDKDIR%\lib\crt\i386;%MASMPATH%\lib"

if exist "%WINXPDDKDIR%" set "LIB=%WINXPDDKDIR%\lib\wxp\i386;%LIB%"

set "LIBPATH=%LIB%"

set "INCLUDE=%MASMPATH%\include;%MASMPATH%\macros"

set "PATH=%COMPILERPATH%;%ADDITIONALDLLPATH%;%WINSDKPATH%;%PATH%"

set PATH_ERROR=0
goto :eof

:ErrPath
set PATH_ERROR=1
goto :eof