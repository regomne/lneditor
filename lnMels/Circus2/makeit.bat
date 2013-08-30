@echo off
: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist rsrc.rc goto over1
\MASM32\BIN\Rc.exe /v rsrc.rc
\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1

if exist %1.obj del Circus2.obj
if exist %1.dll del Circus2.dll

: -----------------------------------------
: assemble Circus2.asm into an OBJ file
: -----------------------------------------
\MASM32\BIN\Ml.exe /c /coff Circus2.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:Circus2.def /section:.bss,S /out:Circus2.mel Circus2.obj rsrc.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\Circus2.mel goto ohehe
del \masm32\lneditor\mel\Circus2.mel
:ohehe
copy Circus2.mel \masm32\lneditor\mel
dir Circus2.*
goto TheEnd

:nores
: -----------------------
: link the main OBJ file
: -----------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:Circus2.def /section:.bss,S /out:Circus2.mel Circus2.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\Circus2.mel goto ohehe2
del \masm32\lneditor\mel\Circus2.mel
:ohehe2
copy Circus2.mel \masm32\lneditor\mel
dir Circus2.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this Circus2.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this Circus2.
echo.
goto TheEnd

:TheEnd

pause
