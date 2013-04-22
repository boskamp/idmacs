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

rem Number of file descriptor to which command output will go.
set gv_stdout=nul

rem Global return variable set by sub routines
rem gv_return=

rem Directory where this script is, including trailing backslash
set gv_temp=%~dp0

rem Remove trailing backslash
set gv_script_dir=%gv_temp:~0,-1%

rem Drive letter where this script is located
set gv_script_drive=%~d0

rem Directory where IDM job exports are
set gv_job_dir=!gv_script_dir!\job

rem Directory where IDMacs documentation is
set gv_doc_dir=!gv_script_dir!\doc

rem Directory where Elisp will be copied to and byte-compiled
set gv_gen_dir=!gv_script_dir!\gen

rem ******************************************************************
rem Define source code directories
rem ******************************************************************
rem Directory underneath which language-specific source dirs are
set gv_src_dir=!gv_script_dir!\src

rem Directory underneath which submodules with Elisp sources are
set gv_src_el_dir=!gv_src_dir!\el

rem Directory where Windows CMD (aka batch) scripts are
set gv_src_cmd_dir=!gv_src_dir!\cmd

rem ******************************************************************
rem Parse command line arguments
rem ******************************************************************
rem This is our script file name, without path and with file extension
set gv_script_cmd=%~n0

