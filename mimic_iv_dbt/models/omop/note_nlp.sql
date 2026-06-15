-- cdm_note_nlp: dictionary-NER clinical-term extraction over omop.note, built in ONE pass.
-- Term dictionary = standard OMOP clinical concepts (single-token names); a simple lexical
-- negation (a cue within the 3 preceding tokens) sets term_exists. No batching, no external
-- artifact: dbt materializes this as CREATE TABLE omop.note_nlp AS (...). For the full ~2.6M
-- note corpus, run the build with --threads 2 so the tokenization stays within memory.
WITH dict AS (
    SELECT lower(concept_name) AS term, MIN(concept_id) AS concept_id
    FROM {{ ref('concept') }}
    WHERE standard_concept = 'S'
      AND domain_id IN ('Condition', 'Drug', 'Procedure', 'Observation', 'Measurement', 'Device')
      AND length(concept_name) BETWEEN 4 AND 40
      AND concept_name NOT LIKE '% %'
      AND lower(concept_name) NOT IN (
          'history','normal','other','none','blood','daily','right','left','small','large',
          'study','status','review','recent','stable','clear','rate','noted','total','test',
          'line','care','unit','room','time','date','name','female','male','present','past',
          'today','given','change','follow','continue','patient','family','home','admit',
          'with','known','using','within','well','seen','also','since','being','prior',
          'technique','scale','very','much','each','this','that','these','those','good'
      )
    GROUP BY 1
),
batch AS (
    SELECT n.note_id, regexp_split_to_array(lower(n.note_text), '[^a-z0-9]+') AS arr
    FROM {{ ref('note') }} n
    WHERE n.note_text IS NOT NULL
),
toks AS (
    SELECT note_id, unnest(arr) AS tok, unnest(range(1, len(arr) + 1)) AS idx
    FROM batch
),
neg_idx AS (
    SELECT note_id, idx FROM toks
    WHERE tok IN ('no','not','denies','denied','without','negative','absence','neg','never','none','r/o')
),
matches AS (
    SELECT t.note_id, t.idx, t.tok AS lexical_variant, d.concept_id,
        CASE WHEN EXISTS (
            SELECT 1 FROM neg_idx g
            WHERE g.note_id = t.note_id AND g.idx BETWEEN t.idx - 3 AND t.idx - 1
        ) THEN 'N' ELSE 'Y' END AS term_exists
    FROM toks t
    JOIN dict d ON d.term = t.tok
)
SELECT
    (note_id * 1000000 + idx)               AS note_nlp_id,   -- idx unique per note -> collision-free
    note_id,
    0                                       AS section_concept_id,
    lexical_variant                         AS snippet,
    CAST(idx AS VARCHAR)                    AS "offset",
    lexical_variant,
    concept_id                              AS note_nlp_concept_id,
    0                                       AS note_nlp_source_concept_id,
    'duckdb-dictionary-ner'                 AS nlp_system,
    CURRENT_DATE                            AS nlp_date,
    CURRENT_TIMESTAMP                       AS nlp_datetime,
    term_exists,
    CAST(NULL AS VARCHAR)                   AS term_temporal,
    CAST(NULL AS VARCHAR)                   AS term_modifiers
FROM matches
