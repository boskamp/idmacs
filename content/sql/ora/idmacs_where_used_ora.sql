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
-- Synopsis: Find any string in SAP(R) Identity Management (IDM)
--           JavaScript or SQL source code, job definitions or tasks.
--
--           This is one of three related files:
--
--           [1] idmacs_where_used_install_ora.sql
--           [2] idmacs_where_used_ora.sql          (THIS FILE)
--           [3] idmacs_where_used_uinstall_ora.sql
--
--           ALL OF THESE FILES ARE SPECIFIC TO ORACLE(R) DATABASE.
--
--           The most recent versions of these files, as well as
--           versions for other databases, can be found at GitHub:
--
--           https://github.com/boskamp/idmacs
--
-- Usage:    1. Before you can use this query, YOU MUST RUN THE
--              INSTALLER [1] once.
--
--           2. Paste this source code into the SQL editor of any
--              graphical SQL client that can display CLOB and/or
--              XML data. Microsoft(R) SQL Server Management Studio,
--              Oracle(R) SQL Developer and IBM(R) Data Studio are
--              known to work fine. Others may work as well.
--
--           3. In the SQL editor, replace YOUR_SEARCH_TERM_HERE
--              near the end of the code with the string you want
--              to search for. See also section "Example".
--
--           4. Execute the resulting query as ADMIN user (MXMC_ADMIN).
--
<<<<<<< HEAD
--           5. (Optional) Examine MATCH_LOCATION_TEXT and MATCH_DOCUMENT
=======
--           5. (Optional) Examine MATCH_LOCATION_* and MATCH_DOCUMENT
>>>>>>> 9676977375cd512737dfb592b6888ebaf339100e
--              values of the result set directly in the SQL client.
--
--           6. (Optional) Locate tasks or jobs corresponding to NODE_ID
--              values from your result set using MMC's Find action.
--              Make sure to check "Find Tasks or Jobs only"!
--
-- Example:  To search for all occurrences of the string MX_DISABLED,
--           the code near the end should look like:
--
--           WHERE z_idmacs_where_used.clob_contains(
--               match_location_text
--               , 'MX_DISABLED'
--           ) > 0
--
--           Search is CASE-INSENSITIVE and uses SUBSTRING MATCHING,
--           so this query would find any of the following strings,
--           for instance:
--
--           MX_DISABLED
--           mx_disabled
--           #mx_disabled
--
-- Result:   The result set will list any locations that contain your
--           search term. Its rows have the following structure:
--
--           1. NODE_TYPE           : char(1)
--           2. NODE_ID             : number(10,0)
--           3. NODE_NAME           : varchar2(2000 char)
--           4. MATCH_LOCATION_TEXT : clob
--           5. MATCH_DOCUMENT      : xmltype
--
--           NODE_TYPE = [ 'A' -- Attribute (Identity Store attribute)
--                       | 'T' -- Task
--                       | 'S' -- Script (global script)
--                       | 'J' -- Job
--                       ]
--
--           NODE_ID   = [ attribute_id
--                       | task_id
--                       | script_id
--                       | job_id
--                       ]
--
--           NODE_NAME = [ attribute_name
--                       | task_name
--                       | script_name
--                       | job_name
--                       ]
--
--           MATCH_LOCATION_TEXT is a piece of text contained in
--           MATCH_DOCUMENT. This piece of text contains your search
--           term at least once.
--
--           MATCH_DOCUMENT is an XML representation of the whole
--           designtime object (attribute, task, script or job)
--           identified by NODE_TYPE and NODE_ID.
--
--           For MATCH_DOCUMENTs that contain your search term multiple
--           times, the result set will generally contain multiple lines
--           which differ only in their MATCH_LOCATION_TEXT values.
--
-- Credits:  Martin Smith http://stackoverflow.com/users/73226/martin-smith
--           Thanks for explaining how to display large text in SSMS
--
--           Finn Ellebaek Nielsen https://ellebaek.wordpress.com
--           Thanks for explaining how to convert LONG to CLOB on the fly
--
-- *******************************************************************
WITH text_datasource_cte(node_id,node_type,node_name,native_xml) AS (
SELECT
     a.attr_id
     ,'A' -- Attribute
     ,a.attrname
     ,xmlroot(
         xmlelement(
            NAME "ATTRIBUTE_S"
            ,xmlconcat(
                xmlforest(
                    a.attr_id
		    ,a.is_id
		    ,i.idstorename
                    ,a.attrname
                    ,a.info
                    ,a.deltask
                    ,a.modtask
                    ,a.instask                
                    ,a.display_name
                    ,a.tooltip
                    ,a.regexvalidate
                    ,a.sqlvalues
                    ,a.sqlaccesstask
                    ,a.sqlvaluestable
                    ,a.sqlvaluesid)
                    ,xmlforest(
                        (SELECT
                            xmlagg(
                                xmlelement(
                                    NAME "ATTRIBUTE_VALUE_CHOICE_S"
                                    ,xmlforest(
                                        v.attr_value))
                            ORDER BY v.attr_value)
                        FROM mxi_attrvaluechoice v
                        WHERE v.attr_id=a.attr_id)
                        AS "ATTRIBUTE_VALUE_CHOICE_T")))
         ,version '1.0')
     FROM mxiv_allattributes a
     INNER JOIN mxi_idstores i
     ON a.is_id=i.is_id
UNION ALL SELECT
    t.taskid
    ,'T' -- Task
    ,t.taskname
    ,xmlroot(
        xmlelement(
            NAME "TASK_S"
            ,xmlconcat(
                xmlforest(
                    t.taskid
                    ,t.taskname
                    ,t.boolsql)
                ,xmlforest(
                    (SELECT
                        xmlagg(
                            xmlelement(
                                NAME "TASK_ATTRIBUTE_S"
                                ,xmlforest(
                                    ta.attr_id
                                    ,ta.attrname
                                    ,ta.sqlvalues))
                            ORDER BY ta.attrname)
                        FROM mxiv_taskattributes ta
                        WHERE ta.taskid=t.taskid)
                    AS "TASK_ATTRIBUTE_T")
                ,xmlforest(
                    (SELECT
                        xmlagg(
                            xmlelement(
                                NAME "TASK_ACCESS_S"
                                ,xmlforest(
                                    tx.sqlscript
                                    ,tx.targetsqlscript
                                    ,a.attrname         AS "ATTRNAME"
                                    ,ta.attrname        AS "TARGETATTRNAME"
                                    ,e.mcmskeyvalue     AS "MSKEYVALUE"
                                    ,te.mcmskeyvalue    AS "TARGETMSKEYVALUE"))
                        ORDER BY
                            tx.sqlscript
                            ,tx.targetsqlscript)
                        FROM mxpv_taskaccess tx
                        LEFT OUTER JOIN mxi_attributes a
                        ON tx.attr_id=a.attr_id
                        LEFT OUTER JOIN mxi_attributes ta
                        ON tx.targetattr_id=ta.attr_id
                        LEFT OUTER JOIN idmv_entry_simple e
                        ON tx.mskey=e.mcmskey
                        LEFT OUTER JOIN idmv_entry_simple te
                        ON tx.targetmskey=te.mcmskey
                        WHERE tx.taskid=t.taskid)
                    AS "TASK_ACCESS_T")))
        ,version '1.0')
    FROM mxpv_alltaskinfo t     
)     
,b64_enc_prefix_cte(node_id, node_type, node_name, b64_enc_prefix, is_xml) AS (
SELECT
    scriptid
    ,'S' -- Global script
    -- node_name length must be consistent with z_idmacs_clob_obj.node_name
    ,cast(scriptname as VARCHAR2(2000))
    ,scriptdefinition
    ,0
    FROM mc_global_scripts
UNION ALL SELECT
    node_id
    ,'J' -- Job
    ,node_name
    ,node_data
    ,1
    FROM table(
        z_idmacs_where_used.read_tab_with_long_col_ptf(
            'MC_JOBS'        --iv_tab_name
            ,'JOBID'         --iv_id_column_name
            ,'NAME'          --iv_name_colun_name
            ,'JOBDEFINITION' --iv_long_column_name
        )
    )
)
,b64_enc_cte(node_id, node_type, node_name, b64_enc,is_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    -- SUBSTR returns datatype of arg1 (CLOB in this case)
    ,substr(
        -- CLOB, so return value will be CLOB
        b64_enc_prefix
        -- LENGTH accepts CHAR, VARCHAR2, NCHAR,
        -- NVARCHAR2,CLOB, or NCLOB
        ,length('{B64}') + 1
        ,length(b64_enc_prefix) - length('{B64}')
    )
    ,is_xml
    FROM b64_enc_prefix_cte
)
,b64_dec_cte(node_id,node_type,node_name,b64_dec,is_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    ,z_idmacs_where_used.base64_decode(b64_enc)
    ,is_xml
    FROM b64_enc_cte
)
,b64_datasource_cte(node_id, node_type, node_name, native_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    ,CASE is_xml
        WHEN 1 THEN xmlparse(DOCUMENT b64_dec)
        -- TODO: this generates the CDATA section verbatim,
        -- which differs from the behavior on DB/2
        ELSE sys_xmlgen(b64_dec, XMLFormat(enclTag => 'ROOT'))
    END
    FROM b64_dec_cte
)
,any_datasource_cte(node_id, node_type, node_name, native_xml) AS (
SELECT
     *
     FROM b64_datasource_cte
UNION ALL SELECT
     *
     FROM text_datasource_cte
)
,all_text_cte(node_id, node_type, node_name, match_location_text, match_document) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    ,dbms_xmlgen.convert(
        extract(match_location,'.').getCLOBVal()
        , 1 -- value of dbms_xmlgen.entity_decode
    ) AS match_location_text
    ,native_xml as match_document

    FROM any_datasource_cte
    ,xmltable('
        for $t in ( $native_xml//attribute::*
                   ,$native_xml/descendant-or-self::text())
        return $t
        ' 
        PASSING native_xml AS "native_xml"
        COLUMNS match_location XMLType PATH '.'
    )
)
SELECT
    * 
    FROM all_text_cte
    WHERE z_idmacs_where_used.clob_contains(
        match_location_text
        , 'YOUR_SEARCH_TERM_HERE'
    ) > 0
    ORDER BY node_type, node_id
;
