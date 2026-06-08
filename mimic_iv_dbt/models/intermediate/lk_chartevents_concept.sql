-- lk_chartevents_concept: distinct chartevents itemids + values -> standard concepts.
WITH code_dist AS (
    SELECT itemid, source_code, source_label, 'mimiciv_meas_chart' AS source_vocabulary_id, COUNT(*) AS row_count
    FROM {{ ref('lk_chartevents_clean') }}
    GROUP BY itemid, source_code, source_label
    UNION ALL
    SELECT CAST(NULL AS BIGINT) AS itemid, value AS source_code, value AS source_label,
           'mimiciv_meas_chartevents_value' AS source_vocabulary_id, COUNT(*) AS row_count
    FROM {{ ref('lk_chartevents_clean') }}
    GROUP BY value
)
SELECT
    src.itemid                  AS itemid,
    src.source_code             AS source_code,
    src.source_label            AS source_label,
    src.source_vocabulary_id    AS source_vocabulary_id,
    vc.domain_id                AS source_domain_id,
    vc.concept_id               AS source_concept_id,
    vc2.domain_id               AS target_domain_id,
    vc2.concept_id              AS target_concept_id,
    src.row_count               AS row_count
FROM code_dist src
LEFT JOIN {{ ref('voc_concept') }} vc
    ON  vc.concept_code = src.source_code
    AND vc.vocabulary_id = src.source_vocabulary_id
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON  vc.concept_id = vcr.concept_id_1
    AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON  vc2.concept_id = vcr.concept_id_2
    AND vc2.standard_concept = 'S'
    AND vc2.invalid_reason IS NULL
