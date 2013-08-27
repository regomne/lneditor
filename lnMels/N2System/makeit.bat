@echo off
: -------------------------------
: if resources exist, build them
: -------------------------------
if not exist rsrc.rc goto over1
\MASM32\BIN\Rc.exe /v rsrc.rc
\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1

if exist %1.obj del N2System.obj
if exist %1.dll del N2System.dll

: -----------------------------------------
: assemble N2System.asm into an OBJ file
: -----------------------------------------
\MASM32\BIN\Ml.exe /c /coff N2System.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:N2System.def /section:.bss,S /out:N2System.mel N2System.obj rsrc.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\N2System.mel goto ohehe
del \masm32\lneditor\mel\N2System.mel
:ohehe
copy N2System.mel \masm32\lneditor\mel
dir N2System.*
goto TheEnd

:nores
: -----------------------
: link the main OBJ file
: -----------------------
\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS /Dll /Def:N2System.def /section:.bss,S /out:N2System.mel N2System.obj
if errorlevel 1 goto errlink
if not exist \masm32\lneditor\mel\N2System.mel goto ohehe2
del \masm32\lneditor\mel\N2System.mel
:ohehe2
copy N2System.mel \masm32\lneditor\mel
dir N2System.*
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this N2System.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this N2System.
echo.
goto TheEnd

:TheEnd

pause
