-- cdm_visit_occurrence: hadm/no-hadm visits (band 3) + ED visits from the ED module (band 27, concept 9203).
-- When an ED stay has a hadm_id (an admission followed), the inpatient visit's preceding_visit_occurrence_id is
-- set to that ED visit, so the ED-preceded-admission link is reflected in the data.
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
    COALESCE(
        ed_prec.visit_occurrence_id,
        LAG(src.visit_occurrence_id) OVER (PARTITION BY src.subject_id, src.hadm_id ORDER BY src.start_datetime)
    )                                       AS preceding_visit_occurrence_id
FROM {{ ref('lk_visit_clean') }} src
INNER JOIN {{ ref('cdm_person_all') }} per
    ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
LEFT JOIN {{ ref('lk_visit_concept') }} lat ON lat.source_code = src.admission_type
LEFT JOIN {{ ref('lk_visit_concept') }} la  ON la.source_code = src.admission_location
LEFT JOIN {{ ref('lk_visit_concept') }} ld  ON ld.source_code = src.discharge_location
LEFT JOIN {{ ref('care_site') }} cs     ON cs.care_site_name = 'BIDMC'
LEFT JOIN {{ ref('voc_concept') }} da ON da.concept_id = (CASE WHEN src.admission_location IS NOT NULL THEN COALESCE(la.target_concept_id, 0) END)
LEFT JOIN {{ ref('voc_concept') }} db ON db.concept_id = (CASE WHEN src.discharge_location IS NOT NULL THEN COALESCE(ld.target_concept_id, 0) END)
-- ED stay that preceded this admission (one per hadm): its ED visit becomes the inpatient's preceding visit
LEFT JOIN (
    SELECT hadm_id, MAX(visit_occurrence_id) AS visit_occurrence_id
    FROM {{ ref('lk_ed_visit') }} WHERE hadm_id IS NOT NULL GROUP BY hadm_id
) ed_prec ON ed_prec.hadm_id = src.hadm_id

UNION ALL

-- ED visits (one per ed.edstays row), concept 9203 Emergency Room Visit
SELECT
    edv.visit_occurrence_id                 AS visit_occurrence_id,
    per.person_id                           AS person_id,
    9203                                    AS visit_concept_id,        -- Emergency Room Visit
    CAST(edv.visit_start_datetime AS DATE)  AS visit_start_date,
    edv.visit_start_datetime                AS visit_start_datetime,
    CAST(edv.visit_end_datetime AS DATE)    AS visit_end_date,
    edv.visit_end_datetime                  AS visit_end_datetime,
    32817                                   AS visit_type_concept_id,
    CAST(NULL AS BIGINT)                    AS provider_id,
    cs.care_site_id                         AS care_site_id,
    edv.visit_source_value                  AS visit_source_value,
    0                                       AS visit_source_concept_id,
    0                                       AS admitted_from_concept_id,
    edv.arrival_transport                   AS admitted_from_source_value,
    0                                       AS discharged_to_concept_id,
    edv.disposition                         AS discharged_to_source_value,
    CAST(NULL AS BIGINT)                    AS preceding_visit_occurrence_id
FROM {{ ref('lk_ed_visit') }} edv
INNER JOIN {{ ref('cdm_person_all') }} per
    ON CAST(edv.subject_id AS VARCHAR) = per.person_source_value
LEFT JOIN {{ ref('care_site') }} cs ON cs.care_site_name = 'BIDMC'
