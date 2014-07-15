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

WITH strip_prefix_cte(job_id,job_name,job_base64)AS (
SELECT
    JobId
    ,Name
    -- Casting to VARCHAR(MAX) before applying SUBSTRING()
    -- is required, otherwise the result would be truncated 
    -- to 8000 bytes.
    ,SUBSTRING(
        CAST(JobDefinition AS VARCHAR(MAX))
        ,6
        ,DATALENGTH(JobDefinition)
    )
    FROM mc_jobs WITH(NOLOCK)
)
,base64_decode_cte(job_id,job_name,job_xml) AS (
    SELECT
        job_id
        ,job_name
        ,CAST(
            CAST(N'' AS XML).value(
                'xs:base64Binary(sql:column("job_base64"))'
                ,'VARBINARY(MAX)'
            ) AS xml
        )
        FROM strip_prefix_cte
)
SELECT 
    d.job_id
    ,d.job_name
    ,d.job_xml 
    -- Columns returned from nodes() method cannot be used directly,
    -- so the indirection via query(.), returning self, is required.
    ,xq_result.match_element.query('.') as match_element

    FROM base64_decode_cte d
    CROSS APPLY
    d.job_xml.nodes('
        for $t in (//attribute::*, /descendant-or-self::text())
               
        (: Replace MX_DISABLED with any string to search for :)
        where contains($t, "MX_DISABLED")

        return $t/..
    ') AS xq_result(match_element)

    ORDER BY d.job_id
;
