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
-- Run this script as user SYSTEM to create a custom full text search
-- policy. This is required because the default policy doesn't
-- work with underscores as expected.
--
-- User MXMC_OPER doesn't seem to have the required permissions
-- for package CTX_DDL.
-- *******************************************************************
BEGIN
ctx_ddl.drop_policy('Z_IDMACS_POLICY');
ctx_ddl.drop_preference('Z_IDMACS_LEXER');
END;
/

BEGIN
ctx_ddl.create_preference(preference_name => 'Z_IDMACS_LEXER'
                          ,object_name => 'BASIC_LEXER');
			  
ctx_ddl.set_attribute(preference_name => 'Z_IDMACS_LEXER'
                      ,attribute_name => 'printjoins'
                      ,attribute_value => '_');
END;
/

BEGIN
ctx_ddl.create_policy(policy_name => 'Z_IDMACS_POLICY'                      
                      ,lexer => 'Z_IDMACS_LEXER');
END;
/
