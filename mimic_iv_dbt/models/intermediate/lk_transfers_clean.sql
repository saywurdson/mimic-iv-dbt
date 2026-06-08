-- transfers (non-discharge) -> visit_detail source; missing hadm_id backfilled by overlap.
SELECT
    src.subject_id                                  AS subject_id,
    COALESCE(src.hadm_id, vis.hadm_id)              AS hadm_id,
    CAST(src.intime AS DATE)                        AS date_id,
    src.transfer_id                                 AS transfer_id,
    src.intime                                      AS start_datetime,
    src.outtime                                     AS end_datetime,
    src.careunit                                    AS current_location,
    'transfers'                                     AS unit_id,
    src.load_table_id
FROM {{ ref('src_transfers') }} src
LEFT JOIN {{ ref('lk_admissions_clean') }} vis
    ON  vis.subject_id = src.subject_id
    AND src.intime BETWEEN vis.start_datetime AND vis.end_datetime
    AND src.hadm_id IS NULL
WHERE src.eventtype != 'discharge'
