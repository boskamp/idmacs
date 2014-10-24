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
          -- result set will always contain one task only,
          -- so let task be the root element, not tasks
          --,root('tasks')
          ,type)
     from mxpv_alltaskinfo t with (nolock)
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
             'xs:base64Binary(sql:column("b64_enc"))'
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
         when 0 then (select b64_dec for xml path)
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
     node_id
     ,node_type
     ,node_name
     ,xml_sequence.query('.') as match_location
     ,xml_sequence.query('/') as match_document
     from any_datasource_cte
     cross apply
     native_xml.nodes('
         for $t in (//attribute::*, /descendant-or-self::text())
         where contains(upper-case($t), upper-case("YOUR_SEARCH_TERM_HERE"))

         (: If you are on MSSQL2005, you are limited to case-insensitive :)
         (: search as this 2005 does not support fn:upper-case() yet.    :)
         (: where contains($t, "YOUR_SEARCH_TERM_HERE")                  :)

         return if ($t instance of attribute()) then $t/..
         else $t
     ') as t(xml_sequence)
     order by node_type,node_id
;