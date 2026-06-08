-- cdm_visit_detail (transfers + ER + services); concept and care_site via current_location.
SELECT
    src.visit_detail_id                     AS visit_detail_id,
    per.person_id                           AS person_id,
    COALESCE(vdc.target_concept_id, 0)      AS visit_detail_concept_id,
    CAST(src.start_datetime AS DATE)        AS visit_detail_start_date,
    src.start_datetime                      AS visit_detail_start_datetime,
    CASE WHEN CAST(src.end_datetime AS DATE) < CAST(src.start_datetime AS DATE) THEN CAST(src.start_datetime AS DATE) ELSE CAST(src.end_datetime AS DATE) END AS visit_detail_end_date,
    CASE WHEN src.end_datetime < src.start_datetime THEN src.start_datetime ELSE src.end_datetime END AS visit_detail_end_datetime,
    32817                                   AS visit_detail_type_concept_id,
    CAST(NULL AS BIGINT)                    AS provider_id,
    cs.care_site_id                         AS care_site_id,
    CASE WHEN da.domain_id = 'Visit' THEN (CASE WHEN src.admission_location IS NOT NULL THEN COALESCE(la.target_concept_id, 0) END) ELSE 0 END AS admitted_from_concept_id,
    CASE WHEN db.domain_id = 'Visit' THEN (CASE WHEN src.discharge_location IS NOT NULL THEN COALESCE(ld.target_concept_id, 0) END) ELSE 0 END AS discharged_to_concept_id,
    src.preceding_visit_detail_id           AS preceding_visit_detail_id,
    src.source_value                        AS visit_detail_source_value,
    COALESCE(vdc.source_concept_id, 0)      AS visit_detail_source_concept_id,
    src.admission_location                  AS admitted_from_source_value,
    src.discharge_location                  AS discharged_to_source_value,
    CAST(NULL AS BIGINT)                    AS parent_visit_detail_id,
    vis.visit_occurrence_id                 AS visit_occurrence_id
FROM {{ ref('lk_visit_detail_prev_next') }} src
INNER JOIN {{ ref('cdm_person_all') }} per
    ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
INNER JOIN {{ ref('visit_occurrence') }} vis
    ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' ||
        COALESCE(CAST(src.hadm_id AS VARCHAR), CAST(src.date_id AS VARCHAR))
LEFT JOIN {{ ref('care_site') }} cs     ON cs.care_site_source_value = src.current_location
LEFT JOIN {{ ref('lk_visit_concept') }} vdc ON vdc.source_code = src.current_location
LEFT JOIN {{ ref('lk_visit_concept') }} la  ON la.source_code = src.admission_location
LEFT JOIN {{ ref('lk_visit_concept') }} ld  ON ld.source_code = src.discharge_location
LEFT JOIN {{ ref('voc_concept') }} da ON da.concept_id = (CASE WHEN src.admission_location IS NOT NULL THEN COALESCE(la.target_concept_id, 0) END)
LEFT JOIN {{ ref('voc_concept') }} db ON db.concept_id = (CASE WHEN src.discharge_location IS NOT NULL THEN COALESCE(ld.target_concept_id, 0) END)
