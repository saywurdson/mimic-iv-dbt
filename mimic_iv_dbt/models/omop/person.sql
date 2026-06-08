-- cdm_person (final): keep only persons with an observation_period row (drops event-less patients).
SELECT per.*
FROM {{ ref('cdm_person_all') }} per
INNER JOIN {{ ref('observation_period') }} op
    ON per.person_id = op.person_id
