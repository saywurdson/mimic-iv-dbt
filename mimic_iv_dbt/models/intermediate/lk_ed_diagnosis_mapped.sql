-- lk_ed_diagnosis_mapped: MIMIC-IV-ED ed.diagnosis ICD9CM/ICD10CM (dots stripped) -> standard.
-- Mirrors lk_diagnoses_icd_mapped, but keyed on the ED stay: dates come from the ED visit
-- (lk_ed_visit start/end) and visit linkage is carried via stay_id.
WITH clean AS (
    SELECT
        src.subject_id,
        src.stay_id,
        CASE WHEN src.seq_num > 20 THEN 20 ELSE src.seq_num END AS seq_num,
        vis.visit_start_datetime                    AS start_datetime,
        vis.visit_end_datetime                      AS end_datetime,
        src.icd_code                                AS source_code,
        CASE WHEN src.icd_version = 9 THEN 'ICD9CM'
             WHEN src.icd_version = 10 THEN 'ICD10CM' END AS source_vocabulary_id,
        src.load_table_id
    FROM {{ ref('src_ed_diagnosis') }} src
    INNER JOIN {{ ref('lk_ed_visit') }} vis ON src.stay_id = vis.stay_id
)
SELECT
    src.subject_id                      AS subject_id,
    src.stay_id                         AS stay_id,
    src.seq_num                         AS seq_num,
    src.start_datetime                  AS start_datetime,
    src.end_datetime                    AS end_datetime,
    32817                               AS type_concept_id,
    src.source_code                     AS source_code,
    src.source_vocabulary_id            AS source_vocabulary_id,
    vc.concept_id                       AS source_concept_id,
    vc.domain_id                        AS source_domain_id,
    vc2.concept_id                      AS target_concept_id,
    COALESCE(vc2.domain_id, 'Condition') AS target_domain_id,
    'cond.ed_diagnosis'                 AS unit_id,
    src.load_table_id
FROM clean src
LEFT JOIN {{ ref('voc_concept') }} vc
    ON  REPLACE(vc.concept_code, '.', '') = REPLACE(TRIM(src.source_code), '.', '')
    AND vc.vocabulary_id = src.source_vocabulary_id
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON  vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON  vc2.concept_id = vcr.concept_id_2
    AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
