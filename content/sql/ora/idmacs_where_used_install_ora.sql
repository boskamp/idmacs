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

  DROP PACKAGE BODY "IDMACS_WHERE_USED";
  DROP PACKAGE "IDMACS_WHERE_USED";
  -- DROP TYPE BODY "IDMACS_CLOB_TAB"; --this doesn't have any body
  DROP TYPE "IDMACS_CLOB_TAB";
  DROP TYPE BODY "IDMACS_CLOB_OBJ";
  DROP TYPE "IDMACS_CLOB_OBJ";
/  
--------------------------------------------------------
--  DDL for Type IDMACS_CLOB_OBJ
--------------------------------------------------------
  CREATE OR REPLACE TYPE "IDMACS_CLOB_OBJ" 
    AS OBJECT (
  
    node_id          NUMBER(10,0)
    ,node_name       VARCHAR2(2000)
    ,node_data       CLOB

    ,CONSTRUCTOR FUNCTION IDMACS_CLOB_OBJ
    RETURN SELF AS RESULT
  
    ,CONSTRUCTOR FUNCTION IDMACS_CLOB_OBJ(iv_dbms_sql_cursor IN INTEGER)
    RETURN SELF AS RESULT

  ,MEMBER PROCEDURE define_columns(iv_dbms_sql_cursor IN INTEGER)
);
/
CREATE OR REPLACE TYPE BODY "IDMACS_CLOB_OBJ" 
    AS
  /**
   * Constructor. Sets all attributes to NULL.
   * @return  New object type instance.
   */
  CONSTRUCTOR FUNCTION IDMACS_CLOB_OBJ
  RETURN SELF AS RESULT AS

  BEGIN
    RETURN;
  END IDMACS_CLOB_OBJ;

  /**
   * Constructs a new instance with values fetched from DBMS_SQL cursor
   *
   * @param   iv_dbms_sql_cursor
   * @return  new object type instance
   */
  CONSTRUCTOR FUNCTION IDMACS_CLOB_OBJ(iv_dbms_sql_cursor IN INTEGER)
  RETURN SELF AS RESULT
  AS
    lv_long_val LONG;
    lv_long_len INTEGER;
    lv_buf_len  INTEGER := 32760;
    lv_cur_pos  NUMBER := 0; --TODO: verify choice of data type
  BEGIN
      dbms_sql.column_value(iv_dbms_sql_cursor, 01, node_id);
      dbms_sql.column_value(iv_dbms_sql_cursor, 02, node_name);

      -- Create CLOB.
      dbms_lob.createtemporary(node_data, FALSE, dbms_lob.call);

      -- Piecewise fetching of the LONG column, appending to the CLOB
      loop
          dbms_sql.column_value_long(
              iv_dbms_sql_cursor
              ,03 --column ID of LONG column
              ,lv_buf_len
              ,lv_cur_pos
              ,lv_long_val
              ,lv_long_len
          );
          EXIT WHEN lv_long_len = 0;

	        dbms_lob.append(node_data, lv_long_val);
          lv_cur_pos := lv_cur_pos + lv_long_len;
      END LOOP;

    RETURN;
  END idmacs_clob_obj;

  /**
   * Defines all columns in DBMS_SQL cursor
   * @param  iv_dbms_sql_cursor parsed DBMS_SQL cursor
   */
  MEMBER PROCEDURE define_columns(iv_dbms_sql_cursor IN INTEGER) 
  AS

  BEGIN
     -- INT column
    dbms_sql.define_column(iv_dbms_sql_cursor, 01, node_id);
    -- VARCHAR2 column
    dbms_sql.define_column(iv_dbms_sql_cursor, 02, node_name, 90);
    -- LONG column
    dbms_sql.define_column_long(iv_dbms_sql_cursor, 03);
  END define_columns;
END;
/
--------------------------------------------------------
--  DDL for Type IDMACS_CLOB_TAB
--------------------------------------------------------

  CREATE OR REPLACE TYPE "IDMACS_CLOB_TAB" 
    AS
    TABLE OF IDMACS_CLOB_OBJ;
/
--------------------------------------------------------
--  DDL for Package IDMACS_WHERE_USED
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "IDMACS_WHERE_USED" 
    AUTHID CURRENT_USER
    AS 

  /**
   * Public function CLOB_CONTAINS
   *
   * @param IV_STRING string to test
   * @param IV_SUBSTR substring to test for
   * @return 1 if IV_STRING contains IV_SUBSTR, 0 otherwise
   */
   FUNCTION clob_contains(
       iv_string CLOB
       ,iv_substr VARCHAR2
   )
   RETURN INTEGER;

    /**
     * Public function BASE64_DECODE
     *
     * TODO: documentation
     */
    FUNCTION base64_decode(
        iv_base64 IN CLOB
    )
    RETURN CLOB;
    
    /**
     * Public function READ_TAB_WITH_LONG_COL_PFF
     *
     * TODO: documentation
     */
    FUNCTION read_tab_with_long_col_ptf(
        iv_table_name        IN VARCHAR2
        ,iv_id_column_name   IN VARCHAR2
        ,iv_name_column_name IN VARCHAR2
        ,iv_long_column_name IN VARCHAR2
    )
    RETURN idmacs_clob_tab PIPELINED;
    
END IDMACS_WHERE_USED;
/

