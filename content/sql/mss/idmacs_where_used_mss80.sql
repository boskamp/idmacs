-- Copyright (c) 2014, 2016 Lambert Boskamp
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
--           THIS IS THE VERSION FOR IDM 8.0 ON MICROSOFT(R) SQL SERVER.
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
--           5. (Optional) TODO: Describe how to locate tasks or jobs 
--              corresponding to NODE_ID values from result set in
--              SAP(R) IDM Developer Studio.
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
--                       | 'S' -- Script (package script)
--                       | 'G' -- Script (global script)
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
with text_datasource_cte(node_id,node_type,node_name,native_xml) as (
select
     a.attr_id
     ,'A'-- Attribute
     ,a.attrname
     ,(select
         a.attr_id         as "ATTR_ID"
         ,a.is_id          as "IS_ID"
         ,i.idstorename    as "IDSTORENAME"
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
     inner join mxi_idstores i with (nolock)
     on a.is_id=i.is_id

union all select
     t.taskid
     ,'T'-- Task
     ,t.taskname
     ,(select
         t.taskid    as "TASKID"
         ,t.taskname as "TASKNAME"
         ,t.boolsql  as "BOOLSQL"
         ,t.onsubmit as "ONSUBMIT"
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
              ,a.attrname         as "ATTRNAME"
              ,ta.attrname        as "TARGETATTRNAME"
              ,e.mcmskeyvalue     as "MSKEYVALUE"
              ,te.mcmskeyvalue    as "TARGETMSKEYVALUE"
              from mxpv_taskaccess tx with (nolock)
              left outer join mxi_attributes a with (nolock)
              on tx.attr_id=a.attr_id
              left outer join mxi_attributes ta with (nolock)
              on tx.targetattr_id=ta.attr_id
              left outer join idmv_entry_simple e with (nolock)
              on tx.mskey=e.mcmskey
              left outer join idmv_entry_simple te with (nolock)
              on tx.targetmskey=te.mcmskey
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
     ,'G'--Global Script
     ,scriptname
     ,scriptdefinition
     ,0
  from mc_global_scripts with (nolock)
union all select
      b.mcscriptid
      ,'S'--Package Script
      ,a.mcqualifiedname + ':jscript.' + b.mcscriptname
      ,b.mcscriptdefinition
      ,0
   from mc_package a with (nolock)
   inner join mc_package_scripts b with (nolock)
   on a.mcpackageid=b.mcpackageid

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
     -- is required, otherwise B64_ENC_PREFIX will be truncated
     -- to 8000 bytes.
     ,substring(
         cast(b64_enc_prefix as varchar(max))
         ,len('{B64}') + 1
         ,datalength(b64_enc_prefix) - len('{B64}')
     )
     ,is_xml
     from b64_enc_prefix_cte
)
,b64_dec_cte(node_id,node_type,node_name,b64_dec,is_xml) as (
select
     node_id
     ,node_type
     ,node_name
     ,cast(N'' AS XML).value(
         'xs:base64Binary(sql:column("B64_ENC"))'
         ,'VARBINARY(MAX)'
     )
     ,is_xml
     from b64_enc_cte
)
,xml_utf8_hex_cte(name,value) as (
select
    'PROLOG'
    -- This is the hexadecimal byte values
    -- of the following UTF-8 encoded text:
    -- <?xml version="1.0" encoding="utf-8"?><ROOT><![CDATA[
    ,'3C3F786D6C2076657273696F6E3D22312E302220
      656E636F64696E673D227574662D38223F3E3C52
      4F4F543E3C215B43444154415B'

union all select
    'EPILOG'
    -- This is the hexadecimal byte values 
    -- of the following UTF-8 encoded text:
    -- ]]></ROOT>
    ,'5D5D3E3C2F524F4F543E'
)
,xml_utf8_bin_cte(name,value) as (
select
    name
    ,cast(N'' as XML).value(
        'xs:hexBinary(sql:column("VALUE"))'
        , 'VARBINARY(MAX)'
     )
    from xml_utf8_hex_cte
)
,b64_datasource_cte(node_id,node_type,node_name,native_xml) as (
select
     node_id
     ,node_type
     ,node_name
     ,case is_xml
         --If B64_DEC is not well-formed XML by itself,
         --decorate it with UTF-8 encoded XML prolog and epilog.
         --Casting UTF-8 binary to VARCHAR or NVARCHAR won't work.
         --See https://support.microsoft.com/en-us/kb/232580
         when 0 then cast(
             (select
                 value
                 from xml_utf8_bin_cte
                 where name='PROLOG')

             + b64_dec

             + (select
                 value
                 from xml_utf8_bin_cte
                 where name='EPILOG')

         as xml)
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
