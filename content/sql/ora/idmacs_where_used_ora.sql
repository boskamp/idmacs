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
WITH text_datasource_cte(node_id,node_type,node_name,native_xml) AS (
SELECT
     a.attr_id
     ,'A'-- Attribute
     ,a.attrname
     ,   xmlelement(
            NAME "ATTRIBUTE_S"
            ,xmlconcat(
                xmlforest(
                    a.attr_id
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
                    ,xmlelement(
                        NAME "ATTRIBUTE_VALUE_CHOICE_T"
                        ,(SELECT
                            xmlagg(
                                xmlelement(
                                    NAME "ATTRIBUTE_VALUE_CHOICE_S"
                                    ,xmlforest(
                                        v.attr_value))
                            ORDER BY v.attr_value)
                        FROM mxi_attrvaluechoice v
                        WHERE v.attr_id=a.attr_id))))                    
     FROM mxiv_allattributes a
UNION ALL SELECT
    t.taskid
    ,'T'-- Task
    ,t.taskname
        ,xmlelement(
            NAME "TASK_S"
            ,xmlconcat(
                xmlforest(
                    t.taskid
                    ,t.taskname
                    ,t.boolsql)
                ,xmlelement(
                    NAME "TASK_ATTRIBUTE_T"
                    ,(SELECT
                        xmlagg(
                            xmlelement(
                                NAME "TASK_ATTRIBUTE_S"
                                ,xmlforest(
                                    ta.attr_id
                                    ,ta.attrname
                                    ,ta.sqlvalues))
                            ORDER BY ta.attrname)
                        FROM mxiv_taskattributes ta
                        WHERE ta.taskid=t.taskid))
                ,xmlelement(
                    NAME "TASK_ACCESS_T"
                    ,(SELECT
                        xmlagg(
                            xmlelement(
                                NAME "TASK_ACCESS_S"
                                ,xmlforest(
                                    tx.sqlscript
                                    ,tx.targetsqlscript))
                        ORDER BY
                            tx.sqlscript
                            ,tx.targetsqlscript)
                        FROM mxpv_taskaccess tx
                        WHERE tx.taskid=t.taskid))))
    FROM mxpv_alltaskinfo t     
)     
,b64_enc_prefix_cte(node_id, node_type, node_name, b64_enc_prefix, is_xml) AS (
SELECT
    scriptid
    ,'S' -- Global script
    ,cast(scriptname as varchar2(2000)) --TODO: consistent length
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
        idmacs_where_used.read_tab_with_long_col_ptf(
            'MC_JOBS'
            ,'JOBID'
            ,'NAME'
            ,'JOBDEFINITION'
        )
    
    )
)
,b64_enc_cte(node_id, node_type, node_name, b64_enc,is_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    -- SUBSTR returns datatype of arg1 (CLOB in this case)
    ,SUBSTR(b64_enc_prefix
             -- LENGTH accepts CHAR, VARCHAR2, NCHAR, NVARCHAR2,
	     -- CLOB, or NCLOB
            ,LENGTH('{B64}') + 1
            ,LENGTH(b64_enc_prefix) - LENGTH('{B64}')
    )
    ,is_xml
    FROM b64_enc_prefix_cte
)
,b64_dec_cte(node_id,node_type,node_name,b64_dec,is_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    ,idmacs_where_used.base64_decode(b64_enc)
    ,is_xml
    FROM b64_enc_cte
)
,b64_datasource_cte(node_id,node_type,node_name,native_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    ,CASE is_xml
            WHEN 1 THEN XMLPARSE(DOCUMENT b64_dec)
            --TODO: this generates the CDATA section verbatim,
            --which differs from the behavior on DB/2
            ELSE sys_xmlgen(xmlcdata(b64_dec))
        END
        FROM b64_dec_cte
)
,any_datasource_cte(node_id,node_type,node_name,native_xml) AS (
SELECT
     *
     from b64_datasource_cte
UNION ALL SELECT
     *
     FROM text_datasource_cte
)
,all_text_cte(node_id,node_type,node_name,match_location,match_doucment) as (
SELECT
     node_id
     ,node_type
     ,NODE_NAME
     ,DBMS_XMLGEN.CONVERT(
        EXTRACT(MATCH_LOCATION,'.').getClobVal()
        , 1 --DBMS_XMLGEN.ENTITY_DECODE
     ) as match_location
     ,native_xml
     FROM any_datasource_cte
     ,xmltable('
         for $t in ( $native_xml//attribute::*
                    ,$native_xml/descendant-or-self::text())
         return $t
     ' 
     PASSING NATIVE_XML AS "native_xml"
     COLUMNS "MATCH_LOCATION"  XMLType PATH '.'
     )
)
SELECT * 
    FROM ALL_TEXT_CTE
    WHERE IDMACS_WHERE_USED.CLOB_CONTAINS(
        MATCH_LOCATION
        , 'YOUR_SEARCH_TERM_HERE'
    ) > 0
    ORDER BY NODE_TYPE, NODE_ID
;