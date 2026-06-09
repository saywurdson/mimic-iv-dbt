{{ config(materialized='table') }}

/* Top 25 measurement (lab / vital) concepts by distinct patient count. */

{{ top_concepts('measurement', 'measurement_concept_id') }}
