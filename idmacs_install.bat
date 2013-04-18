@rem Copyright 2013 Lambert Boskamp
@rem
@rem Author: Lambert Boskamp <lambert@boskamp-consulting.com.nospam>
@rem
@rem This file is part of IDMacs.
@rem
@rem IDMacs is free software: you can redistribute it and/or modify
@rem it under the terms of the GNU General Public License as published by
@rem the Free Software Foundation, either version 3 of the License, or
@rem (at your option) any later version.
@rem
@rem IDMacs is distributed in the hope that it will be useful,
@rem but WITHOUT ANY WARRANTY; without even the implied warranty of
@rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@rem GNU General Public License for more details.
@rem
@rem You should have received a copy of the GNU General Public License
@rem along with IDMacs.  If not, see <http://www.gnu.org/licenses/>.
@echo off
setlocal enableextensions enabledelayedexpansion

rem Absolute path of the directory where this script is located,
rem including the trailing backslash
set gc_script_dir=%~dp0

rem Drive letter where this script is located
set gc_script_drive=%~d0

rem Default emacs installation directory
set gc_emacs_dir_default=!gc_script_drive!\emacs-24.1

rem ************************************************* BEGIN WHILE LOOP
:while_not_emacs_dir

set "gv_emacs_dir="
echo Enter Emacs24 Installation Directory, or q to quit
set /p gv_emacs_dir="[!gc_emacs_dir_default!]: " %=%

rem Use default if user just pressed Enter
if "!gv_emacs_dir!" == "" set gv_emacs_dir=!gc_emacs_dir_default!

rem Check user's answer ignoring case
if /i "!gv_emacs_dir!" == "q" (
    echo(
    echo Installation aborted
    echo(
) & goto :eof

rem  ******************************************************************
echo Verifying Emacs installation
rem  ******************************************************************
if not exist "!gv_emacs_dir!" (
    echo(
    echo ERROR: Directory !gv_emacs_dir! does not exist
    echo(
) & goto :while_not_emacs_dir

set gv_emacs_exe=!gv_emacs_dir!\bin\emacs.exe

if not exist "!gv_emacs_exe!" (
    echo(
    echo ERROR: File !gv_emacs_exe! does not exist
    echo(
) & goto :while_not_emacs_dir

"!gv_emacs_exe!" --version >nul 2>&1

if errorlevel 1 (
    echo(
    echo ERROR: Test execution of !gv_emacs_exe! failed (!errorlevel!)
    echo(
) & goto :while_not_emacs_dir

echo OK
echo(

rem *************************************************** END WHILE LOOP

rem Backslash is already included in gc_script_dir
set gv_gen_dir=!gc_script_dir!gen

rem  ******************************************************************
echo Preparing generation directory "!gv_gen_dir!"
rem  ******************************************************************

rem Backslash is already included in gc_script_dir
set gv_src_el_dir=!gc_script_dir!src\el

rem Delete all files in the generation directory.
rem Error messages are ignored, since the directory may not exist yet.
del /q "!gv_gen_dir!\*" >nul 2>&1

rem Create the generation directory, if required
if not exist "!gv_gen_dir!" mkdir "!gv_gen_dir!"

rem Copy all elisp files that must be byte-compiled
call :sub_copy_el_files_to_dir ^
     !gv_src_el_dir!\auto-complete ^
     !gv_gen_dir!

call :sub_copy_el_files_to_dir ^
     !gv_src_el_dir!\js2-mode ^
     !gv_gen_dir!

call :sub_copy_el_files_to_dir ^
     !gv_src_el_dir!\yasnippet ^
     !gv_gen_dir!

echo OK
echo(

rem  ******************************************************************
echo Byte-compiling Elisp files
rem  ******************************************************************

rem Emacs arguments for byte compilation of Elisp files in batch mode
set gv_arg_byte_compile=--batch -q --no-site-file -f batch-byte-compile

rem I don't understand why but the FOR loop doesn't work with delayed
rem variable expansion syntax, i.e. !gv_gen_dir! doesn't do anything.

for /r "%gv_gen_dir%" %%g in (*.el) do (
    "!gv_emacs_exe!" !gv_arg_byte_compile! "%%g"
    if errorlevel 1 (
        echo ERROR: Return code !errorlevel! compiling "%%g"
    ) & goto :eof
)

echo OK
echo(

goto :eof

rem ******************************************************************
rem * Subroutine: sub_copy_el_files_to_dir
rem *
rem * Parameters:
rem * %1 - Source directory to search for *.el files
rem * %2 - Target directory to copy to
rem ******************************************************************
:sub_copy_el_files_to_dir
setlocal
set lv_file_pattern=%1\*.el
set lv_target_dir=%2

copy /y "!lv_file_pattern!" "!lv_target_dir!" >nul 2>&1

endlocal
goto :eof


