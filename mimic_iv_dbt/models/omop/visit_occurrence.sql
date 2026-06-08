-- cdm_visit_occurrence: visit_concept via admission_type; care_site via BIDMC (NULL if no BIDMC row).
SELECT
    src.visit_occurrence_id                 AS visit_occurrence_id,
    per.person_id                           AS person_id,
    COALESCE(lat.target_concept_id, 0)      AS visit_concept_id,
    CAST(src.start_datetime AS DATE)        AS visit_start_date,
    src.start_datetime                      AS visit_start_datetime,
    CAST(src.end_datetime AS DATE)          AS visit_end_date,
    src.end_datetime                        AS visit_end_datetime,
    32817                                   AS visit_type_concept_id,
    CAST(NULL AS BIGINT)                    AS provider_id,
    cs.care_site_id                         AS care_site_id,
    src.source_value                        AS visit_source_value,
    COALESCE(lat.source_concept_id, 0)      AS visit_source_concept_id,
    CASE WHEN da.domain_id = 'Visit' THEN (CASE WHEN src.admission_location IS NOT NULL THEN COALESCE(la.target_concept_id, 0) END) ELSE 0 END AS admitted_from_concept_id,
    src.admission_location                  AS admitted_from_source_value,
    CASE WHEN db.domain_id = 'Visit' THEN (CASE WHEN src.discharge_location IS NOT NULL THEN COALESCE(ld.target_concept_id, 0) END) ELSE 0 END AS discharged_to_concept_id,
    src.discharge_location                  AS discharged_to_source_value,
    LAG(src.visit_occurrence_id) OVER (
        PARTITION BY src.subject_id, src.hadm_id ORDER BY src.start_datetime) AS preceding_visit_occurrence_id
FROM {{ ref('lk_visit_clean') }} src
INNER JOIN {{ ref('cdm_person_all') }} per
    ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
LEFT JOIN {{ ref('lk_visit_concept') }} lat ON lat.source_code = src.admission_type
LEFT JOIN {{ ref('lk_visit_concept') }} la  ON la.source_code = src.admission_location
LEFT JOIN {{ ref('lk_visit_concept') }} ld  ON ld.source_code = src.discharge_location
LEFT JOIN {{ ref('care_site') }} cs     ON cs.care_site_name = 'BIDMC'
LEFT JOIN {{ ref('voc_concept') }} da ON da.concept_id = (CASE WHEN src.admission_location IS NOT NULL THEN COALESCE(la.target_concept_id, 0) END)
LEFT JOIN {{ ref('voc_concept') }} db ON db.concept_id = (CASE WHEN src.discharge_location IS NOT NULL THEN COALESCE(ld.target_concept_id, 0) END)
