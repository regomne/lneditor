@echo off
pushd ..
call pvarsasm.bat
popd
echo %PATH_ERROR%
if %PATH_ERROR%==1 goto errpath

: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist rsrc.rc goto over1
Rc.exe /v rsrc.rc
Cvtres.exe /machine:ix86 rsrc.res
:over1


: -----------------------------------------
: assemble j_list.asm into an OBJ file
: -----------------------------------------
Ml.exe /c /coff j_list.asm
if errorlevel 1 goto errasm

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:j_list.def /section:.bss,S /out:j_list.mel j_list.obj rsrc.obj
if errorlevel 1 goto errlink
if not exist ..\..\mel\j_list.mel goto ohehe
del ..\..\mel\j_list.mel
:ohehe
copy j_list.mel ..\..\mel
dir j_list.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this j_list.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this j_list.
echo.
goto TheEnd

:errpath
echo.
echo Path Error!
echo.
goto TheEnd

:TheEnd


pause
