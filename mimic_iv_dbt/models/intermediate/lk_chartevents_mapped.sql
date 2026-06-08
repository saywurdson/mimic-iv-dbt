-- lk_chartevents_mapped: chartevents mapped (HEAVY); fans out by target_domain_id to meas/obs/proc/device.
SELECT
    {{ mimic_sk('chartevents', 'src.subject_id, src.stay_id, src.start_datetime, src.itemid, src.value') }} AS measurement_id,
    src.subject_id                              AS subject_id,
    src.hadm_id                                 AS hadm_id,
    src.stay_id                                 AS stay_id,
    src.start_datetime                          AS start_datetime,
    32817                                       AS type_concept_id,
    src.itemid                                  AS itemid,
    src.source_code                             AS source_code,
    src.source_label                            AS source_label,
    c_main.source_vocabulary_id                 AS source_vocabulary_id,
    c_main.source_domain_id                     AS source_domain_id,
    c_main.source_concept_id                    AS source_concept_id,
    c_main.target_domain_id                     AS target_domain_id,
    c_main.target_concept_id                    AS target_concept_id,
    src.value                                   AS value_source_value,
    CASE WHEN (CASE WHEN src.valuenum IS NULL THEN src.value ELSE NULL END) IS NOT NULL
         THEN COALESCE(c_value.target_concept_id, 0) END AS value_as_concept_id,
    src.valuenum                                AS value_as_number,
    src.valueuom                                AS unit_source_value,
    CASE WHEN src.valueuom IS NOT NULL THEN COALESCE(uc.target_concept_id, 0) END AS unit_concept_id,
    'meas.chartevents'                          AS unit_id,
    src.load_table_id
FROM {{ ref('lk_chartevents_clean') }} src
LEFT JOIN {{ ref('lk_chartevents_concept') }} c_main
    ON c_main.source_code = src.source_code AND c_main.source_vocabulary_id = 'mimiciv_meas_chart'
LEFT JOIN {{ ref('lk_chartevents_concept') }} c_value
    ON c_value.source_code = src.value
    AND c_value.source_vocabulary_id = 'mimiciv_meas_chartevents_value'
    AND c_value.target_domain_id = 'Meas Value'
LEFT JOIN {{ ref('lk_meas_unit_concept') }} uc
    ON uc.source_code = src.valueuom
