@echo off
: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist rsrc.rc goto over1
\MASM32\BIN\Rc.exe /v rsrc.rc
\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1

if exist %1.obj del majiro.obj
if exist %1.dll del majiro.dll

: -----------------------------------------
: assemble majiro.asm into an OBJ file
: -----------------------------------------
\MASM32\BIN\Ml.exe /c /coff majiro.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:majiro.def /section:.bss,S /out:majiro.mel majiro.obj rsrc.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\majiro.mel goto ohehe
del \masm32\lneditor\mel\majiro.mel
:ohehe
copy majiro.mel \masm32\lneditor\mel
dir majiro.*
goto TheEnd

:nores
: -----------------------
: link the main OBJ file
: -----------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:majiro.def /section:.bss,S /out:majiro.mel majiro.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\majiro.mel goto ohehe2
del \masm32\lneditor\mel\majiro.mel
:ohehe2
copy majiro.mel \masm32\lneditor\mel
dir majiro.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this majiro.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this majiro.
echo.
goto TheEnd

:TheEnd

pause
