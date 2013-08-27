@echo off
set CURPATH=%CD%
cd ..
call pvarsasm.bat
cd "%CURPATH%"
if %PATH_ERROR%==1 goto errpath

: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist rsrc.rc goto over1
Rc.exe /v rsrc.rc
Cvtres.exe /machine:ix86 rsrc.res
:over1


: -----------------------------------------
: assemble stuff.asm into an OBJ file
: -----------------------------------------
Ml.exe /c /coff stuff.asm
if errorlevel 1 goto errasm

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:stuff.def /section:.bss,S /out:stuff.mel stuff.obj rsrc.obj
if errorlevel 1 goto errlink
if not exist ..\..\mel\stuff.mel goto ohehe
del ..\..\mel\stuff.mel
:ohehe
copy stuff.mel ..\..\mel
dir stuff.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this stuff.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this stuff.
echo.
goto TheEnd

:errpath
echo.
echo Path Error!
echo.
goto TheEnd

:TheEnd


pause
