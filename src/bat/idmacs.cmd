@echo off
if not exist "C:\Documents and Settings\Administrator.AMAZON-8A7331BF\Application Data\.emacs.d\server\server" (
   C:\emacs-24.1\bin\runemacs.exe
   sleep 2
)
c:\emacs-24.1\bin\emacsclientw.exe "%*"
