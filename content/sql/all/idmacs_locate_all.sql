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
-- ************* N O T E    F O R   O R A / D B 2  *******************
-- *******************************************************************
-- This query is designed for MS SQL Server. To execute on Oracle
-- or DB2, replace all occurrences of character plus (+) throughout
-- this whole script with two consecutive pipe characters (||).
-- *******************************************************************

-- Synopsis: Query to find the locations of tasks or jobs in the
--           SAP NetWeaver Identity Management (R) IC Designtime. 
--           Locations are represented by column NODE_PATH of this 
--           query's result set. NODE_PATH is a character string 
--           loosely resembling a file system path.
--
--           If you have any jobs are tasks that are linked from 
--           multiple locations, one row is returned per location,
--           each with a different NODE_PATH.
--
-- Usage:    Running this query AS IS will return the locations of
--           all tasks, jobs and groups in the current database. 
--           The runtime user (MXMC_RT) normally has sufficient
--           permissions to execute it.
--          
--           You'll typically uncomment the "NODE_TYPE=...",
--           "NODE_ID=..." and/or "NODE_NAME=..." predicates in the 
--           WHERE clause of the outer query at the very end
--           of this file. See section "Examples" below.
--
--           NODE_TYPE = [ 'J' -- Job
--                       | 'T' -- Task
--                       | 'G' -- Group (aka folder)
--                       | 'I' -- Identity Store
--                       ]
--
--           NODE_ID = [job_id|task_id|group_id|ids_id]
--
--           NODE_NAME = [job_name|task_name|group_name|ids_name]
--
-- Examples: Locate provisioning task 601/Provisioning:
--           WHERE NODE_TYPE='T' 
--           AND NODE_ID=601
--
--           Locate all jobs whose name is "ModifyABAPIdentity":
--           WHERE NODE_TYPE='J' 
--           AND NODE_NAME='ModifyABAPIdentity'
--
-- Notes:    This query aims at being easily portable between
--           MSS/ORA/DB2. For this reason:
--
--           * Only data types supported by all platforms are used
--           * No query hints like WITH (NOLOCK) are used
--           * VARCHAR columns use a maximum length that will
--             work on all three platforms (4000 bytes)
--             ORA:  4.000 bytes
--             MSS:  8.000 bytes, or 2^31-1 bytes with VARCHAR(max)
--             DB2: 32.672 bytes
--
-- TODO:     Programmatic check for infinite recursion
--           to avoid warning on DB2 (SQLCODE=347, SQLSTATE=01605)
-- *******************************************************************
WITH nodes
-- ORA requires a list of column aliases, SQL Server doesn't
     (node_id, parent_node_id, parent_node_type, node_name, node_type)
     AS (

-- Identity Stores
     SELECT is_id         AS node_id
           ,NULL          AS parent_node_id
           ,NULL          AS parent_node_type
           ,idstorename   AS node_name
           ,'I'           AS node_type
     FROM mxi_idstores

-- Tasks Contained in a Folder
     UNION ALL
     SELECT t.taskid      AS node_id
            ,t.taskgroup  AS parent_node_id
            ,'G'          AS parent_node_type
            ,t.taskname   AS node_name
            ,'T'          AS node_type
     FROM mc_group g
     INNER JOIN mxp_tasks t
     ON t.taskgroup=g.group_id

-- Provisioning Folders Below Identity Stores (Root Folders)
     UNION ALL
     SELECT group_id      AS node_id
            ,idstore      AS parent_node_id
            ,'I'          AS parent_node_type
            ,group_name   AS node_name
            ,'G'          AS node_type
     FROM mc_group
     WHERE provision_group=1
     AND parent_group IS NULL

-- Provisioning Folders Below Other Folders (Child Folders)
     UNION ALL
     SELECT group_id      AS node_id
            ,parent_group AS parent_node_id
            ,'G'          AS parent_node_type
            ,group_name   AS node_name
            ,'G'          AS node_type
     FROM mc_group
     WHERE provision_group=1
     AND parent_group IS NOT NULL

-- Job Folders
     UNION ALL
     SELECT group_id      AS node_id
            ,parent_group AS parent_node_id
            ,'G'          AS parent_node_type
            ,group_name   AS node_name
            ,'G'          AS node_type
     FROM mc_group
     WHERE provision_group=0

  -- Tasks Contained in a Task Group
     UNION ALL
     SELECT
     l.tasklnk            AS node_id
     ,l.taskref           AS parent_node_id
     ,'T'                 AS parent_node_type
     ,CASE p.actiontype
         WHEN -4 --Switch Task
         THEN CAST('[CASE '
             + -- ORA/DB2: ||
             l.childgroup
             + -- ORA/DB2: ||
             '] - '
             + -- ORA/DB2: ||
             c.taskname AS VARCHAR(4000))

         WHEN -3 --Conditional Task
         THEN
           CASE l.childgroup
               WHEN '1'
               THEN CAST('[CASE TRUE] - '
                   + -- ORA/DB2: ||
                   c.taskname AS VARCHAR(4000))
               ELSE CAST('[CASE FALSE] - '
                   + -- ORA/DB2: ||
                   c.taskname AS VARCHAR(4000))
           END

         ELSE c.taskname
      END                 AS node_name
     ,'T'                 AS node_type
     FROM mxp_tasklnk l
     INNER JOIN mxp_tasks p
     ON l.taskref=p.taskid
     INNER JOIN mxp_tasks c
     ON l.tasklnk=c.taskid

-- Provisioning Jobs
    UNION ALL
    SELECT j.jobid        AS node_id
    ,t.taskid             AS parent_node_id
    ,'T'                  AS parent_node_type
    ,j.NAME               AS node_name
    ,'J'                  AS node_type
    FROM mc_jobs j
    INNER JOIN mxp_tasks t
    ON j.jobguid=t.jobguid
    WHERE j.provision=1

-- Regular Jobs
    UNION ALL
    SELECT j.jobid        AS node_id
    ,group_id             AS parent_node_id
    ,'G'                  AS parent_node_type
    ,j.NAME               AS node_name
    ,'J'                  AS node_type
    FROM mc_jobs j
    WHERE j.provision=0
)--nodes

