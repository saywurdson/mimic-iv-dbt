# MIMIC-IV → OMOP CDM Pipeline

A dbt + DuckDB pipeline that transforms the [MIMIC-IV](https://physionet.org/content/mimiciv/)
critical-care dataset into the [OHDSI **OMOP Common Data Model** (CDM) v5.4](https://ohdsi.github.io/CommonDataModel/).
It is a faithful, DuckDB-native re-implementation of the OHDSI/MIMIC BigQuery ETL -
the same 5-stage design expressed as composable dbt layers.

> **Data access.** MIMIC-IV is credentialed data. You must complete the
> [PhysioNet](https://physionet.org/) CITI training and data-use agreement before
> downloading it. No patient data is included in this repository.

## Overview

MIMIC-IV's core `hosp` and `icu` modules ship ~30 relational tables; this project
also reads the companion **MIMIC-IV-ED** (emergency department) and MIMIC-IV-Note
datasets. It lands them in DuckDB, cleans and maps them to standard OMOP
vocabularies, and emits 28 OMOP CDM clinical and standardized-vocabulary tables
(the `omop` schema), with the standardized OMOP vocabulary loaded alongside in a
`vocab` schema and a `marts` schema of ready-made clinical KPIs on top - ready for
OHDSI analytics tools (ATLAS, Achilles, HADES) or plain SQL.

### What is OMOP CDM?

The OMOP Common Data Model is an open, person-centric standard for observational
health data. Mapping a source dataset onto OMOP means analyses, cohort
definitions, and quality tools written once can run against *any* OMOP database,
regardless of the originating EHR.

## Architecture

The ETL follows the OHDSI snapshot → clean → concept → mapped → distribute design,
realized as four dbt layers:

```
MIMIC-IV CSVs ─► staging (src_*) ─► intermediate (lk_*) ─► omop (cdm_*) ─► marts
  (*.csv.gz)      1:1 typed views    concept mapping &       OMOP CDM     clinical
                                     business logic          5.4 tables   KPIs
       │                                                          │
       └── OMOP Athena vocabulary (CONCEPT, CONCEPT_RELATIONSHIP, …) ──────┘
```

- **staging** - one model per source table (light typing/renaming). Clinical
  staging materializes into a disposable scratch database; the OMOP vocabulary is
  staged into the deliverable.
- **intermediate** - the heavy lifting: source values are mapped to standard OMOP
  concepts via the Athena vocabulary plus custom seed mappings.
- **omop** - the final CDM 5.4 tables in the `omop` schema.
- **marts** - clinical KPI summary tables (`kpi_*`) in the `marts` schema, built
  on top of the OMOP layer for critical-care reporting (see below).

Staging and intermediate tables are written to a throwaway `mimic_iv_delete`
database (attached at build time) so the deliverable stays lean.

The **MIMIC-IV-ED module** (emergency-department stays, triage, vital signs,
diagnoses, and medications) flows through the same layers — `src_ed_*` staging and
`lk_ed_*` intermediate models — and is unioned into the OMOP `visit_occurrence`
(as Emergency Room visits, concept 9203), `condition_occurrence`, `measurement`,
`drug_exposure`, and `observation` tables.

### Clinical KPIs (`marts` schema)

The `marts` models roll the OMOP tables up into the headline metrics a
critical-care analyst reaches for first. They build with the rest of the DAG and
land in the deliverable database alongside the OMOP tables:

| Mart | What it answers |
|------|-----------------|
| `kpi_cohort_summary` | Patients, hospital admissions, ICU stays, deaths (one row) |
| `kpi_outcomes` | In-hospital & 30-day mortality, 30-day readmission, hospital/ICU length of stay |
| `kpi_demographics` | Patient counts and % by gender, race, and age band |
| `kpi_top_conditions` / `kpi_top_drugs` / `kpi_top_procedures` / `kpi_top_measurements` | Top 25 concepts by distinct patients |
| `kpi_ed_summary` | ED visits, ED patients, ED → inpatient admission rate, median ED length of stay |
| `kpi_ed_breakdowns` | ED stays by triage acuity, disposition, and arrival transport |
| `kpi_ed_chief_complaints` | Top 20 ED chief complaints (free text, as triaged) |
| `kpi_payer_mix` | Hospital admissions and patients by primary insurance (payer) |
| `kpi_top_drg` | Top 25 DRG (Diagnosis Related Group) concepts by distinct patients |
| `kpi_admission_base` / `kpi_patient_base` | Per-admission and per-patient grain the summaries roll up from |

MIMIC-IV de-identifies dates by shifting each patient's events into the future, so
intervals (length of stay, age, readmission gaps) are exact while calendar dates
are not. Patients over 89 are recorded with a de-identified age and are flagged
and capped into the `90+` band.

`kpi_admission_base` is grounded in the MIMIC-IV source tables rather than the
OMOP layer, because that layer loses two distinctions the KPIs need: OMOP
`visit_occurrence` unions real hospital admissions with synthesized no-hadm
outpatient/ED visits (so a "hospital admission" is taken to be a row with a
`hadm_id`), and this ETL's care-unit concept mapping only resolves one ICU unit to
a standard concept (so ICU stays are detected from the source `transfers` care-unit
names - MICU, SICU, CCU, CVICU, TSICU, Neuro SICU, NICU, …).

## Data Sources

| Source | What | Where it goes |
|--------|------|---------------|
| MIMIC-IV relational data | `hosp/` + `icu/` `*.csv.gz` | `staging` → `intermediate` → `omop` |
| MIMIC-IV-ED | `ed/` `*.csv.gz` (edstays, triage, vitalsign, diagnosis, medrecon, pyxis) | `staging` → `intermediate` → `omop` |
| OMOP Athena vocabulary | Standard concept TSVs from [athena.ohdsi.org](https://athena.ohdsi.org) | `vocab` schema, used for mapping |
| Custom seed mappings | `mimic_iv_dbt/seeds/custom/` (incl. `ed_vital_to_concept`, `gsn_to_rxnorm`, `insurance_to_concept`) | source-specific concept fixes |

## OMOP CDM tables produced

`person` · `observation_period` · `visit_occurrence` · `visit_detail` ·
`condition_occurrence` · `drug_exposure` · `procedure_occurrence` ·
`device_exposure` · `measurement` · `observation` · `specimen` · `death` ·
`note` · `condition_era` · `drug_era` · `dose_era` · `fact_relationship` ·
`location` · `care_site` · `provider` · `cdm_source` · `cost` · `episode` ·
`episode_event` · `payer_plan_period` · `note_nlp` · `metadata` ·
`source_to_concept_map`

## Quick Start

### Prerequisites

- [Docker](https://www.docker.com/) (the dev container is the supported path), or
  local Python ≥3.11 with [`uv`](https://docs.astral.sh/uv/)
- A PhysioNet account with MIMIC-IV access
- OMOP Athena vocabulary bundle

### 1. Open in the dev container (recommended)

Open the repo in VS Code and **"Reopen in Container"**. The container builds from
the lean `Dockerfile`, runs `uv sync` to create `.venv`, and registers the
terminology MCP server. Alternatively, build the image directly:

```bash
docker build -t mimic-iv-dbt .
docker run -it --rm -v "$PWD":/workspaces/mimic-iv-dbt mimic-iv-dbt
```

### 2. Set up the Python environment

```bash
uv sync          # creates .venv from pyproject.toml + uv.lock
```

### 3. Configure paths

```bash
cp .env.example .env          # then edit to match your data locations
set -a && source .env && set +a
```

Defaults assume data under `data/` inside the container; override `MIMIC_IV_PATH`,
`OMOP_VOCAB_PATH`, and `MIMIC_IV_DB_PATH` as needed.

### 4. Load source data

Download MIMIC-IV (`*.csv.gz`) into `MIMIC_IV_PATH` and the Athena vocabulary TSVs
into `OMOP_VOCAB_PATH`. The helper script stages MIMIC-IV CSVs into DuckDB:

```bash
uv run python mimiciv.py
```

### 5. Build the OMOP CDM with dbt

```bash
uv run dbt build --project-dir mimic_iv_dbt        # run + test everything
# or selectively:
uv run dbt run  --project-dir mimic_iv_dbt --select staging
uv run dbt run  --project-dir mimic_iv_dbt --select omop
uv run dbt run  --project-dir mimic_iv_dbt --select marts   # KPI summaries (needs omop)
```

### 6. Explore the result

```bash
uv run streamlit run dashboard.py                  # http://localhost:8501
```

The dashboard reads the `marts.kpi_*` tables and renders cohort size, outcomes
(mortality, readmission, length of stay), demographics, the most common
conditions, drugs, procedures, and measurements, plus Emergency Department flow
(triage acuity, disposition, arrival transport, chief complaints) and payer/DRG
billing breakdowns. You can also query the OMOP and `marts` tables directly in
DuckDB (e.g. `SELECT * FROM marts.kpi_outcomes`).

## Project structure

```
mimic-iv-dbt/
├── Dockerfile               # lean python + duckdb + dbt + uv image
├── .devcontainer/           # VS Code dev container definition
├── .mcp.json                # dbt MCP server for Claude Code
├── pyproject.toml / uv.lock # pinned Python dependencies (uv)
├── .env.example             # path configuration template
├── mimiciv.py               # loads MIMIC-IV CSVs into DuckDB
├── dashboard.py             # Streamlit OMOP explorer
└── mimic_iv_dbt/            # the dbt project
    ├── dbt_project.yml
    ├── profiles.yml         # DuckDB target (paths via env_var)
    ├── models/
    │   ├── staging/         # src_* (mimic) + vocabulary
    │   ├── intermediate/    # lk_* concept mapping
    │   ├── omop/            # cdm_* OMOP CDM 5.4 tables
    │   └── marts/           # kpi_* clinical summary tables
    ├── seeds/custom/        # custom concept mappings
    ├── macros/  tests/  snapshots/  analyses/
```

## Key engineering features

- **DuckDB-native OHDSI ETL** - runs the full MIMIC-IV → OMOP mapping locally,
  no cloud warehouse required.
- **Analytics-ready KPI marts** - critical-care metrics (mortality, length of
  stay, readmission, demographics, top concepts), emergency-department flow, and
  payer/DRG billing modeled in dbt and surfaced in a Streamlit dashboard.
- **Layered dbt design** with a disposable scratch database so the published
  OMOP database carries only the deliverable.
- **Portable configuration** - all data and database paths resolve through
  `env_var()`, so the same project runs in the container, in CI, or on a laptop.
- **Reproducible environment** - pinned via `uv`, containerized, dev-container ready.

## Technologies

dbt · DuckDB · OMOP CDM 5.4 · OHDSI vocabularies · Python · uv · Streamlit · Plotly

## License

See [LICENSE](LICENSE).
