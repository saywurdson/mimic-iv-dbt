-- derive end_datetime, preceding visit_detail_id, and admission/discharge locations.
SELECT
    src.visit_detail_id,
    src.subject_id,
    src.hadm_id,
    src.date_id,
    src.start_datetime,
    COALESCE(
        src.end_datetime,
        LEAD(src.start_datetime) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id ORDER BY src.start_datetime ASC),
        vis.end_datetime
    )                                               AS end_datetime,
    src.source_value,
    src.current_location,
    LAG(src.visit_detail_id) OVER (
        PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
        ORDER BY src.start_datetime ASC)            AS preceding_visit_detail_id,
    COALESCE(
        LAG(src.current_location) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
            ORDER BY src.start_datetime ASC),
        vis.admission_location)                     AS admission_location,
    COALESCE(
        LEAD(src.current_location) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
            ORDER BY src.start_datetime ASC),
        vis.discharge_location)                     AS discharge_location,
    src.unit_id,
    src.load_table_id
FROM {{ ref('lk_visit_detail_clean') }} src
LEFT JOIN {{ ref('lk_visit_clean') }} vis
    ON  src.subject_id = vis.subject_id
    AND (src.hadm_id = vis.hadm_id OR (src.hadm_id IS NULL AND src.date_id = vis.date_id))
