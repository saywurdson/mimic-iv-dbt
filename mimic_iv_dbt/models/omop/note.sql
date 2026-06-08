-- cdm_note: MIMIC-IV-Note discharge summaries + radiology reports.
WITH src_notes AS (
    SELECT note_id, subject_id, hadm_id, note_type, charttime, text FROM {{ ref('src_discharge') }}
    UNION ALL
    SELECT note_id, subject_id, hadm_id, note_type, charttime, text FROM {{ ref('src_radiology') }}
)
SELECT
    {{ mimic_sk('note', 'n.note_id') }} AS note_id,
    per.person_id,
    CAST(n.charttime AS DATE) AS note_date,
    n.charttime AS note_datetime,
    CASE n.note_type
        WHEN 'DS' THEN 44814637   -- Discharge summary note
        WHEN 'RR' THEN 44814641   -- Radiology report
        WHEN 'AR' THEN 44814641   -- Radiology addendum -> radiology report
        ELSE 0
    END AS note_type_concept_id,
    CAST(0 AS BIGINT) AS note_class_concept_id,
    n.note_type AS note_title,
    n.text AS note_text,
    CAST(0 AS BIGINT) AS encoding_concept_id,
    CAST(4180186 AS BIGINT) AS language_concept_id,   -- English language
    CAST(NULL AS BIGINT) AS provider_id,
    vis.visit_occurrence_id,
    CAST(NULL AS BIGINT) AS visit_detail_id,
    n.note_id AS note_source_value,
    CAST(NULL AS BIGINT) AS note_event_id,
    CAST(NULL AS BIGINT) AS note_event_field_concept_id
FROM src_notes n
-- INNER JOIN final person: excludes notes for event-less (dropped) patients.
JOIN {{ ref('person') }} per
    ON per.person_source_value = CAST(n.subject_id AS VARCHAR)
LEFT JOIN {{ ref('visit_occurrence') }} vis
    ON vis.visit_source_value = CAST(n.subject_id AS VARCHAR) || '|' || CAST(n.hadm_id AS VARCHAR)
