@echo off
: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist rsrc.rc goto over1
\MASM32\BIN\Rc.exe /v rsrc.rc
\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1

if exist %1.obj del bgi.obj
if exist %1.dll del bgi.dll

: -----------------------------------------
: assemble bgi.asm into an OBJ file
: -----------------------------------------
\MASM32\BIN\Ml.exe /c /coff bgi.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:bgi.def /section:.bss,S /out:bgi.mel bgi.obj rsrc.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\bgi.mel goto ohehe
del \masm32\lneditor\mel\bgi.mel
:ohehe
copy bgi.mel \masm32\lneditor\mel
dir bgi.*
goto TheEnd

:nores
: -----------------------
: link the main OBJ file
: -----------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:bgi.def /section:.bss,S /out:bgi.mel bgi.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\bgi.mel goto ohehe2
del \masm32\lneditor\mel\bgi.mel
:ohehe2
copy bgi.mel \masm32\lneditor\mel
dir bgi.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this bgi.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this bgi.
echo.
goto TheEnd

:TheEnd

pause
