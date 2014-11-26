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
--           Q U I C K   S T A R T  (>>> Read at least from here...)
-- *******************************************************************
-- Synopsis: Query to find occurences of a given string inside
--           an SAP(R) Identity Management (IDM) designtime model.
--   
-- Usage:    Connect to your database as admin (MXMC_ADMIN) or oper
--           user (MXMC_OPER) to execute this query. Admin user will
--           not find any matches in stored procedures, though. 
--           Only oper user will find matches anywhere.
--
--           Other standard SAP(R) IDM database users do not have
--           sufficient permissions to execute this query, by default.
--           
--           Before executing the query, replace the example string 
--           YOUR_SEARCH_TERM_HERE near the very end of this query's
--           source code with the actual string you would like
--           to search for. 
--
--           If you would like to search for occurences of the string
--           MX_DISABLED, for example, the code should look like:
--
--           where contains(upper-case($t),upper-case("MX_DISABLED"))
--
-- *******************************************************************
--           Q U I C K   S T A R T    (<<< ...to here. Thank you!)
-- *******************************************************************
-- Result:   The result set will list any locations that contain your
--           search string. It has the following row structure:
--
--           1. NODE_TYPE           : char(1)
--           2. NODE_ID             : int
--           3. NODE_NAME           : varchar(max)
--           4. MATCH_LOCATION_XML  : xml
--           5. MATCH_LOCATION_TEXT : varchar(max)
--           6. MATCH_DOCUMENT      : xml
--
--           Multiple matching locations within the same SAP(R) IDM
--           designtime object will result in separate rows differing
--           only in their MATCH_LOCATION_* columns but otherwise
--           identical content.
--
--           The NODE_TYPE column specifies the type of SAP(R) IDM
--           designtime object the match has been found in:
--
--           NODE_TYPE = [ 'A' -- Identity Store Attribute
--                       | 'T' -- Task
--                       | 'S' -- Global Script
--                       | 'J' -- Job
--                       | 'P' -- Stored Procedure
--                       ]
--
--           Columns NODE_ID and NODE_NAME provide ID and name of the
--           SAP(R) designtime object. 
--           
--           Their meaning depends on NODE_TYPE. If NODE_TYPE is 'A', 
--           for instance, then NODE_ID is the ID of an Identity Store 
--           attribute like in MXI_ATTRIBUTES.ATTR_ID.
--
--           NODE_ID   = [ attribute_id
--                       | task_id
--                       | global_script_id
--                       | job_id
--                       | stored_procedure_id
--                       ]
--
--           NODE_NAME = [ attribute_name
--                       | task_name
--                       | global_script_name
--                       | job_name
--                       | stored_procedure_name
--                       ]
--
--           Column MATCH_LOCATION_XML contains one continuous
--           piece of text that contains your search string at least once.
--
--           Its value may, for instance, be the complete source code 
--           of a global script, or the complete content of the 
--           "SQL statement" input field on the "Source" tab of a 
--           single pass in an SAP(R) IDM job.
--  
--           In contrast to MATCH_LOCATION_TEXT, this column represents
--           the matching text wrapped into an artifical XML processing 
--           instruction, looking  like <?X ... ?> . For this reason,
--           the column value will contain an extra four characters at 
--           the beginning and an additional extra three at the end 
--           which do not reflect real content from the database.
-- 
--           This specific XML representation is chosen for usability in 
--           Microsoft (R) SQL Server Management Studio (SSMS) only.
--
--           You can click on the cell value's hyperlink in the result set 
--           to display the complete matching text in a new editor window.
--           Line breaks from the original text found in the database will
--           be preserved and displayed as expected.
--
--           Column MATCH_LOCATION_TEXT is exactly the same content as
--           MATCH_LOCATION_XML, but as plain text exactly as found in
--           the database. The drawback of this representation is that
--           line breaks are lost, and it's less convenient to display 
--           the complete column value in SSMS.
--
--           Column MATCH_DOCUMENT is the complete SAP(R) IDM designtime 
--           object that contains the content of MACH_LOCATION_*.
--
--           In the case of SAP(R) IDM jobs (NODE_TYPE='J'), this is the 
--           complete job definition as stored in MC_JOBS.JOB_DEFINITION, 
--           just BASE64 decoded. In this case, the structure of the XML
--           is defined by SAP(R).
--
--           For all other types of SAP(R) IDM designtime objects,
--           it is an artifical XML representation generated on the
--           fly from the corresponding relational tables, e.g. 
--           from table MXI_ATTRIBUTES and others for Identity Store 
--           attributes. 
--
--           Note that in the latter case, the XML representation 
--           typically does not contain all fields of the underlying 
--           table(s). The choice of fields is more or less arbitrary.
--           The XML typically contains only fields I personally ever
--           had a need to search in in practice. Your requirements 
--           may be different. To include more fields, you could extend
--           field lists SELECTed by the Common Table Expressions (CTE) 
--           at the top of this query.
--
-- Bugs:     Specifically for global scripts, this query will report 
--           ONLY ONE matching location, even when the script contains 
--           multiple matches.
--
--           If you're interested in finding ALL occurences of your 
--           search string, it's often required to open the content of 
--           MATCH_DOCUMENT in a separate window via hyperlink, and 
--           then do an SSMS "Quick Find..." (Ctrl+F) there to step 
--           through all occurences of your search string within a
--           a single SAP(R) IDM designtime object.
-- *******************************************************************
with text_datasource_cte(node_id,node_type,node_name,native_xml) as (
select
     a.attr_id
     ,'A'-- Attribute
     ,a.attrname
     ,(select
         a.attr_id         as "ATTR_ID"
         ,a.attrname       as "ATTR_NAME"
         ,a.info           as "INFO"
         ,a.deltask        as "DELTASK"
         ,a.modtask        as "MODTASK"
         ,a.instask        as "INSTASK"
         ,a.display_name   as "DISPLAY_NAME"
         ,a.tooltip        as "TOOLTIP"
         ,a.regexvalidate  as "REGEXVALIDATE"
         ,a.sqlvalues      as "SQLVALUES"
         ,a.sqlaccesstask  as "SQLACCESSTASK"
         ,a.sqlvaluestable as "SQLVALUESTABLE"
         ,a.sqlvaluesid    as "SQLVALUESID"
         ,(select
               v.attr_value as "ATTR_VALUE"
               from mxi_attrvaluechoice v with (nolock)
               where v.attr_id=a.attr_id
               order by v.attr_value
               for xml path('ATTRIBUTE_VALUE_CHOICE_S')
               ,root('ATTRIBUTE_VALUE_CHOICE_T')
               ,type)
         for xml path('ATTRIBUTE_S')
         ,type)
     from mxiv_allattributes a with (nolock)

union all select
     t.taskid
     ,'T'-- Task
     ,t.taskname
     ,(select
         t.taskid    as "TASKID"
         ,t.taskname as "TASKNAME"
         ,t.boolsql  as "BOOLSQL"
         ,(select
             ta.attr_id    as "ATTR_ID"
             ,ta.attrname  as "ATTRNAME"
             ,ta.sqlvalues as "SQLVALUES"
             from mxiv_taskattributes ta with (nolock)
             where ta.taskid=t.taskid
             order by ta.attr_id
             for xml path('TASK_ATTRIBUTE_S')
             ,root('TASK_ATTRIBUTE_T')
             ,type)
          ,(select
              tx.sqlscript        as "SQLSCRIPT"
              ,tx.targetsqlscript as "TARGETSQLSCRIPT"
              from mxpv_taskaccess tx with (nolock)
              where tx.taskid=t.taskid
              for xml path('TASK_ACCESS_S')
              ,root('TASK_ACCESS_T')
              ,type)
          order by t.taskid
          for xml path('TASK_S')
          -- Result set will always contain one task only,
          -- so let task be the root element, not tasks
          --,root('tasks')
          ,type)
     from mxpv_alltaskinfo t with (nolock)

--Searching in stored procedure source code works only with MXMC_OPER.
--object_definition() will always return NULL for other users, so the
--query still works, but matches in stored procedure source code will
--not be found.
union all select
   object_id(routine_name)
   ,'P'
   ,routine_name
   ,(select
       routine_name            as "PROCEDURE_NAME"
       ,object_definition(
            object_id(
                routine_name)) as "PROCEDURE_DEFINITION"
       for xml path('PROCEDURE_S')
       ,type)
   from information_schema.routines with (nolock)
)
,b64_enc_prefix_cte(node_id, node_type, node_name, b64_enc_prefix,
is_xml) as (
select
     scriptid
     ,'S'--Global Script
     ,scriptname
     ,scriptdefinition
     ,0
  from mc_global_scripts with (nolock)
union all select
     jobid
     ,'J'--Job
     ,name
     ,jobdefinition
     ,1
     from mc_jobs with (nolock)
     where jobdefinition is not null
)
,b64_enc_cte(node_id, node_type, node_name, b64_enc,is_xml)as (
select
     node_id
     ,node_type
     ,node_name
     -- Casting to varchar(max) before applying substring
     -- is required, otherwise log_data will be truncated
     -- to 8000 bytes.
     ,substring(
         cast(b64_enc_prefix as varchar(max))
         ,len('{B64}') + 1
         ,DATALENGTH(b64_enc_prefix) - len('{B64}')
     )
     ,is_xml
     from b64_enc_prefix_cte
)
,b64_dec_cte(node_id,node_type,node_name,b64_dec,is_xml) as (
SELECT
     node_id
     ,node_type
     ,node_name
     ,cast(
         CAST(N'' AS XML).value(
             'xs:base64Binary(sql:column("B64_ENC"))'
             ,'VARBINARY(MAX)'
         )
     as varchar(max))
     ,is_xml
     FROM b64_enc_cte
)
,b64_datasource_cte(node_id,node_type,node_name,native_xml) as (
select
     node_id
     ,node_type
     ,node_name
     ,case is_xml
         --If B64_DEC is not well-formed XML by itself,
         --create an XML fragment with a single ROOT node.
         --Include the content of B64_DEC column as a text
         --node underneath ROOT.
         when 0 then (select
             b64_dec as [text()] 
             for xml path('')
             ,root('ROOT')
             ,type)
         --If B64_DEC already is well-formed XML,
         --just cast it to T-SQL's native XML data type.
         else cast(b64_dec as xml)
     end
     from b64_dec_cte a
)
,any_datasource_cte(node_id,node_type,node_name,native_xml) as (
select
     *
     from b64_datasource_cte
union all select
     *
     from text_datasource_cte
)
select
     node_type
     ,node_id
     ,node_name

     --Column MATCH_LOCATION_XML is specific to the MSSQL version
     --of this query. It's only required to provide hyperlink 
     --navigation and to preserve line breaks in SSMS.
     ,(select
         xml_sequence.value('.', 'VARCHAR(MAX)')
         as [processing-instruction(X)]
         for xml path('')
         ,type)
     as match_location_xml

     --Must use value() method of XML data type to avoid entitization 
     --of XML characters, e.g. encoding of "<" to "&lt;".
     ,xml_sequence.value('.', 'VARCHAR(MAX)') as match_location_text

     ,xml_sequence.query('/') as match_document
     from any_datasource_cte
     cross apply
     native_xml.nodes('
         (: Release 2005 of MSSQL does not have fn:upper-case() yet.    :)
         (: As a workaround, you can omit the upper-case() calls in the :)
         (: XQuery WHERE clause, resulting in case-sensitive search.    :)

         for $t in (//attribute::*, /descendant-or-self::text())
         where contains(upper-case($t),upper-case("YOUR_SEARCH_TERM_HERE"))
         return $t

     ') as t(xml_sequence)
     order by node_type,node_id
;