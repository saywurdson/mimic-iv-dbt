-- ED visit authority: one OMOP visit per ed.edstays row (concept 9203 Emergency Room Visit),
-- id allocated in band 27 so it never collides with the hadm/no-hadm visits (band 3).
-- hadm_id, when present, is the signal that an inpatient admission followed this ED stay; downstream
-- visit_occurrence uses it to set the inpatient visit's preceding_visit_occurrence_id to this ED visit.
SELECT
    {{ mimic_sk('ed_visit', 'subject_id, stay_id') }} AS visit_occurrence_id,
    subject_id,
    hadm_id,
    stay_id,
    intime                                  AS visit_start_datetime,
    COALESCE(outtime, intime)               AS visit_end_datetime,
    arrival_transport,
    disposition,
    'ED|' || CAST(subject_id AS VARCHAR) || '|' || CAST(stay_id AS VARCHAR) AS visit_source_value
FROM {{ ref('src_ed_edstays') }}
