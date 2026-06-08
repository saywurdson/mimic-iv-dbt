-- services with LEAD end_datetime / LAG prior service; exact-time dups removed.
WITH dup AS (
    SELECT trace_id
    FROM {{ ref('src_services') }}
    GROUP BY trace_id
    HAVING COUNT(*) > 1
)
SELECT
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    src.transfertime                                AS start_datetime,
    LEAD(src.transfertime) OVER (
        PARTITION BY src.subject_id, src.hadm_id ORDER BY src.transfertime
    )                                               AS end_datetime,
    src.curr_service                                AS curr_service,
    src.prev_service                                AS prev_service,
    LAG(src.curr_service) OVER (
        PARTITION BY src.subject_id, src.hadm_id ORDER BY src.transfertime
    )                                               AS lag_service,
    'services'                                      AS unit_id,
    src.load_table_id
FROM {{ ref('src_services') }} src
LEFT JOIN dup ON src.trace_id = dup.trace_id
WHERE dup.trace_id IS NULL
