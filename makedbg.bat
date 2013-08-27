@echo off
call varsasm.bat
if %PATH_ERROR%==1 goto errpath

rc.exe /v lnrc.rc
if errorlevel 1 goto errres
cvtres.exe /machine:ix86 lnrc.res
if errorlevel 1 goto errres

if exist lnedit.obj del lnedit.obj

if exist lnedit.pdb del lnedit.pdb
if exist lnedit.ilk del lnedit.ilk

: -----------------------------------------
: assemble lnrc.asm into an OBJ file
: -----------------------------------------

Ml.exe /c /coff /Cp /Zi /D "_LN_DEBUG" lnedit.asm
if errorlevel 1 goto errasm

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------

Link.exe /ltcg /SUBSYSTEM:WINDOWS /DEBUG /DEBUGTYPE:CV /DEF:export.def uuid.lib msvcrt.lib msvcprt.lib oldnames.lib lnedit.obj lnrc.obj lnedit2.lib
if errorlevel 1 goto errlink
dir lnedit.*
incver.exe
goto TheEnd

:errpath
echo.
echo Please set the correct path in varsasm.bat!
echo.
goto TheEnd

:errlink
: ----------------------------------------------------
: display message if there is an error during linking
: ----------------------------------------------------
echo.
echo There has been an error while linking this lnedit.
echo.
goto TheEnd

:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling this lnedit.
echo.
goto TheEnd

:errres
echo.
echo There has been an error while compiling the resource.
echo.
goto TheEnd

:TheEnd

pause
