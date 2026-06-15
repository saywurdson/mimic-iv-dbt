-- cdm_metadata: build/version provenance (CDM version, vocabulary version, source descriptors).
WITH meta(name, value_as_string) AS (
    SELECT 'CDM Version',              'CDM v{{ var("cdm_version") }}'
    UNION ALL SELECT 'CDM Source Name',         '{{ var("cdm_source_name") }}'
    UNION ALL SELECT 'CDM Source Abbreviation', '{{ var("cdm_source_abbreviation") }}'
    UNION ALL SELECT 'Vocabulary Version',
        (SELECT MAX(vocabulary_version) FROM {{ ref('vocabulary') }} WHERE vocabulary_id = 'None')
)
SELECT
    {{ mimic_sk('metadata', 'name') }}      AS metadata_id,
    0                                       AS metadata_concept_id,
    0                                       AS metadata_type_concept_id,
    name,
    value_as_string,
    CAST(NULL AS BIGINT)                    AS value_as_concept_id,
    CAST(NULL AS DOUBLE)                    AS value_as_number,
    CURRENT_DATE                            AS metadata_date,
    CURRENT_TIMESTAMP                       AS metadata_datetime
FROM meta
