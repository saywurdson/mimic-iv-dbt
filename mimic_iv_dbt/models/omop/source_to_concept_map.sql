-- cdm_source_to_concept_map: custom source->standard mappings used by the ETL.
-- Reshapes the custom_mapping seed (the MIMIC-IV local concepts + their 'Maps to' target) into STCM.
SELECT
    LEFT(cm.concept_code, 50)                AS source_code,   -- CDM 5.4 source_code is varchar(50)
    CAST(cm.source_concept_id AS BIGINT)     AS source_concept_id,
    cm.source_vocabulary_id                  AS source_vocabulary_id,
    cm.concept_name                          AS source_code_description,
    CAST(cm.target_concept_id AS BIGINT)     AS target_concept_id,
    COALESCE(tc.vocabulary_id, 'None')       AS target_vocabulary_id,
    COALESCE(cm.valid_start_date, CAST('1970-01-01' AS DATE)) AS valid_start_date,
    COALESCE(cm.valid_end_date,   CAST('2099-12-31' AS DATE)) AS valid_end_date,
    cm.invalid_reason                        AS invalid_reason
FROM {{ ref('int_custom_mapping') }} cm
LEFT JOIN {{ ref('concept') }} tc ON tc.concept_id = cm.target_concept_id
WHERE CAST(cm.target_concept_id AS BIGINT) > 0
  AND cm.concept_code IS NOT NULL
  AND cm.relationship_id = 'Maps to'
