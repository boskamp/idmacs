@echo off
rem Make all variables set in this script local
setlocal

rem Drive letter where this script is located
set script_drive=%~d0

rem Default emacs installation directory
set emacs_dir_default=%script_drive%\emacs-24.1

:prompt_for_emacs_dir
rem Prompt user for Emacs installation directory, offer default
set /p emacs_dir="Emacs24 Installation Directory [%emacs_dir_default%]: " %=%

rem Use default if user just pressed enter
if "%emacs_dir%" == "" set emacs_dir=%emacs_dir_default%
echo Using Emacs24 Installation Directory '%emacs_dir%'

if not exist "%emacs_dir%" goto :emacs_dir_not_found

rem Use quoting for emacs.exe so paths with spaces will work
set emacs_exe="%emacs_dir%\bin\emacs.exe"
if not exist %emacs_exe% goto :emacs_exe_not_found

rem Test invocation of emacs.exe
set test_emacs_exe=%emacs_exe% --version
%test_emacs_exe% >nul 2>&1
if errorlevel 1 goto :exit_test_emacs_exe_error

rem Emacs arguments for byte compilation of Elisp files in batch mode
set arg_byte_compile=--batch -q --no-site-file -f batch-byte-compile

rem Emacs command including these arguments
set cmd_byte_compile=%emacs_exe% %arg_byte_compile%

rem Find all .el files underneath directory
rem and batch byte compile them using their full path names
for /r "%emacs_dir%\test" %%g in (*.el) do %cmd_byte_compile% %%~fg

rem Command for recursive copying of the IDMacs directory
echo This script is located in %~dp0
set cmd_copy_recursive=xcopy /q /y /i /e

rem TODO continue with copying byte-compiled files into emacs_dir

echo All OK, thanks for using IDMacs
goto :exit

:emacs_dir_not_found
echo ERROR: Directory '%emacs_dir%' doesn't exist
set emacs_dir=
goto :prompt_for_emacs_dir

:emacs_exe_not_found
echo ERROR: Emacs executable '%emacs_exe%' doesn't exist
set emacs_dir=
set emacs_exe=
goto :prompt_for_emacs_dir

:exit_test_emacs_exe_error
echo Error %errorlevel% on execution of '%test_emacs_exe%'
goto :exit

:exit
endlocal
exit /b %errorlevel%
