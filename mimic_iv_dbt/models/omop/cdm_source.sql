-- cdm_cdm_source: single metadata row.
SELECT
    '{{ var("cdm_source_name") }}'          AS cdm_source_name,
    '{{ var("cdm_source_abbreviation") }}'  AS cdm_source_abbreviation,
    'PhysioNet'                             AS cdm_holder,
    'MIMIC-IV is a publicly available database of patients admitted to the '
        || 'Beth Israel Deaconess Medical Center in Boston, MA, USA.' AS source_description,
    'https://mimic-iv.mit.edu/docs/'        AS source_documentation_reference,
    'https://github.com/OHDSI/MIMIC/'       AS cdm_etl_reference,
    CAST('2020-09-01' AS DATE)              AS source_release_date,
    CURRENT_DATE                            AS cdm_release_date,
    '{{ var("cdm_version") }}'              AS cdm_version,
    CAST(NULL AS BIGINT)                    AS cdm_version_concept_id,
    (SELECT MAX(vocabulary_version) FROM {{ ref('voc_vocabulary') }} WHERE vocabulary_id = 'None') AS vocabulary_version
