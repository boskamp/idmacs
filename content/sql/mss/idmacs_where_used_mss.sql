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
with text_datasource_cte(node_id,node_type,node_name,native_xml) as ( select
     attr_id
     ,'A'-- Attribute
     ,attrname
     ,(select sqlvalues for xml path)
     from mxiv_schema with (nolock)
 
union all select
     taskid
     ,'T'-- Task
     ,taskname
     ,(select boolsql for xml path)
     from mxpv_alltaskinfo with (nolock)
     where boolsql is not null
 
union all select
     -- t.taskid << 32 | ta.attr_id
     ( t.taskid * power(cast(2 as bigint),32) ) | ta.attr_id
     ,'TA'--Task Attribute
     ,t.taskname+':'+ta.attrname
     ,(select sqlvalues for xml path)
     from mxiv_taskattributes ta
     with (nolock)
     inner join mxpv_alltaskinfo t with (nolock)
     on ta.taskid=t.taskid
     where sqlvalues is not null
 
union all select
   t.taskid
   ,'TX'--Task Access Control
   ,t.taskname
   ,(select sqlscript,targetsqlscript from mxpv_taskaccess where taskid=t.taskid for xml path('MXPV_TASKACCESS'))
   from mxpv_alltaskinfo t with (nolock)
   where exists (
       select 1 
           from mxpv_taskaccess a with (nolock)
           where a.taskid=t.taskid
           and a.sqlscript is not null
           or a.targetsqlscript is not null )
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
         return if ($t instance of attribute()) then $t/..
         else $t
     ') as t(xml_sequence)
     order by node_id,node_type
;