-- cdm_death: deathtime from earliest admission per subject; death_date = min(deathtime, dischtime).
WITH lk_death_adm AS (
    SELECT DISTINCT
        subject_id,
        FIRST_VALUE(deathtime) OVER (PARTITION BY subject_id ORDER BY admittime ASC) AS deathtime,
        FIRST_VALUE(dischtime) OVER (PARTITION BY subject_id ORDER BY admittime ASC) AS dischtime,
        32817 AS type_concept_id
    FROM {{ ref('src_admissions') }}
    WHERE deathtime IS NOT NULL
)
SELECT
    per.person_id                                       AS person_id,
    CAST(CASE WHEN src.deathtime <= src.dischtime THEN src.deathtime ELSE src.dischtime END AS DATE) AS death_date,
    CASE WHEN src.deathtime <= src.dischtime THEN src.deathtime ELSE src.dischtime END               AS death_datetime,
    src.type_concept_id                                 AS death_type_concept_id,
    0                                                   AS cause_concept_id,
    CAST(NULL AS VARCHAR)                               AS cause_source_value,
    0                                                   AS cause_source_concept_id
FROM lk_death_adm src
INNER JOIN {{ ref('cdm_person_all') }} per
    ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
