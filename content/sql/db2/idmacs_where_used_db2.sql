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
-- * Include same datasources as in MSS version
-- * XQuery for actual search
-- * Documentation
-- *******************************************************************
WITH text_datasource_cte(node_id,node_type,node_name,native_xml) AS (
SELECT
    t.taskid
    ,'T'-- Task
    ,t.taskname
    ,xmldocument(
        xmlelement(
            NAME "TASK"
            ,xmlconcat(
            xmlforest(
                t.taskid
                ,t.taskname
                ,t.boolsql)
                ,xmlelement(
                    NAME "TASKATTRIBUTES"
                    ,(SELECT
                        xmlagg(
                            xmlelement(
                                NAME "TASKATTRIBUTE"
                                ,xmlforest(
                                    ta.attr_id
                                    ,ta.attrname
                                    ,ta.sqlvalues))
                            ORDER BY ta.attrname)
                        FROM mxiv_taskattributes ta
                        WHERE ta.taskid=t.taskid))
                ,xmlelement(
                    NAME "TASKACCESSES"
                    ,(SELECT
                        xmlagg(
                            xmlelement(
                                NAME "TASKACCESS"
                                ,xmlforest(
                                    tx.sqlscript
                                    ,tx.targetsqlscript))
                        ORDER BY
                            tx.sqlscript
                            ,tx.targetsqlscript)
                        FROM mxpv_taskaccess tx
                        WHERE tx.taskid=t.taskid)))))
    FROM mxpv_alltaskinfo t
)
,b64_enc_prefix_cte(node_id, node_type, node_name, b64_enc_prefix, is_xml) AS (
SELECT
    scriptid
    ,'S' -- Global script
    ,scriptname
    ,scriptdefinition
    ,0
    FROM mc_global_scripts
UNION ALL SELECT
    jobid
    ,'J' -- Job
    ,name
    ,jobdefinition
    ,1
    FROM mc_jobs
)
,b64_enc_cte(node_id, node_type, node_name, b64_enc,is_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    ,SUBSTR(b64_enc_prefix
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
    ,XMLCAST(XMLQUERY('xs:base64Binary($b64_enc)' 
                      PASSING b64_enc AS "b64_enc" ) 
             AS BLOB(2g)
    )
    ,is_xml
    FROM b64_enc_cte
)
,b64_datasource_cte(node_id,node_type,node_name,native_xml) AS (
SELECT
    node_id
    ,node_type
    ,node_name
    ,CASE is_xml
        WHEN 1 THEN XMLPARSE(DOCUMENT b64_dec PRESERVE WHITESPACE)
        ELSE XMLPARSE(DOCUMENT 
                      XMLCAST(XMLQUERY('xs:hexBinary($i)' 
                                       PASSING CAST('<?xml version="1.0" encoding="UTF-8"?><root><![CDATA[' 
                                                    AS BLOB(2g)) 
                                       AS "i") 
                              AS BLOB(2g))
                      || b64_dec 
                      || XMLCAST(XMLQUERY('xs:hexBinary($i)' 
                                          PASSING CAST(']]></root>' AS BLOB(2g)) 
                                          AS "i") 
                                 AS BLOB(2g))
                      PRESERVE WHITESPACE)
    END
    FROM b64_dec_cte
)
SELECT * FROM b64_datasource_cte
;
