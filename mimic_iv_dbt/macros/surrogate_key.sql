{#
    Surrogate-key allocation (deterministic), replacing the OHDSI repo's
    FARM_FINGERPRINT(GENERATE_UUID()) which is non-deterministic.

    Each "generator" gets a disjoint 1e9-wide band, with rows numbered inside it
    by row_number() over a deterministic order column. The largest MIMIC-IV table
    (chartevents ~313M rows) fits comfortably in a 1e9 band, so ids never collide
    across generators. This keeps FK joins stable and runs reproducible.

    Cross-table FKs are still resolved by joining id-authority intermediate models
    on natural keys / source_value (person via person_source_value, visit via
    subject|hadm composite source_value), exactly as the repo does -- the
    deterministic SK only guarantees a stable PK per row.

    Usage:  {{ mimic_sk('labevents', 'labevent_id') }}
#}

{% macro _sk_bands() %}
    {% set bands = {
        'patients': 1, 'care_site': 2, 'visit_occurrence': 3, 'visit_detail': 4,
        'condition_occurrence': 5, 'procedure_occurrence': 6, 'observation': 7,
        'drug_exposure': 8, 'device_exposure': 9,
        'labevents': 10, 'chartevents': 11, 'outputevents': 12,
        'specimen': 13, 'meas_organism': 14, 'meas_ab': 15,
        'observation_period': 16, 'condition_era': 17, 'drug_era': 18, 'dose_era': 19,
        'provider': 20, 'note': 21
    } %}
    {{ return(bands) }}
{% endmacro %}

{% macro mimic_sk(generator, order_by='1') %}
    {%- set bands = _sk_bands() -%}
    {%- if generator not in bands -%}
        {{ exceptions.raise_compiler_error("Unknown surrogate-key generator: " ~ generator) }}
    {%- endif -%}
    {%- set base = bands[generator] * 1000000000 -%}
    (CAST({{ base }} AS BIGINT) + row_number() OVER (ORDER BY {{ order_by }}))
{%- endmacro %}
