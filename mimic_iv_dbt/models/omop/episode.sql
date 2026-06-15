-- cdm_episode: one episode per ICU stay (visit_detail rows whose care_site is an ICU careunit).
-- ICU stay is the chosen episode granularity; object = Intensive Care, type = EHR.
SELECT
    {{ mimic_sk('episode', 'vd.visit_detail_id') }} AS episode_id,
    vd.person_id,
    32533                                   AS episode_concept_id,        -- Episode (domain)
    vd.visit_detail_start_date              AS episode_start_date,
    vd.visit_detail_start_datetime          AS episode_start_datetime,
    vd.visit_detail_end_date                AS episode_end_date,
    vd.visit_detail_end_datetime            AS episode_end_datetime,
    CAST(NULL AS BIGINT)                    AS episode_parent_id,
    CAST(NULL AS BIGINT)                    AS episode_number,
    32037                                   AS episode_object_concept_id, -- Intensive Care
    32817                                   AS episode_type_concept_id,    -- EHR
    CAST(vd.visit_detail_id AS VARCHAR)     AS episode_source_value,       -- the ICU-stay visit_detail_id
    0                                       AS episode_source_concept_id
FROM {{ ref('visit_detail') }} vd
INNER JOIN {{ ref('care_site') }} cs ON cs.care_site_id = vd.care_site_id
WHERE cs.care_site_source_value ILIKE '%intensive care%'
   OR cs.care_site_source_value ILIKE '%coronary care%'
   OR cs.care_site_source_value ILIKE '%ICU%'   -- catches 'Trauma SICU (TSICU)' etc.