for %%g in (%*) do (
    set gv_arg_recognized=false

    if "%%g" == "--debug" (
        set gv_stdout=dev_idmacs_install
	echo >!gv_stdout!
	echo(
	echo Logging all command output to file !gv_stdout!
	set gv_arg_recognized=true
    )

    if "%%g" == "--help" (
        call :sub_display_help !gv_script_cmd!
	set gv_arg_recognized=true
	exit /b 0
    )

    if "!gv_arg_recognized!" == "false" (
        echo ERROR: Unrecognized option %%g
        call :sub_display_help !gv_script_cmd!
	exit /b 1
    )
)

echo(
echo *****************************************************************
echo *********    W E L C O M E   T O   I D M A C S    ***************
echo *****************************************************************
echo(
echo Installing this software package requires that you have already
echo downloaded and unzipped GNU Emacs for Windows, version 24.x. 
echo If you haven't done this yet, please visit the following URL:
echo(
echo http://ftp.gnu.org/gnu/emacs/windows/
echo(
echo Download one of the pre-compiled binary distributions of
echo GNU Emacs 24.x for Windows, and unzip it into a local directory.
echo Please make sure to download the full distribution including
echo the Elisp sources, not a binary only version ^(i.e. NOT BAREBIN^).
echo(
echo The recommended archive to download is emacs-24.1-bin-i386.zip
echo *****************************************************************
echo(
set /p gv_temp="Press ENTER to proceed, or q to quit: " %=%
if /i "!gv_temp!" == "q" (
    echo Installation aborted by user. Good bye.
    exit /b 0
)

rem ******************************************************************
rem Prompt for and verify Emacs installation directory
rem ******************************************************************

rem Default emacs installation directory
set gv_emacs_dir_default=!gv_script_drive!\emacs-24.1

:while_not_emacs_dir & rem ================================ BEGIN LOOP

set "gv_emacs_dir="
echo(
echo Enter Emacs24 directory, or q to quit
set /p gv_emacs_dir="[!gv_emacs_dir_default!]: " %=%

rem Use default if user just pressed Enter
if "!gv_emacs_dir!" == "" set gv_emacs_dir=!gv_emacs_dir_default!

rem Check user's answer ignoring case
if /i "!gv_emacs_dir!" == "q" (
    echo(
    echo Installation aborted by user. Good bye.
    echo(
) & goto :eof

rem Remove surrounding quote and/or trailing backslash, if any
call :sub_normalize_dir_name !gv_emacs_dir!
set gv_emacs_dir=!gv_return!

rem  ******************************************************************
echo(
echo Verifying Emacs installation in "!gv_emacs_dir!"
rem  ******************************************************************
call :sub_check_dir_exists "!gv_emacs_dir!"
if not "!gv_return!" == "0" goto :while_not_emacs_dir

set gv_emacs_site_lisp_dir=!gv_emacs_dir!\site-lisp

call :sub_check_dir_exists "!gv_emacs_site_lisp_dir!"
if not "!gv_return!" == "0" goto :while_not_emacs_dir

set gv_emacs_bin_dir=!gv_emacs_dir!\bin

call :sub_check_dir_exists "!gv_emacs_bin_dir!"
if not "!gv_return!" == "0" goto :while_not_emacs_dir

set gv_emacs_exe=!gv_emacs_bin_dir!\emacs.exe

call :sub_check_file_exists "!gv_emacs_exe!"
if not "!gv_return!" == "0" goto :while_not_emacs_dir

"!gv_emacs_exe!" --version >>!gv_stdout! 2>&1

if errorlevel 1 (
    echo(
    echo ERROR: Return code !errorlevel! testing "!gv_emacs_exe!"
    echo(
) & goto :while_not_emacs_dir

echo OK
echo(

rem ========================================================= END LOOP

rem  *****************************************************************
echo Preparing generation directory "!gv_gen_dir!"
rem  *****************************************************************

rem Delete all files in the generation directory
rem or create it if it doesn't exist yet

if exist "!gv_gen_dir!" (
    del /q "!gv_gen_dir!\*"
) else (
    mkdir "!gv_gen_dir!"
)
rem ******************************************************************
rem Copy all Elisp files that must be byte-compiled
rem ******************************************************************
call :sub_copy_el_files_to_dir ^
     "!gv_src_el_dir!\auto-complete" ^
     "!gv_gen_dir!"

call :sub_copy_el_files_to_dir ^
     "!gv_src_el_dir!\js2-mode" ^
     "!gv_gen_dir!"

call :sub_copy_el_files_to_dir ^
     "!gv_src_el_dir!\yasnippet" ^
     "!gv_gen_dir!"

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
    "!gv_emacs_exe!" !gv_arg_byte_compile! "%%g" >>!gv_stdout! 2>&1

    set lv_temp=%%g
    set lv_elc_file=!lv_temp!c

    if not exist "!lv_elc_file!" (
        echo ERROR: "!lv_elc_file!" could not be generated.
	echo ERROR: Please retry the installation with --verbose
	echo ERROR: and check for compilation error messages.
	echo(
	echo Aborting installation.
    ) & exit /b !errorlevel!
)

echo OK
echo(

rem  *****************************************************************
echo Ready to deploy IDMacs files to "!gv_emacs_dir!"
rem  *****************************************************************
echo(
echo WARNING: THIS WILL OVERWRITE ANY OR ALL MANUAL CUSTOMIZATIONS
echo YOU MAY HAVE APPLIED TO EMACS INSTALLATION AT "!gv_emacs_dir!"
echo(

set /p gv_overwrite_ok="Are you sure (y/n) [n]: " %=%
if /i not "!gv_overwrite_ok!" == "y" (
    echo(
    echo Installation aborted by user. Good bye.
) & exit /b

rem  *****************************************************************
echo Deploying IDMacs files to "!gv_emacs_dir!"
rem  *****************************************************************

copy /y ^
    "!gv_gen_dir!\*" ^
    "!gv_emacs_site_lisp_dir!" ^
    >>!gv_stdout! 2>&1

copy /y ^
    "!gv_src_cmd_dir!\*" ^
    "!gv_emacs_bin_dir!" ^
    >>!gv_stdout! 2>&1

rem Copy intialization Elisp file as source only (no compilation)

copy /y ^
    "!gv_src_el_dir!\init\*.el" ^
    "!gv_emacs_site_lisp_dir!" ^
    >>!gv_stdout! 2>&1

rem Set target IDMacs directories underneath Emacs dir
rem only now that gv_emacs_dir is defined and verified

set gv_emacs_etc_idm_dir=!gv_emacs_dir!\etc\idmacs

rem ******************************************************************
rem Copy exported jobs
rem ******************************************************************
set gv_emacs_etc_idm_job_dir=!gv_emacs_etc_idm_dir!\job

if not exist "!gv_emacs_etc_idm_job_dir!" (
    mkdir "!gv_emacs_etc_idm_job_dir!"
)

copy /y ^
    "!gv_job_dir!\*" ^
    "!gv_emacs_etc_idm_job_dir!" ^
    >>!gv_stdout! 2>&1

rem ******************************************************************
rem Copy documentation
rem ******************************************************************
set gv_emacs_etc_idm_doc_dir=!gv_emacs_etc_idm_dir!\doc

if not exist "!gv_emacs_etc_idm_doc_dir!" (
    mkdir "!gv_emacs_etc_idm_doc_dir!"
)

copy /y ^
    "!gv_doc_dir!\*" ^
    "!gv_emacs_etc_idm_doc_dir!" ^
    >>!gv_stdout! 2>&1

rem ******************************************************************
rem That's it! Note that exclamation marks need double escape ;-)
rem ******************************************************************
echo( 
echo SUCCESSFULLY INSTALLED. Thank you for using IDMacs^^!




goto :eof & rem ===================================== END MAIN PROGRAM




rem ******************************************************************
rem * Subroutine: sub_copy_el_files_to_dir
rem *
rem * Parameters:
rem * %1 - Source directory to search for *.el files
rem * %2 - Target directory to copy to
rem *
rem * Returns:
rem * nothing
rem ******************************************************************
:sub_copy_el_files_to_dir
setlocal

set lv_file_pattern=%1\*.el
set lv_target_dir=%2
set lv_stdout=%3

copy /y ^
    "!lv_file_pattern!" ^
    "!lv_target_dir!" ^
    >>!gv_stdout! 2>&1

endlocal
goto :eof

rem ******************************************************************
rem * Subroutine: check_dir_exists
rem *
rem * Checks if directory exists, and displays a corresponding
rem * message if it doesn't.
rem *
rem * Parameters:
rem * %1 - Directory name surrounded by double quotes
rem *
rem * Returns:
rem * "0" if %1 exists and is a directory
rem * "1" otherwise
rem ******************************************************************
:sub_check_dir_exists
setlocal

if exist %1 (
    pushd %1 2>nul
    if errorlevel 1 (
        set lv_return=1
        echo(
        echo ERROR: %1 is a file ^(expected a directory^)
        echo(
    ) else (
        set lv_return=0
    )
    popd
) else (
    set lv_return=1
    echo(
    echo ERROR: Directory %1 doesn't exist
    echo(
)

endlocal & set gv_return=%lv_return%
goto :eof

rem ******************************************************************
rem * Subroutine: check_file_exists
rem *
rem * Checks if file exists, and displays a corresponding
rem * message if it doesn't.
rem *
rem * Parameters:
rem * %1 - Directory name surrounded by double quotes
rem *
rem * Returns:
rem * 0 if %1 exists and is a file, not a directory
rem * 1 otherwise
rem ******************************************************************
:sub_check_file_exists
setlocal

if exist %1 (
    pushd %1 2>nul
    if errorlevel 1 (
        set lv_return=0
    ) else (
        set lv_return=1
        echo(
        echo ERROR: %1 is a directory ^(expected a file^)
        echo(
    )
    popd
) else (
    set lv_return=1
    echo(
    echo ERROR: File %1 doesn't exist
    echo(
)

endlocal & set gv_return=%lv_return%
goto :eof

rem ******************************************************************
rem * Subroutine: sub_display_help
rem *
rem * Displays command line options and their meanings
rem *
rem * Parameters:
rem * %1 - Name of this script as invoked from command line
rem *
rem * Returns:
rem * nothing
rem ******************************************************************
:sub_display_help
setlocal

echo(
echo Usage: %1
echo   --debug:   Log full output from all commands into dev_idmacs_install
echo   --help:    display this help

endlocal
goto :eof

rem ******************************************************************
rem * Subroutine: sub_normalize_dir_name
rem *
rem * Check if %1 is surrounded by double quotes. If so, remove them.
rem * Then check if the remaining string ends with a backslash
rem * character. If so, remove that as well.
rem *
rem * Parameters:
rem * %1 - Directory name
rem *
rem * Returns:
rem * Unquoted directory name without trailing backslash
rem ******************************************************************
:sub_normalize_dir_name
setlocal

set lv_dir_name=%1
set lv_first_char=!lv_dir_name:~0,1!
set lv_last_char=!lv_dir_name:~-1,1!

rem Surrounding brackets required for strings containing quotes
if [!lv_first_char!] == [^"] (
   if [!lv_last_char!] == [^"] (
      set lv_dir_name=!lv_dir_name:~1,-1!
   )
)

set lv_last_char=!lv_dir_name:~-1,1!
if [!lv_last_char!] == [\] set lv_dir_name=!lv_dir_name:~0,-1!

endlocal & set gv_return=%lv_dir_name%

goto :eof
