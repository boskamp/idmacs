-- Copyright (c) 2014, Lambert Boskamp
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:

-- 1. Redistributions of source code must retain the above copyright
-- notice, this list of conditions and the following disclaimer.

-- 2. Redistributions in binary form must reproduce the above 
-- copyright notice, this list of conditions and the following
-- disclaimer in the documentation and/or other materials provided
-- with the distribution.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
-- FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
-- COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
-- INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
-- OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- *******************************************************************
--
-- Synopsis: UNINSTALL a where-used query for use with SAP(R) IDM.
--
--           This is one of three related files:
--
--           [1] idmacs_where_used_install_ora.sql
--           [2] idmacs_where_used_ora.sql
--           [3] idmacs_where_used_uinstall_ora.sql (THIS FILE)
--
--           ALL OF THESE FILES ARE SPECIFIC TO ORACLE(R) DATABASE.
--
--           The most recent versions of these files, as well as
--           versions for other databases, can be found at GitHub:
--
--           https://github.com/boskamp/idmacs
--   
-- Usage:    1. If SAP(R) IDM has been installed with a database prefix
--              other than the default "MXMC", replace all occurrences
--              of "MXMC" in this script with your actual DB prefix.
--
--           2. Use any SQL client, such as Oracle(R) SQL Developer,
--              to connect to the SAP(R) IDM database and execute this
--              script as OPER user (MXMC_OPER, by default).
--
-- Result:   All schema objects created by the installer [1] 
--           have been removed from the SAP(R) IDM database.
--
-- *******************************************************************
DROP PACKAGE z_idmacs_where_used;
DROP TYPE z_idmacs_clob_tab;
DROP TYPE z_idmacs_clob_obj;

-- Replace MXMC with your DB table prefix
DROP SYNONYM mxmc_admin.z_idmacs_where_used;
