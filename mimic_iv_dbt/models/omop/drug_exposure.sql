-- cdm_drug_exposure from lk_drug_mapped, domain='Drug'.
SELECT
    {{ mimic_sk('drug_exposure', 'src.subject_id, src.start_datetime, src.source_code, src.pharmacy_id') }} AS drug_exposure_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS drug_concept_id,
    CAST(src.start_datetime AS DATE)            AS drug_exposure_start_date,
    src.start_datetime                          AS drug_exposure_start_datetime,
    CAST(src.end_datetime AS DATE)              AS drug_exposure_end_date,
    src.end_datetime                            AS drug_exposure_end_datetime,
    CAST(NULL AS DATE)                          AS verbatim_end_date,
    src.type_concept_id                         AS drug_type_concept_id,
    CAST(NULL AS VARCHAR)                       AS stop_reason,
    CAST(NULL AS BIGINT)                        AS refills,
    src.quantity                                AS quantity,
    CAST(GREATEST(COALESCE(date_diff('day', CAST(src.start_datetime AS DATE), CAST(src.end_datetime AS DATE)), 0), 0) + 1 AS BIGINT) AS days_supply,
    CAST(NULL AS VARCHAR)                       AS sig,
    src.route_concept_id                        AS route_concept_id,
    CAST(NULL AS VARCHAR)                       AS lot_number,
    CAST(NULL AS BIGINT)                        AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    CAST(NULL AS BIGINT)                        AS visit_detail_id,
    src.source_code                             AS drug_source_value,
    src.source_concept_id                       AS drug_source_concept_id,
    src.route_source_code                       AS route_source_value,
    src.dose_unit_source_code                   AS dose_unit_source_value
FROM {{ ref('lk_drug_mapped') }} src
INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
LEFT JOIN {{ ref('visit_occurrence') }} vis
    ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
WHERE src.target_domain_id = 'Drug'
