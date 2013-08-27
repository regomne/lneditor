@echo off
call varsasm.bat
if %PATH_ERROR%==1 goto errpath

rc.exe /v lnrc.rc
if errorlevel 1 goto errres
cvtres.exe /machine:ix86 lnrc.res
if errorlevel 1 goto errres

if exist lnedit.obj del lnedit.obj
if exist lnedit.exe del lnedit.exe
if exist lnedit.pdb del lnedit.pdb
if exist lnedit.ilk del lnedit.ilk

: -----------------------------------------
: assemble lnedit.asm into an OBJ file
: -----------------------------------------
Ml.exe /c /coff lnedit.asm
if errorlevel 1 goto errasm

: --------------------------------------------------
: link the main OBJ file with the resource OBJ file
: --------------------------------------------------
Link.exe /ltcg /SUBSYSTEM:WINDOWS /DEF:export.def uuid.lib msvcrt.lib msvcprt.lib oldnames.lib lnedit.obj lnrc.obj lnedit2.lib 
if errorlevel 1 goto errlink
dir lnedit.*
copy lnedit.exe bin\lnedit.exe
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
echo There has been an error while linking.
echo.
goto TheEnd


:errasm
: -----------------------------------------------------
: display message if there is an error during assembly
: -----------------------------------------------------
echo.
echo There has been an error while assembling.
echo.
goto TheEnd

:errres
echo.
echo There has been an error while compiling the resource.
echo.
goto TheEnd

:TheEnd

pause
