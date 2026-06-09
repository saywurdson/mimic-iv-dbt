{{ config(materialized='table') }}

/* One row per hospital admission, enriched with the derived critical-care
   attributes the KPI summary marts roll up: patient age at admission, hospital +
   ICU length of stay, in-hospital / 30-day mortality, and 30-day readmission.

   Grounded in the MIMIC-IV source tables rather than the OMOP layer, because that
   layer loses two distinctions these KPIs need:

     * "Hospital admission" = a row in `admissions` (a hadm_id). MIMIC-IV's OMOP
       visit_occurrence unions real admissions with synthesized no-hadm
       outpatient/ED single-day visits (it is ~2.9M rows vs. ~546k admissions),
       and visit_concept_id is derived from admission_type, so it cannot separate
       the two. We join visit_occurrence back to `src_admissions` on the hadm key.

     * ICU stays come from `transfers.careunit`. This ETL's care-unit concept
       mapping only resolves the MICU/SICU unit to a standard concept (32037);
       every other ICU unit lands on concept 0, so visit_detail_concept_id misses
       them. We detect ICU from the care-unit names directly.

   MIMIC-IV de-identifies dates by shifting each patient's events into the future,
   so intervals (length of stay, age, readmission gaps) are exact while calendar
   dates are not. Age comes from anchor_year/anchor_age; patients 89 or older are
   recorded with anchor_age 91, so any computed age over 89 is the de-identified
   elderly cohort -- flagged (age_deid_capped) and capped at 90. */

WITH adm AS (
    SELECT
        subject_id,
        hadm_id,
        admittime,
        dischtime,
        deathtime,
        CAST(subject_id AS VARCHAR) || '|' || CAST(hadm_id AS VARCHAR) AS visit_source_value
    FROM {{ ref('src_admissions') }}
    WHERE hadm_id IS NOT NULL
),

-- OMOP keys (visit_occurrence_id, person_id) for each real admission
vis AS (
    SELECT visit_occurrence_id, person_id, visit_source_value
    FROM {{ ref('visit_occurrence') }}
),

-- ICU stays per admission, detected from the source care-unit names. The standard
-- MIMIC-IV ICU units (note "Trauma SICU (TSICU)" has no "Intensive Care" text);
-- the *Intermediate / Stepdown / PACU units are deliberately not ICUs.
icu AS (
    SELECT
        hadm_id,
        count(*) AS icu_stay_count,
        sum(date_diff('hour', intime, outtime) / 24.0) AS icu_los_days
    FROM {{ ref('src_transfers') }}
    WHERE outtime >= intime
      AND careunit IN (
          'Medical Intensive Care Unit (MICU)',
          'Medical/Surgical Intensive Care Unit (MICU/SICU)',
          'Surgical Intensive Care Unit (SICU)',
          'Cardiac Vascular Intensive Care Unit (CVICU)',
          'Trauma SICU (TSICU)',
          'Coronary Care Unit (CCU)',
          'Neuro Surgical Intensive Care Unit (Neuro SICU)',
          'Neonatal Intensive Care Unit (NICU)',
          'Intensive Care Unit (ICU)'
      )
    GROUP BY 1
),

base AS (
    SELECT
        v.visit_occurrence_id,
        v.person_id,
        CAST(a.admittime AS DATE) AS visit_start_date,
        CAST(a.dischtime AS DATE) AS visit_end_date,
        a.deathtime,
        greatest(date_diff('day', a.admittime, a.dischtime), 0) AS hospital_los_days,
        extract(year FROM a.admittime) - p.year_of_birth AS age_raw,
        coalesce(i.icu_stay_count, 0) AS icu_stay_count,
        coalesce(i.icu_los_days, 0) AS icu_los_days,
        i.hadm_id IS NOT NULL AS had_icu_stay,
        -- discharge date of this patient's immediately preceding admission
        lag(CAST(a.dischtime AS DATE)) OVER (
            PARTITION BY v.person_id
            ORDER BY a.admittime, v.visit_occurrence_id
        ) AS prev_discharge_date
    FROM adm a
    JOIN vis v USING (visit_source_value)
    JOIN {{ ref('person') }} p ON p.person_id = v.person_id
    LEFT JOIN icu i USING (hadm_id)
),

deaths AS (
    SELECT person_id, death_date FROM {{ ref('death') }}
)

SELECT
    b.visit_occurrence_id,
    b.person_id,
    b.visit_start_date,
    b.visit_end_date,
    CASE WHEN b.age_raw > 89 THEN 90 ELSE b.age_raw END AS age,
    b.age_raw > 89 AS age_deid_capped,
    CASE
        WHEN b.age_raw < 1  THEN '0 (neonate)'
        WHEN b.age_raw <= 17 THEN '1-17'
        WHEN b.age_raw <= 44 THEN '18-44'
        WHEN b.age_raw <= 64 THEN '45-64'
        WHEN b.age_raw <= 89 THEN '65-89'
        ELSE '90+'
    END AS age_band,
    b.hospital_los_days,
    b.icu_stay_count,
    b.icu_los_days,
    b.had_icu_stay,
    -- in-hospital death: admissions records a deathtime for deaths during the stay
    b.deathtime IS NOT NULL AS died_in_hospital,
    -- 30-day mortality: death within 30 days of discharge
    coalesce(d.death_date BETWEEN b.visit_start_date AND b.visit_end_date + 30, FALSE) AS died_within_30d,
    -- 30-day readmission: this admission follows a prior discharge by 0-30 days
    coalesce(
        b.prev_discharge_date IS NOT NULL
        AND date_diff('day', b.prev_discharge_date, b.visit_start_date) BETWEEN 0 AND 30,
        FALSE
    ) AS is_readmission_30d
FROM base b
LEFT JOIN deaths d ON d.person_id = b.person_id
