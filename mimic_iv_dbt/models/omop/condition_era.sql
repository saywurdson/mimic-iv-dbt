-- cdm_condition_era: collapse condition_occurrence into 30-day-gap eras (OHDSI algorithm).
WITH target AS (
    SELECT
        condition_occurrence_id,
        person_id,
        condition_concept_id,
        condition_start_date,
        COALESCE(condition_end_date, condition_start_date + INTERVAL 1 DAY) AS condition_end_date
    FROM {{ ref('condition_occurrence') }}
    WHERE condition_concept_id != 0
),
events AS (
    SELECT person_id, condition_concept_id, condition_start_date AS event_date, -1 AS event_type,
           ROW_NUMBER() OVER (PARTITION BY person_id, condition_concept_id ORDER BY condition_start_date) AS start_ordinal
    FROM target
    UNION ALL
    SELECT person_id, condition_concept_id, condition_end_date + INTERVAL 30 DAY AS event_date, 1 AS event_type,
           NULL AS start_ordinal
    FROM target
),
ranked AS (
    SELECT person_id, condition_concept_id, event_date, event_type,
        MAX(start_ordinal) OVER (
            PARTITION BY person_id, condition_concept_id
            ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal,
        ROW_NUMBER() OVER (
            PARTITION BY person_id, condition_concept_id
            ORDER BY event_date, event_type) AS overall_ord
    FROM events
),
ends AS (
    SELECT person_id, condition_concept_id, event_date - INTERVAL 30 DAY AS end_date
    FROM ranked
    WHERE (2 * start_ordinal) - overall_ord = 0
),
era_ends AS (
    SELECT c.person_id, c.condition_concept_id, c.condition_start_date, MIN(e.end_date) AS era_end_date
    FROM target c
    JOIN ends e
        ON c.person_id = e.person_id
        AND c.condition_concept_id = e.condition_concept_id
        AND e.end_date >= c.condition_start_date
    GROUP BY c.person_id, c.condition_concept_id, c.condition_start_date
)
SELECT
    {{ mimic_sk('condition_era', 'person_id, condition_concept_id, era_end_date') }} AS condition_era_id,
    person_id,
    condition_concept_id,
    MIN(condition_start_date)   AS condition_era_start_date,
    era_end_date                AS condition_era_end_date,
    COUNT(*)                    AS condition_occurrence_count
FROM era_ends
GROUP BY person_id, condition_concept_id, era_end_date
