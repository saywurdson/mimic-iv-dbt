{{ config(materialized='table') }}

/* One row per patient, rolled up from kpi_admission_base and joined to
   demographics (gender, race) resolved to vocabulary names. Attributes recorded
   at the patient's first admission (age, age_band) use min_by over admit date. */

WITH adm AS (
    SELECT
        person_id,
        count(*) AS n_admissions,
        sum(icu_stay_count) AS n_icu_stays,
        bool_or(had_icu_stay) AS ever_icu,
        sum(hospital_los_days) AS total_hospital_los_days,
        sum(icu_los_days) AS total_icu_los_days,
        bool_or(died_in_hospital) AS died_in_hospital,
        min(visit_start_date) AS first_admit_date,
        min_by(age, visit_start_date) AS age_at_first_admit,
        min_by(age_band, visit_start_date) AS age_band
    FROM {{ ref('kpi_admission_base') }}
    GROUP BY 1
)

SELECT
    a.person_id,
    coalesce(gc.concept_name, 'Unknown') AS gender,
    coalesce(rc.concept_name, 'Unknown') AS race,
    a.age_at_first_admit,
    a.age_band,
    a.n_admissions,
    a.n_icu_stays,
    a.ever_icu,
    a.total_hospital_los_days,
    a.total_icu_los_days,
    a.died_in_hospital,
    d.person_id IS NOT NULL AS died_ever
FROM adm a
JOIN {{ ref('person') }} p USING (person_id)
LEFT JOIN {{ ref('concept') }} gc ON gc.concept_id = p.gender_concept_id
LEFT JOIN {{ ref('concept') }} rc ON rc.concept_id = p.race_concept_id
LEFT JOIN {{ ref('death') }} d ON d.person_id = a.person_id
