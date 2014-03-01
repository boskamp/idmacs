-- Copyright 2014 Lambert Boskamp
--
-- Author: Lambert Boskamp <lambert@boskamp-consulting.com.nospam>
--
-- This file is part of IDMacs.
--
-- IDMacs is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- IDMacs is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with IDMacs.  If not, see <http://www.gnu.org/licenses/>.
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
