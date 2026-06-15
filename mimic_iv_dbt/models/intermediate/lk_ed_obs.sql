-- ED observation mapper: triage chiefcomplaint/acuity + vitalsign rhythm -> Observation domain.
-- chiefcomplaint -> value_as_string (concept 37158808), acuity -> value_as_number (concept 0),
-- rhythm -> value_as_string (concept 0). Concept_ids sourced from ed_vital_to_concept where
-- target_domain='Observation'. visit_occurrence_id from lk_ed_visit (band 27) on stay_id;
-- person_id resolved downstream via cdm_person_all on person_source_value = CAST(subject_id AS VARCHAR).
WITH ed_obs_concept AS (
    SELECT ed_column, concept_id
    FROM {{ ref('ed_vital_to_concept') }}
    WHERE target_domain = 'Observation'
),
triage_chief AS (
    SELECT
        t.subject_id                            AS subject_id,
        v.visit_occurrence_id                   AS visit_occurrence_id,
        COALESCE(c.concept_id, 0)               AS observation_concept_id,
        v.visit_start_datetime                  AS observation_datetime,
        CAST(NULL AS DOUBLE)                     AS value_as_number,
        t.chiefcomplaint                        AS value_as_string,
        'chiefcomplaint'                        AS source_code,
        'triage'                                AS load_table_id
    FROM {{ ref('src_ed_triage') }} t
    INNER JOIN {{ ref('lk_ed_visit') }} v ON t.stay_id = v.stay_id
    LEFT JOIN ed_obs_concept c ON c.ed_column = 'chiefcomplaint'
    WHERE t.chiefcomplaint IS NOT NULL
),
triage_acuity AS (
    SELECT
        t.subject_id                            AS subject_id,
        v.visit_occurrence_id                   AS visit_occurrence_id,
        COALESCE(c.concept_id, 0)               AS observation_concept_id,
        v.visit_start_datetime                  AS observation_datetime,
        t.acuity                                 AS value_as_number,
        CAST(NULL AS VARCHAR)                    AS value_as_string,
        'acuity'                                AS source_code,
        'triage'                                AS load_table_id
    FROM {{ ref('src_ed_triage') }} t
    INNER JOIN {{ ref('lk_ed_visit') }} v ON t.stay_id = v.stay_id
    LEFT JOIN ed_obs_concept c ON c.ed_column = 'acuity'
    WHERE t.acuity IS NOT NULL
),
vital_rhythm AS (
    SELECT
        s.subject_id                            AS subject_id,
        v.visit_occurrence_id                   AS visit_occurrence_id,
        COALESCE(c.concept_id, 0)               AS observation_concept_id,
        s.charttime                             AS observation_datetime,
        CAST(NULL AS DOUBLE)                     AS value_as_number,
        s.rhythm                                AS value_as_string,
        'rhythm'                                AS source_code,
        'vitalsign'                             AS load_table_id
    FROM {{ ref('src_ed_vitalsign') }} s
    INNER JOIN {{ ref('lk_ed_visit') }} v ON s.stay_id = v.stay_id
    LEFT JOIN ed_obs_concept c ON c.ed_column = 'rhythm'
    WHERE s.rhythm IS NOT NULL
)
SELECT
    subject_id,
    visit_occurrence_id,
    observation_concept_id,
    observation_datetime,
    32817                                       AS observation_type_concept_id,
    value_as_number,
    value_as_string,
    source_code,
    load_table_id
FROM triage_chief
UNION ALL SELECT
    subject_id, visit_occurrence_id, observation_concept_id, observation_datetime,
    32817 AS observation_type_concept_id, value_as_number, value_as_string, source_code, load_table_id
FROM triage_acuity
UNION ALL SELECT
    subject_id, visit_occurrence_id, observation_concept_id, observation_datetime,
    32817 AS observation_type_concept_id, value_as_number, value_as_string, source_code, load_table_id
FROM vital_rhythm
