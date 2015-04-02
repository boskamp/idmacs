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
--           THIS IS THE VERSION FOR IBM(R) DB2(R).
--
--           The most recent version of this file as well as
--           versions for other databases can be found at GitHub:
--
--           https://github.com/boskamp/idmacs
--   
-- Usage:    1. Paste this source code into the SQL editor of any
--              graphical SQL client that can display CLOB and/or
--              XML data. Microsoft(R) SQL Server Management Studio,
--              Oracle(R) SQL Developer and IBM(R) Data Studio are
--              known to work fine. Others may work as well.
--
--           2. In the SQL editor, replace YOUR_SEARCH_TERM_HERE
--              near the end of the code with the string you want
--              to search for. See also section "Example".
--
--           3. Execute the resulting query as ADMIN user (MXMC_ADMIN).
--
--           4. (Optional) Examine MATCH_LOCATION_* and MATCH_DOCUMENT
--              values of the result set directly in the SQL client.
--
--           5. (Optional) Locate tasks or jobs corresponding to NODE_ID
--              values from your result set using MMC's Find action.
--              Make sure to check "Find Tasks or Jobs only"!
--
-- Example:  To search for all occurences of the string MX_DISABLED,
--           the code near the end should look like:
--
--           where contains(upper-case($t),upper-case("MX_DISABLED"))
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
--           2. NODE_ID             : int
--           3. NODE_NAME           : varchar(max)
--           4. MATCH_LOCATION_XML  : xml                 (MSSQL only)
--           5. MATCH_LOCATION_TEXT : varchar(max)
--           6. MATCH_DOCUMENT      : xml
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
--           MATCH_LOCATION_XML is similar to MATCH_LOCATION_TEXT,
--           just represented as XML to enable convenient hyperlink
--           navigation in Microsoft(R) SQL Server Management Studio.
--           This column exists in the MSSQL version only.
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
--           which differ only in their MATCH_LOCATION_* values.
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
     ,'A'-- Attribute
     ,a.attrname
     ,xmldocument(
        xmlelement(
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
                        WHERE v.attr_id=a.attr_id)))))                    
     FROM mxiv_allattributes a

UNION ALL SELECT
    t.taskid
    ,'T'-- Task
    ,t.taskname
    ,xmldocument(
        xmlelement(
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
                                       PASSING CAST('<?xml version="1.0" encoding="UTF-8"?><ROOT><![CDATA[' 
                                                    AS BLOB(2g)) 
                                       AS "i") 
                              AS BLOB(2g))
                      || b64_dec 
                      || XMLCAST(XMLQUERY('xs:hexBinary($i)' 
                                          PASSING CAST(']]></ROOT>' AS BLOB(2g)) 
                                          AS "i") 
                                 AS BLOB(2g))
                      PRESERVE WHITESPACE)
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
SELECT
     node_id
     ,node_type
     ,node_name
     ,match_location_text
     ,match_document
     FROM any_datasource_cte
     ,xmltable('
         for $t in ( $native_xml//attribute::*
                    ,$native_xml/descendant-or-self::text())
         where contains( upper-case($t)
                        ,upper-case("YOUR_SEARCH_TERM_HERE")) 
         return $t
         
         (: This could be used on DB2 to conditionally return  :)
         (: parent of attribute nodes, but self of text nodes. :)
         (: XQuery "instance of"" operator seems unsupported.  :)
         (:                                                    :)
         (: return if($t/self::attribute()) then $t/.. else $t :) 
     ' 
     PASSING BY REF native_xml AS "native_xml"
     COLUMNS "MATCH_LOCATION_TEXT"  CLOB(2G) PATH '.'
             ,"MATCH_DOCUMENT" XML PATH '/'
     )
    ORDER BY node_type, node_id
;

