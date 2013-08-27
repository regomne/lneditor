@echo off
: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist rsrc.rc goto over1
\MASM32\BIN\Rc.exe /v rsrc.rc
\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1

if exist %1.obj del lucifen.obj
if exist %1.dll del lucifen.dll

: -----------------------------------------
: assemble lucifen.asm into an OBJ file
: -----------------------------------------
\MASM32\BIN\Ml.exe /c /coff lucifen.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:lucifen.def /section:.bss,S /out:lucifen.mel lucifen.obj rsrc.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\lucifen.mel goto ohehe
del \masm32\lneditor\mel\lucifen.mel
:ohehe
copy lucifen.mel \masm32\lneditor\mel
dir lucifen.*
goto TheEnd

:nores
: -----------------------
: link the main OBJ file
: -----------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:lucifen.def /section:.bss,S /out:lucifen.mel lucifen.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\lucifen.mel goto ohehe2
del \masm32\lneditor\mel\lucifen.mel
:ohehe2
copy lucifen.mel \masm32\lneditor\mel
dir lucifen.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this lucifen.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this lucifen.
echo.
goto TheEnd

:TheEnd

pause