--------------------------------------------------------
--  DDL for Package Body IDMACS_WHERE_USED
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IDMACS_WHERE_USED" 
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
       SELECT xmlcast(
           xmlquery('
               let $lv_result := contains($iv_string, $iv_substr)
               return $lv_result
               '
               PASSING 
                   iv_string  AS "iv_string"
                   ,iv_substr AS "iv_substr"
               RETURNING CONTENT
           --xs:boolean(true) is cast to 1
           --xs:boolean(false) is cast to 0
           ) AS INTEGER) INTO lv_result
           FROM dual
           ;

       RETURN lv_result;
  END varchar2_contains;

  FUNCTION clob_contains(
       iv_string CLOB
       ,iv_substr VARCHAR2
   )
   RETURN INTEGER
   AS 
      -- Initialize result to false (0), so a zero-length input
      -- IV_STRING will always return false. This is consistent
      -- with VARCHAR2_CONTAINS and XQuery fn:contains().
      lv_result               INTEGER     := 0;
      lv_string               VARCHAR2(2000 CHAR);
      lv_num_chars_to_read    PLS_INTEGER := 0;
      lv_offset               PLS_INTEGER := 1;
      lv_num_chars_remaining  PLS_INTEGER := 0;
  BEGIN
      lv_num_chars_remaining := length(iv_string) - lv_offset + 1;
     
      WHILE lv_num_chars_remaining > 0 LOOP
     
      lv_num_chars_to_read := least(lv_num_chars_remaining, 2000);
     
      lv_string := dbms_lob.substr(
          iv_string --CLOB, so returned datatype is VARCHAR2
          ,lv_num_chars_to_read
          ,lv_offset
      );
     
      lv_offset := lv_offset + lv_num_chars_to_read;
     
      lv_num_chars_remaining
          := lv_num_chars_remaining - lv_num_chars_to_read;
                                     
        lv_result := idmacs_where_used.varchar2_contains(lv_string, iv_substr);
        EXIT WHEN lv_result = 1;
      END LOOP;
     
      RETURN lv_result;
  END clob_contains;
   
  /**
   * Private procedure validate_column_name
   *
   * Checks that iv_col_name is a column name
   * of table iv_tab_name. If not, raises an application error.
   */
  PROCEDURE validate_table_column_name(
      iv_tab_name VARCHAR2
      ,iv_col_name VARCHAR2
  )
  AS
      lv_count integer;
  BEGIN
      SELECT count(*) INTO lv_count
          FROM user_tables
          WHERE table_name = iv_tab_name
          ;
      IF lv_count = 0 THEN
         raise_application_error(
             -20010
             , 'Not a valid table name: '||iv_tab_name
         );
      END IF;
      SELECT count(*) INTO lv_count
          FROM user_tab_cols
          WHERE table_name=iv_tab_name
          AND column_name = iv_col_name
          ;
      IF lv_count = 0 THEN
          raise_application_error(
             -20011
             , 'Not a valid column name: '||iv_col_name
          );
      END IF;
  END validate_table_column_name;
    
  FUNCTION base64_decode(
        iv_base64 IN CLOB
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
                                     
        lv_result
          := lv_result
	  --TODO: use dbms_lob.append instead of ||
          || utl_raw.cast_to_varchar2(
              utl_encode.base64_decode(
                utl_raw.cast_to_raw(lv_substring)));
      END LOOP;
     
      RETURN lv_result;
  
  END base64_decode; 
  
FUNCTION read_tab_with_long_col_ptf(
        iv_table_name        IN VARCHAR2
        ,iv_id_column_name   IN VARCHAR2
        ,iv_name_column_name IN VARCHAR2
        ,iv_long_column_name IN VARCHAR2
    )
    RETURN idmacs_clob_tab PIPELINED
AS
  lv_query           VARCHAR2(2000);
  lv_dbms_sql_cursor INTEGER;
  lv_execute_rc      PLS_INTEGER;
  LO_CLOB_OBJECT     IDMACS_CLOB_OBJ;
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
  
  dbms_sql.parse(lv_dbms_sql_cursor, lv_query, dbms_sql.NATIVE);
  
  -- Define columns through dummy object type instance
  lo_clob_object := idmacs_clob_obj();
  
  lo_clob_object.define_columns(lv_dbms_sql_cursor);
  
  -- Execute
  lv_execute_rc := dbms_sql.execute(lv_dbms_sql_cursor);
  dbms_output.put_line('Cursor executed, RC=' || lv_execute_rc);
  
  -- Fetch all rows, pipe each back
  WHILE dbms_sql.fetch_rows(lv_dbms_sql_cursor) > 0 LOOP
  
    lo_clob_object := idmacs_clob_obj(lv_dbms_sql_cursor);
    
    PIPE ROW(lo_clob_object);
    
    dbms_output.put_line(
      'Piped back table='
      || iv_table_name
      || ' ,node_id=' 
      || lo_clob_object.node_id
      || ', node_name=' 
      || lo_clob_object.node_name
    );
  END LOOP;

  dbms_sql.close_cursor(lv_dbms_sql_cursor);
EXCEPTION
  WHEN OTHERS THEN
    
    dbms_output.put_line('SQLERRM:    ' || sqlerrm);
    dbms_output.put_line('CALLSTACK:  ' || dbms_utility.format_call_stack);
    dbms_output.put_line('ERRORSTACK: ' || dbms_utility.format_error_stack);
    dbms_output.put_line('BACKTRACE:  ' || dbms_utility.format_error_backtrace);
    
    IF dbms_sql.is_open(lv_dbms_sql_cursor) THEN
      dbms_sql.close_cursor(lv_dbms_sql_cursor);
    END IF;

    RAISE;
END read_tab_with_long_col_ptf;

END IDMACS_WHERE_USED;
/
