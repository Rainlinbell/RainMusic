@rem Hvigor project startup script for Windows
@if "%DEBUG%" == "" @echo off

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

set HVIGOR_HOME=D:\DevEco Studio\tools\hvigor

@rem Use Node.js from PATH or NODE_HOME
set NODE_EXE=node.exe

%NODE_EXE% --version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto execute

echo ERROR: node.exe not found in PATH.
exit /b 1

:execute
@rem Execute hvigor
cd /d "%APP_HOME%"
"%NODE_EXE%" "%HVIGOR_HOME%\bin\hvigorw.js" %*

if "%ERRORLEVEL%" == "0" exit /b 0
exit /b 1
