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
-- TODO:
-- * Documentation
-- *******************************************************************

--------------------------------------------------------
--  DDL for Type z_idmacs_clob_obj
--------------------------------------------------------
CREATE OR REPLACE
    TYPE z_idmacs_clob_obj
    AUTHID CURRENT_USER
    AS OBJECT (
  
    node_id    NUMBER(10,0)
    ,node_name VARCHAR2(2000 CHAR)
    ,node_data CLOB

    ,CONSTRUCTOR FUNCTION z_idmacs_clob_obj
    RETURN SELF AS RESULT
  
    ,CONSTRUCTOR FUNCTION z_idmacs_clob_obj(
        iv_dbms_sql_cursor IN INTEGER
    )
    RETURN SELF AS RESULT

    ,MEMBER PROCEDURE define_columns(iv_dbms_sql_cursor IN INTEGER)
);
/

CREATE OR REPLACE
    TYPE BODY z_idmacs_clob_obj
    AS
    /**
     * Constructor. Sets all attributes to NULL.
     * @return  New object type instance.
     */
    CONSTRUCTOR FUNCTION z_idmacs_clob_obj
    RETURN SELF AS RESULT
    AS

    BEGIN
        RETURN;
    END z_idmacs_clob_obj;

    /**
     * Constructs a new instance with values fetched from DBMS_SQL cursor
     *
     * @param   IV_DBMS_SQL_CURSOR
     * @return  new object type instance
     */
    CONSTRUCTOR FUNCTION z_idmacs_clob_obj(
        iv_dbms_sql_cursor IN INTEGER)
    RETURN SELF AS RESULT
    AS
        lv_buf_val        VARCHAR2(32767 BYTE);
        lv_buf_len        INTEGER := 32767;
        lv_bytes_returned INTEGER;
        lv_offset         INTEGER := 0;
    BEGIN
        dbms_sql.column_value(iv_dbms_sql_cursor, 1, node_id);
        dbms_sql.column_value(iv_dbms_sql_cursor, 2, node_name);

        -- Create CLOB that will not be cached and free'd after this call
        dbms_lob.createtemporary(node_data, FALSE, dbms_lob.call);

        -- Piecewise fetching of the LONG column into VARCHAR2 buffer
        LOOP
            dbms_sql.column_value_long(
                iv_dbms_sql_cursor
                ,3 --position of LONG column in cursor's SELECT list 
                ,lv_buf_len
                ,lv_offset
                ,lv_buf_val
                ,lv_bytes_returned
            );
            EXIT WHEN lv_bytes_returned = 0;

            -- Concatentation operator vs. dbms_lob.append
            -- performed the same in my tests on 11g
            node_data := node_data || lv_buf_val;
            lv_offset := lv_offset + lv_bytes_returned;
        END LOOP;

        RETURN;
    END z_idmacs_clob_obj;

    /**
     * Defines all columns in DBMS_SQL cursor
     *
     * @param  IV_DBMS_SQL_CURSOR    parsed DBMS_SQL cursor
     */
    MEMBER PROCEDURE define_columns(
        iv_dbms_sql_cursor IN INTEGER
    ) 
    AS

    BEGIN
        -- INT column
        dbms_sql.define_column(
            iv_dbms_sql_cursor
            ,1
            ,node_id
        );
        -- VARCHAR2 column
        dbms_sql.define_column(
            iv_dbms_sql_cursor
            ,2
            ,node_name
            ,2000 -- character length of node_name's data type
        );
        -- LONG column
        dbms_sql.define_column_long(
            iv_dbms_sql_cursor
            ,3
        );
    END define_columns;
END;
/

--------------------------------------------------------
--  DDL for Type z_idmacs_clob_tab
--------------------------------------------------------
CREATE OR REPLACE TYPE Z_IDMACS_CLOB_TAB
    -- =================================================
    -- Specifying an invoker_rights_clause doesn't seem
    -- to work for anything other than OBJECT types
    -- =================================================
    -- AUTHID CURRENT_USER
    AS
    TABLE OF z_idmacs_clob_obj;
/

