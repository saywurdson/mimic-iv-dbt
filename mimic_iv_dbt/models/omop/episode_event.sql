-- cdm_episode_event: links each ICU episode to its source visit_detail row.
-- episode_source_value carries the visit_detail_id, so event_id recovers it directly (1:1, no join).
SELECT
    e.episode_id,
    CAST(e.episode_source_value AS BIGINT)  AS event_id,
    1147624                                 AS episode_event_field_concept_id  -- visit_detail.visit_detail_id
FROM {{ ref('episode') }} e