,tree
     -- ORA requires list of column aliases in CTE definition, MSS doesn't
     (node_id,node_type,node_name,parent_node_id,parent_node_type,node_path)
     AS (
     SELECT node_id
            ,node_type
            ,node_name
            ,parent_node_id
            ,parent_node_type
            ,CAST('/'
                + -- ORA/DB2: ||
                CAST(node_id AS VARCHAR(4000))
                + -- ORA/DB2: ||
                ':'
                + -- ORA/DB2: ||
                node_name AS VARCHAR(4000)
            ) AS node_path
     FROM nodes
     WHERE parent_node_id IS NULL

     UNION ALL
     SELECT n.node_id
            ,n.node_type
            ,n.node_name
            ,n.parent_node_id
            ,n.parent_node_type
            ,CAST(t.node_path
                + -- ORA/DB2: ||
                '/'
                + -- ORA/DB2: ||
                CAST(n.node_id AS VARCHAR(4000))
                + -- ORA/DB2: ||
                ':'
                + -- ORA/DB2: ||
                n.node_name
                AS VARCHAR(4000)
            ) AS node_path
-- DB2 CTEs require pre-ANSI JOIN syntax (equivalent to INNER JOIN)
     FROM nodes n
     , tree t
     WHERE t.node_id=n.parent_node_id
     AND t.node_type=n.parent_node_type
)

SELECT
     node_id
     ,node_type
     ,node_name
     ,node_path
     FROM tree
     WHERE 1=1
-- Uncomment and adapt any or all of the below lines
     -- AND node_id   = 601
     -- AND node_type = 'T'
     -- AND node_name = 'Provisioning'
     ORDER BY node_path
; 
