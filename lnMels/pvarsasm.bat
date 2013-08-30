@echo off
rem Set env vars of plugins.

cd ..
call varsasm.bat
if %PATH_ERROR%==1 goto ErrPath

set "INCLUDE=%LNEDITDIR%;%INCLUDE%"
set "LIB=%LNEDITDIR%;%LIB%"
set "LIBPATH=%LNEDITDIR%;%LIBPATH%"

goto :eof

:ErrPath
set PATH_ERROR=1
goto :eof