--------------------------------------------------------
--  DDL for Package z_idmacs_where_used
--------------------------------------------------------
CREATE OR REPLACE PACKAGE z_idmacs_where_used
    AUTHID CURRENT_USER
    AS

    /**
     * Public function CLOB_CONTAINS
     *
     * Test whether IV_SUBSTR is contained in IV_STRING,
     * where IV_STRING is a CLOB. When IV_CASE_SENSITIVE
     * is 0 (the default), this is the same as calling
     * dbms_lob.instr(). Otherwise, a case-sensitive
     * comparison is performed.
     *
     * @param IV_STRING            string to test
     * @param IV_SUBSTR            substring to test for
     * @param IV_CASE_SENSITIVE    0 to ignore case,
     *                             1 to match case (default: 0)
     * @return 1 if IV_STRING contains IV_SUBSTR, 0 otherwise
     */
    FUNCTION clob_contains(
        iv_string          CLOB
        ,iv_substr         VARCHAR2
        ,iv_case_sensitive INTEGER DEFAULT 0
    )
    RETURN INTEGER;

    /**
     * Public function BASE64_DECODE
     *
     * Special purpose BASE64 decoder which
     * assumes that the result of decoding is
     * not just any raw binary data, but charater-like
     * data which can be represented as a CLOB.
     *
     * @param: IV_BASE64 encoded data
     * @return decoded, character-like data
     */
    FUNCTION base64_decode(
        iv_base64 CLOB
    )
    RETURN CLOB;
    
    /**
     * Public function READ_TAB_WITH_LONG_COL_PTF
     *
     * Pipelined table function that reads from a source table
     * specified in IV_TABLE_NAME and converts LONG data stored
     * in column IV_LONG_COLUMN_NAME to CLOB on the fly.
     *
     * The table supplied in IV_TABLE_NAME must have one INT column
     * containing a unique ID for each row.
     * Provide the name of this column in IV_ID_COLUMN_NAME.
     *
     * Second, the table must have a char-like column containing
     * a NAME for each row.
     * Provide the name of this column in IV_NAME_COLUMN_NAME.
     * 
     * The combination of ID, NAME and CLOB data (converted from
     * LONG) will be returned in a table whose rows have the
     * object type Z_IDMACS_CLOB_TAB.
     *
     * @param IV_TABLE_NAME        table to read from
     * @param IV_ID_COLUMN_NAME    ID column in table
     * @param IV_NAME_COLUMN_NAME  name column in table
     * @param IV_LONG_COLUMN_NAME  column in table with LONG data
     * @return                     table of ID, name and CLOB data
     */
    FUNCTION read_tab_with_long_col_ptf(
        iv_table_name        VARCHAR2
        ,iv_id_column_name   VARCHAR2
        ,iv_name_column_name VARCHAR2
        ,iv_long_column_name VARCHAR2
    )
    RETURN z_idmacs_clob_tab PIPELINED;
    
END z_idmacs_where_used;
/

