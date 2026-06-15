-- cdm_cost: one cost row per DRG code, linked to its hospitalization (visit).
-- MIMIC has no monetary amounts, so all money columns are NULL; the real signal is the DRG concept.
SELECT
    {{ mimic_sk('cost', 'vis.visit_occurrence_id, drg.drg_code, drg.drg_type') }} AS cost_id,
    vis.visit_occurrence_id                 AS cost_event_id,
    'Visit'                                 AS cost_domain_id,
    32817                                   AS cost_type_concept_id,   -- EHR
    CAST(NULL AS BIGINT)                    AS currency_concept_id,
    CAST(NULL AS DOUBLE)                    AS total_charge,
    CAST(NULL AS DOUBLE)                    AS total_cost,
    CAST(NULL AS DOUBLE)                    AS total_paid,
    CAST(NULL AS DOUBLE)                    AS paid_by_payer,
    CAST(NULL AS DOUBLE)                    AS paid_by_patient,
    CAST(NULL AS DOUBLE)                    AS paid_patient_copay,
    CAST(NULL AS DOUBLE)                    AS paid_patient_coinsurance,
    CAST(NULL AS DOUBLE)                    AS paid_patient_deductible,
    CAST(NULL AS DOUBLE)                    AS paid_by_primary,
    CAST(NULL AS DOUBLE)                    AS paid_ingredient_cost,
    CAST(NULL AS DOUBLE)                    AS paid_dispensing_fee,
    CAST(NULL AS BIGINT)                    AS payer_plan_period_id,
    CAST(NULL AS DOUBLE)                    AS amount_allowed,
    0                                       AS revenue_code_concept_id,
    CAST(NULL AS VARCHAR)                   AS revenue_code_source_value,
    COALESCE(dc.concept_id, 0)              AS drg_concept_id,
    drg.drg_code                            AS drg_source_value
FROM {{ ref('src_drgcodes') }} drg
INNER JOIN {{ ref('visit_occurrence') }} vis
    ON vis.visit_source_value = CAST(drg.subject_id AS VARCHAR) || '|' || CAST(drg.hadm_id AS VARCHAR)
-- one DRG concept per code (the DRG vocab has multiple versioned concepts per code); prefer valid, newest
LEFT JOIN (
    SELECT concept_code, concept_id FROM (
        SELECT concept_code, concept_id,
               row_number() OVER (PARTITION BY concept_code
                   ORDER BY (invalid_reason IS NULL) DESC, concept_id DESC) AS rn
        FROM {{ ref('concept') }} WHERE vocabulary_id = 'DRG'
    ) WHERE rn = 1
) dc
    ON dc.concept_code = LPAD(drg.drg_code, 3, '0')   -- MS-DRG is 3-digit zero-padded
   AND drg.drg_type = 'HCFA'   -- MS-DRG (CMS); APR-DRG rows have no DRG-vocab match -> concept 0
