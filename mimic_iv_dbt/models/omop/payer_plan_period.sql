-- cdm_payer_plan_period: one period per hospital admission; payer from admissions.insurance.
SELECT
    {{ mimic_sk('payer_plan_period', 'per.person_id, adm.admittime, adm.hadm_id') }} AS payer_plan_period_id,
    per.person_id,
    CAST(adm.admittime AS DATE)             AS payer_plan_period_start_date,
    CAST(adm.dischtime AS DATE)             AS payer_plan_period_end_date,
    COALESCE(ins.payer_concept_id, 0)       AS payer_concept_id,
    adm.insurance                           AS payer_source_value,
    0                                       AS payer_source_concept_id,
    0                                       AS plan_concept_id,
    CAST(NULL AS VARCHAR)                   AS plan_source_value,
    0                                       AS plan_source_concept_id,
    0                                       AS sponsor_concept_id,
    CAST(NULL AS VARCHAR)                   AS sponsor_source_value,
    0                                       AS sponsor_source_concept_id,
    CAST(NULL AS VARCHAR)                   AS family_source_value,
    0                                       AS stop_reason_concept_id,
    CAST(NULL AS VARCHAR)                   AS stop_reason_source_value,
    0                                       AS stop_reason_source_concept_id
FROM {{ ref('src_admissions') }} adm
INNER JOIN {{ ref('cdm_person_all') }} per
    ON per.person_source_value = CAST(adm.subject_id AS VARCHAR)
LEFT JOIN {{ ref('insurance_to_concept') }} ins
    ON ins.insurance = adm.insurance
WHERE adm.admittime IS NOT NULL
  AND adm.dischtime IS NOT NULL
