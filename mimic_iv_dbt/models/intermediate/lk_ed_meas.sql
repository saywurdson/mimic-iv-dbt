-- lk_ed_meas: MIMIC-IV-ED numeric vitals (ed.triage + ed.vitalsign) -> Measurement.
-- Unpivots the numeric vital columns into one row per (stay, vital, value) where the value is
-- not null, then joins the ed_vital_to_concept seed (target_domain='Measurement') for the
-- measurement_concept_id + unit_concept_id per ed_column. Mirrors lk_meas_labevents_mapped's
-- value/unit shape, but the standard concept comes straight from the seed (no vocab 'Maps to'
-- join needed). triage has no charttime -> measurement_datetime falls back to the ED visit start;
-- vitalsign uses its own charttime. measurement_type_concept_id=32817 (EHR), carried by the final.
WITH unpivoted AS (
    -- triage: one undated reading per ED stay; value_source_value keeps the raw text (pain is free text)
    SELECT
        src.subject_id          AS subject_id,
        src.stay_id             AS stay_id,
        'temperature'           AS ed_column, CAST(src.temperature AS VARCHAR) AS value_source_value, CAST(NULL AS TIMESTAMP) AS charttime FROM {{ ref('src_ed_triage') }} src WHERE src.temperature IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'heartrate', CAST(src.heartrate AS VARCHAR), CAST(NULL AS TIMESTAMP) FROM {{ ref('src_ed_triage') }} src WHERE src.heartrate IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'resprate',  CAST(src.resprate AS VARCHAR),  CAST(NULL AS TIMESTAMP) FROM {{ ref('src_ed_triage') }} src WHERE src.resprate IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'o2sat',     CAST(src.o2sat AS VARCHAR),     CAST(NULL AS TIMESTAMP) FROM {{ ref('src_ed_triage') }} src WHERE src.o2sat IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'sbp',       CAST(src.sbp AS VARCHAR),       CAST(NULL AS TIMESTAMP) FROM {{ ref('src_ed_triage') }} src WHERE src.sbp IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'dbp',       CAST(src.dbp AS VARCHAR),       CAST(NULL AS TIMESTAMP) FROM {{ ref('src_ed_triage') }} src WHERE src.dbp IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'pain',      src.pain,                       CAST(NULL AS TIMESTAMP) FROM {{ ref('src_ed_triage') }} src WHERE src.pain IS NOT NULL
    -- vitalsign: one reading per charttime
    UNION ALL SELECT src.subject_id, src.stay_id, 'temperature', CAST(src.temperature AS VARCHAR), src.charttime FROM {{ ref('src_ed_vitalsign') }} src WHERE src.temperature IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'heartrate',   CAST(src.heartrate AS VARCHAR),   src.charttime FROM {{ ref('src_ed_vitalsign') }} src WHERE src.heartrate IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'resprate',    CAST(src.resprate AS VARCHAR),    src.charttime FROM {{ ref('src_ed_vitalsign') }} src WHERE src.resprate IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'o2sat',       CAST(src.o2sat AS VARCHAR),       src.charttime FROM {{ ref('src_ed_vitalsign') }} src WHERE src.o2sat IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'sbp',         CAST(src.sbp AS VARCHAR),         src.charttime FROM {{ ref('src_ed_vitalsign') }} src WHERE src.sbp IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'dbp',         CAST(src.dbp AS VARCHAR),         src.charttime FROM {{ ref('src_ed_vitalsign') }} src WHERE src.dbp IS NOT NULL
    UNION ALL SELECT src.subject_id, src.stay_id, 'pain',        src.pain,                         src.charttime FROM {{ ref('src_ed_vitalsign') }} src WHERE src.pain IS NOT NULL
)
SELECT
    u.subject_id                                    AS subject_id,
    u.stay_id                                       AS stay_id,
    per.person_id                                   AS person_id,
    vc.concept_id                                   AS measurement_concept_id,
    COALESCE(u.charttime, vis.visit_start_datetime) AS measurement_datetime,
    32817                                           AS measurement_type_concept_id,
    TRY_CAST(u.value_source_value AS DOUBLE)        AS value_as_number,
    vc.unit_concept_id                              AS unit_concept_id,
    vis.visit_occurrence_id                         AS visit_occurrence_id,
    u.ed_column                                     AS measurement_source_value,
    u.value_source_value                            AS value_source_value,
    'meas.ed_vital'                                 AS unit_id
FROM unpivoted u
INNER JOIN {{ ref('ed_vital_to_concept') }} vc
    ON vc.ed_column = u.ed_column AND vc.target_domain = 'Measurement'
INNER JOIN {{ ref('lk_ed_visit') }} vis
    ON vis.stay_id = u.stay_id
INNER JOIN {{ ref('cdm_person_all') }} per
    ON per.person_source_value = CAST(u.subject_id AS VARCHAR)