--------------------------------------------------------
--  DDL for Package Body z_idmacs_where_used
--------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY z_idmacs_where_used
    AS

    /**
     * Private function VARCHAR2_CONTAINS
     *
     * @param IV_STRING string to test
     * @param IV_SUBSTR substring to test for
     * @return 1 if IV_STRING contains IV_SUBSTR, 0 otherwise
     */
    FUNCTION varchar2_contains(
        iv_string VARCHAR2
        ,iv_substr VARCHAR2
    )
    RETURN INTEGER
    AS 
        lv_result INTEGER;
    BEGIN
        IF instr(iv_string, iv_substr) > 0 THEN
            lv_result := 1;
        ELSE
            lv_result := 0;
        END IF;

        RETURN lv_result;
    END varchar2_contains;

    FUNCTION clob_contains(
        iv_string          CLOB
        ,iv_substr         VARCHAR2
        ,iv_case_sensitive INTEGER DEFAULT 0
    )
    RETURN INTEGER
    AS 
        -- Initialize result to false (0), so a zero-length input
        -- IV_STRING will always return false. This is consistent
        -- with VARCHAR2_CONTAINS and XQuery fn:contains().
        lv_result               INTEGER     := 0;
        lv_substr_upper         VARCHAR2(32767 BYTE);
        lv_buf_val              VARCHAR2(2000 CHAR); -- TODO: use max byte size
        lv_num_chars_to_read    PLS_INTEGER := 0;
        lv_offset               PLS_INTEGER := 1;
        lv_num_chars_remaining  PLS_INTEGER := 0;
    BEGIN
        IF iv_case_sensitive = 0 THEN
            lv_substr_upper := upper(iv_substr);

            lv_num_chars_remaining := length(iv_string) - lv_offset + 1;
     
            WHILE lv_num_chars_remaining > 0 LOOP
     
                lv_num_chars_to_read := least(lv_num_chars_remaining, 2000);
     
                lv_buf_val := dbms_lob.substr(
                    iv_string --CLOB, so returned datatype is VARCHAR2
                    ,lv_num_chars_to_read
                    ,lv_offset
                );

                -- TODO: adapt offset computation so that matches across
                -- buffer boundary work as well; right now, they're not found
                lv_offset := lv_offset + lv_num_chars_to_read;
     
                lv_num_chars_remaining
                    := lv_num_chars_remaining - lv_num_chars_to_read;
                                     
                lv_result
                    := z_idmacs_where_used.varchar2_contains(
                        upper(lv_buf_val)
                        ,lv_substr_upper
                    );
          
                EXIT WHEN lv_result = 1;
            END LOOP;

        ELSE -- case-insensitive search
            IF dbms_lob.instr(iv_string, iv_substr) > 0 THEN
                lv_result := 1;
            ELSE
                lv_result := 0;
            END IF;
        END IF;
     
        RETURN lv_result;

    END clob_contains;
   
    /**
     * Private procedure validate_column_name
     *
     * Checks that iv_col_name is a column name
     * of table iv_tab_name. If not, raises an application error.
     */
    PROCEDURE validate_table_column_name(
        iv_tab_name  IN VARCHAR2
        ,iv_col_name IN VARCHAR2
    )
    AS
        lv_count INTEGER;
    BEGIN
        -- ============================================================
        -- UNCOMMENT FOR DEBUGGING ONLY
        -- and ensure buffer for DBMS output is large enough
        -- ============================================================   
        -- dbms_output.put_line('Current schema is ' 
        --    || sys_context('userenv', 'current_schema'));
        -- ============================================================   
    
        SELECT count(*) INTO lv_count
            -- Note that the view USER_TABLES would not work in general,
            -- but only work when this code is executed by the table owner
            -- (OPER user)
            FROM all_tables
            WHERE table_name = iv_tab_name
            ;
        IF lv_count = 0 THEN
            raise_application_error(
                -20010
                ,'Z_IDMACS_WHERE_USED: Not a valid table name: '
		||iv_tab_name
            );
        END IF;

          SELECT count(*) INTO lv_count
            -- USER_TAB_COLS would only work for OPER (see above)
            FROM all_tab_cols
            WHERE table_name  = iv_tab_name
            AND   column_name = iv_col_name
            ;
        IF lv_count = 0 THEN
            raise_application_error(
                -20011
                ,'Z_IDMACS_WHERE_USED: Not a valid column name: '
		||iv_col_name
            );
        END IF;
    END validate_table_column_name;
    
    FUNCTION base64_decode(
        iv_base64 CLOB
    )
    RETURN CLOB
    AS
        lv_result               CLOB;
        lv_substring            VARCHAR2(2000 CHAR);
        lv_num_chars_to_read    PLS_INTEGER := 0;
        lv_offset               PLS_INTEGER := 1;
        lv_num_chars_remaining  PLS_INTEGER := 0;
    BEGIN
        lv_num_chars_remaining := length(iv_base64) - lv_offset + 1;

        -- Create CLOB that will not be cached and free'd after this call
        dbms_lob.createtemporary(lv_result, FALSE, dbms_lob.call);
    
        WHILE lv_num_chars_remaining > 0 LOOP
     
            lv_num_chars_to_read := least(lv_num_chars_remaining, 2000);
     
            lv_substring := dbms_lob.substr(
                iv_base64
                ,lv_num_chars_to_read
                ,lv_offset
            );
     
            lv_offset := lv_offset + lv_num_chars_to_read;
     
            lv_num_chars_remaining
                := lv_num_chars_remaining - lv_num_chars_to_read;

            -- Concatentation operator vs. dbms_lob.append
            -- performed the same in my tests on 11g
            lv_result := lv_result || utl_raw.cast_to_varchar2(
                    utl_encode.base64_decode(
                        utl_raw.cast_to_raw(lv_substring)
                    )
            );
        
            END LOOP;
     
        RETURN lv_result;
  
    END base64_decode; 
  
    FUNCTION read_tab_with_long_col_ptf(
        iv_table_name        VARCHAR2
        ,iv_id_column_name   VARCHAR2
        ,iv_name_column_name VARCHAR2
        ,iv_long_column_name VARCHAR2
    )
    RETURN z_idmacs_clob_tab PIPELINED
    AS
        lv_query           VARCHAR2(2000);
        lv_dbms_sql_cursor INTEGER;
        lv_execute_rc      PLS_INTEGER;
        lo_clob_object     z_idmacs_clob_obj;
    BEGIN
        --Validate dynamic SQL input to prevent SQL injection
        validate_table_column_name(iv_table_name, iv_id_column_name);
        validate_table_column_name(iv_table_name, iv_name_column_name);
        validate_table_column_name(iv_table_name, iv_long_column_name);
        
        lv_query :=
            'SELECT '
            || iv_id_column_name
            || ', '
            || iv_name_column_name
            || ', ' 
            || iv_long_column_name
            || ' FROM '
            || iv_table_name
            ;

        -- Create cursor, parse and bind
        lv_dbms_sql_cursor := dbms_sql.open_cursor();
  
        dbms_sql.parse(lv_dbms_sql_cursor, lv_query, dbms_sql.native);
  
        -- Define columns through dummy object type instance
        lo_clob_object := z_idmacs_clob_obj();
  
        lo_clob_object.define_columns(lv_dbms_sql_cursor);
  
        -- Execute
        lv_execute_rc := dbms_sql.execute(lv_dbms_sql_cursor);
        -- ============================================================
        -- UNCOMMENT FOR DEBUGGING ONLY
        -- and ensure buffer for DBMS output is large enough
        -- ============================================================
        -- dbms_output.put_line('Cursor executed, RC=' || lv_execute_rc);
        -- ============================================================
  
        -- Fetch all rows, pipe each back
        WHILE dbms_sql.fetch_rows(lv_dbms_sql_cursor) > 0 LOOP
  
            lo_clob_object := z_idmacs_clob_obj(lv_dbms_sql_cursor);
    
            PIPE ROW(lo_clob_object);

            -- ============================================================
            -- UNCOMMENT FOR DEBUGGING ONLY
            -- and ensure buffer for DBMS output is large enough
            -- ============================================================
            -- dbms_output.put_line(
            --     'Piped back table='
            --     || iv_table_name
            --     || ' ,node_id=' 
            --     || lo_clob_object.node_id
            --     || ', node_name=' 
            --     || lo_clob_object.node_name
            -- );
            -- ============================================================    
        END LOOP;

        dbms_sql.close_cursor(lv_dbms_sql_cursor);
    EXCEPTION
        WHEN OTHERS THEN
        IF dbms_sql.is_open(lv_dbms_sql_cursor) THEN
            dbms_sql.close_cursor(lv_dbms_sql_cursor);
        END IF;
        RAISE;
    END read_tab_with_long_col_ptf;

END z_idmacs_where_used;
/
CREATE SYNONYM
    -- Replace MXMC with your DB table prefix
    mxmc_admin.z_idmacs_where_used 
    FOR mxmc_oper.z_idmacs_where_used;

GRANT EXECUTE
    -- Replace MXMC with your DB table prefix
    ON mxmc_oper.z_idmacs_where_used 
    TO mxmc_admin;
/

