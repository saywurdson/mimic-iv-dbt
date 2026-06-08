-- cdm_specimen from lk_specimen_mapped, domain='Specimen'.
SELECT
    src.specimen_id                             AS specimen_id,
    per.person_id                               AS person_id,
    COALESCE(src.target_concept_id, 0)          AS specimen_concept_id,
    32856                                       AS specimen_type_concept_id,
    CAST(src.start_datetime AS DATE)            AS specimen_date,
    src.start_datetime                          AS specimen_datetime,
    CAST(NULL AS DOUBLE)                        AS quantity,
    CAST(NULL AS BIGINT)                        AS unit_concept_id,
    0                                           AS anatomic_site_concept_id,
    0                                           AS disease_status_concept_id,
    src.trace_id                                AS specimen_source_id,
    src.source_code                             AS specimen_source_value,
    CAST(NULL AS VARCHAR)                       AS unit_source_value,
    CAST(NULL AS VARCHAR)                       AS anatomic_site_source_value,
    CAST(NULL AS VARCHAR)                       AS disease_status_source_value
FROM {{ ref('lk_specimen_mapped') }} src
INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
WHERE src.target_domain_id = 'Specimen'
