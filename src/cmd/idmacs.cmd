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

rem Always start Emacs with Windows Compatibility Layer set to 
rem Windows XP SP3 to work around issue#9: Displaying API documentation 
rem fails with error "ShellExecute failed..."
set __COMPATIBILITY_LAYER=WINXPSP3

rem Name of trace file; always located in same dir as idmacs.cmd.
rem Note that %~dp0 includes the trailing backslash; fixes issue#2
set gv_trace_file=%~dp0dev_idmacs

rem Truncate trace file
echo( >!gv_trace_file!

rem Global return variable set by sub routines
set gv_return=

rem The file where Emacs server publishes its listener socket
set gv_server_file=%APPDATA%\.emacs.d\server\server
call :sub_trace gv_server_file=!gv_server_file!

rem Command line to start Emacs server with
set gv_cmd_server="%~dp0runemacs.exe"
call :sub_trace gv_cmd_server=!gv_cmd_server!

rem Command line to start Emacs client with
set gv_cmd_client="%~dp0emacsclient.exe" %*
call :sub_trace gv_cmd_client=!gv_cmd_client!

set /a "gv_num_attempts=-1"
set gv_loop_again=false
set gv_start_all_over=true

rem Check which command we must use to sleep (W2K3 vs. W2K8)
call :sub_determine_sleep_cmd
set gv_sleep_cmd=!gv_return!

if "!gv_sleep_cmd!" == "" (
    echo ERROR: No sleep command found. See !gv_trace_file! for details
    exit /b 1
)

call :sub_trace gv_sleep_cmd=!gv_sleep_cmd!

:while_not_server_file & rem ============================== BEGIN LOOP

rem Due to initialization at -1, first loop starts at 0
set /a "gv_num_attempts+=1"

call :sub_trace gv_num_attempts=!gv_num_attempts!

if not exist "!gv_server_file!" (
    call :sub_trace !gv_server_file! does not exist

    if !gv_num_attempts! equ 0 (
        call :sub_trace Starting Emacs server via !gv_cmd_server!
	!gv_cmd_server!
        set gv_loop_again=true
    ) else (
        if !gv_num_attempts! lss 10 (
            call :sub_trace ^
                 Server not reached on attempt #!gv_num_attempts!
            !gv_sleep_cmd! 1 >nul 2>&1
	    set gv_loop_again=true
        ) else (
            echo ERROR: Giving up after !gv_num_attempts! attempts
            exit /b 1
        )
    ) & rem if !gv_num_attempts! equ 0

) else (
    call :sub_trace !gv_server_file! found^^!
    set gv_loop_again=false & rem =============================== EXIT
)& rem if not exist "!gv_server_file!"

rem It's not possible to jump in a bracket context, so do it only now
if "!gv_loop_again!" == "true" goto :while_not_server_file

rem ========================================================= END LOOP

call :sub_trace Starting Emacs client via !gv_cmd_client!
!gv_cmd_client!

goto :eof & rem ============================================= END MAIN

rem ******************************************************************
rem * Subroutine: sub_trace
rem *
rem * Write all command line arguments to a trace file
rem *
rem * Parameters:
rem * %* - Strings to be written to trace file
rem *
rem * Returns:
rem * nothing
rem ******************************************************************
:sub_trace
setlocal

echo %* >>!gv_trace_file!

endlocal
goto :eof

rem ******************************************************************
rem * Subroutine: sub_determine_sleep_cmd
rem *
rem * Determine how we can sleep (wait) from the shell.
rem * In W2K3, we must use SLEEP
rem * In W2K8, we must use TIMEOUT /T
rem *
rem * Parameters:
rem * none
rem *
rem * Returns:
rem * command name as string
rem ******************************************************************
:sub_determine_sleep_cmd
setlocal
set lv_return=

rem Invoking a new shell with /c will return the errorlevel
rem from the command executed

rem ************************************************************
rem Try CMD builtin command sleep (W2K3)
rem ************************************************************
cmd /c "sleep /? >nul 2>&1"

if not errorlevel 1 (
    set lv_return=sleep
    call :sub_trace This system has sleep as a builtin Windows command
) else (
    set lv_errorlevel=!errorlevel!
    call :sub_trace ^
         Trying CMD builtin sleep returned errorlevel !lv_errorlevel!
)

rem ************************************************************
rem Try Cygwin sleep.exe from GNU Coreutils. Depending on the
rem system's PATH, this may take precedence before the Windows
rem CMD builtin sleep. Since GNU sleep doesn't accept the /?
rem option, our test above will fail for that.
rem ************************************************************
if "!lv_return!" == "" (
    cmd /c "sleep --help >nul 2>&1"

    if not errorlevel 1 (
        set lv_return=sleep
        call :sub_trace This system has GNU sleep
    ) else (
        set lv_errorlevel=!errorlevel!
        call :sub_trace ^
             Trying GNU sleep returned errorlevel !lv_errorlevel!
    )
)

rem ************************************************************
rem Try CMD builtin command timeout /t (W2K8 and above)
rem Note that if have Cygwin, we also have GNU timeout,
rem which always seems to return 0, even when an illegal argument
rem like /? is supplied. Trying to use GNU timeout /t, however,
rem doesn't work. So this last test will give a wrong result
rem on systems where Cygwin is installed and comes before cmd.exe
rem in the PATH.
rem 
rem To work around this problem, the test for GNU timeout is executed
rem AFTER the test for GNU sleep. If we have Cygwin, the GNU sleep
rem test above will have succeeded and lv_return is already filled,
rem so this final test is never executed.
rem ************************************************************
if "!lv_return!" == "" (
    cmd /c "timeout /? >nul 2>&1"

    if not errorlevel 1 (
        set lv_return=timeout /t
        call :sub_trace This system has timeout as a builtin Windows command
    ) else (
        set lv_errorlevel=!errorlevel!
        call :sub_trace ^
             Trying CMD builtin timeout returned errorlevel !lv_errorlevel!
    )
)

endlocal & set gv_return=%lv_return%
goto :eof
