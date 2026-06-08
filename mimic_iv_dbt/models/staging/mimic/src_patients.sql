-- snapshot: hosp.patients (prefer hosp over core)
SELECT
    subject_id::BIGINT      AS subject_id,
    anchor_year::INTEGER    AS anchor_year,
    anchor_age::INTEGER     AS anchor_age,
    anchor_year_group       AS anchor_year_group,
    gender                  AS gender,
    dod::TIMESTAMP          AS dod,
    'patients'              AS load_table_id
FROM {{ read_mimic4('patients', 'hosp') }}
