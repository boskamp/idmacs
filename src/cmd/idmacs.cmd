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

rem Name of trace file; always located in current working directory
set gv_trace_file=dev_idmacs

rem Truncate trace file
echo( >!gv_trace_file!

rem The file where Emacs server publishes its listener socket
set gv_server_file=%APPDATA%\.emacs.d\server\server
call :sub_trace gv_server_file=!gv_server_file!

rem Command line to start Emacs server with
set gv_cmd_server="%~dp0runemacs.exe"
call :sub_trace gv_cmd_server=!gv_cmd_server!

rem Command line to start Emacs client with
set gv_cmd_client="%~dp0emacsclient.exe" "%*"
call :sub_trace gv_cmd_client=!gv_cmd_client!

set /a "gv_num_attempts=-1"
set gv_loop_again=false
set gv_start_all_over=true

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
            sleep 1
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
