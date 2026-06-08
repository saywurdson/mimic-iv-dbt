# MIMIC-IV → OMOP CDM Pipeline

A dbt + DuckDB pipeline that transforms the [MIMIC-IV](https://physionet.org/content/mimiciv/)
critical-care dataset into the [OHDSI **OMOP Common Data Model** (CDM) v5.4](https://ohdsi.github.io/CommonDataModel/).
It is a faithful, DuckDB-native re-implementation of the OHDSI/MIMIC BigQuery ETL —
the same 5-stage design expressed as composable dbt layers.

> ⚠️ **Data access.** MIMIC-IV is credentialed data. You must complete the
> [PhysioNet](https://physionet.org/) CITI training and data-use agreement before
> downloading it. No patient data is included in this repository.

## Overview

MIMIC-IV ships as ~30 relational tables across two modules (`hosp`, `icu`). This
project lands them in DuckDB, cleans and maps them to standard OMOP vocabularies,
and emits the 21 OMOP CDM clinical and standardized-vocabulary tables — ready for
OHDSI analytics tools (ATLAS, Achilles, HADES) or plain SQL.

### What is OMOP CDM?

The OMOP Common Data Model is an open, person-centric standard for observational
health data. Mapping a source dataset onto OMOP means analyses, cohort
definitions, and quality tools written once can run against *any* OMOP database,
regardless of the originating EHR.

## Architecture

The ETL follows the OHDSI snapshot → clean → concept → mapped → distribute design,
realized as three dbt layers:

```
MIMIC-IV CSVs ──► staging (src_*)  ──► intermediate (lk_*) ──► omop (cdm_*)
  (*.csv.gz)       1:1 typed views     concept mapping &        OMOP CDM 5.4
                                       business logic           tables
       │                                                              │
       └── OMOP Athena vocabulary (CONCEPT, CONCEPT_RELATIONSHIP, …) ──┘
```

- **staging** — one model per source table (light typing/renaming). Clinical
  staging materializes into a disposable scratch database; the OMOP vocabulary is
  staged into the deliverable.
- **intermediate** — the heavy lifting: source values are mapped to standard OMOP
  concepts via the Athena vocabulary plus custom seed mappings.
- **omop** — the final CDM 5.4 tables in the `omop` schema.

Staging and intermediate tables are written to a throwaway `mimic_iv_delete`
database (attached at build time) so the deliverable stays lean.

## Data Sources

| Source | What | Where it goes |
|--------|------|---------------|
| MIMIC-IV relational data | `hosp/` + `icu/` `*.csv.gz` | `staging` → `intermediate` → `omop` |
| OMOP Athena vocabulary | Standard concept TSVs from [athena.ohdsi.org](https://athena.ohdsi.org) | `vocab` schema, used for mapping |
| Custom seed mappings | `mimic_iv_dbt/seeds/custom/` | source-specific concept fixes |

## OMOP CDM tables produced

`person` · `observation_period` · `visit_occurrence` · `visit_detail` ·
`condition_occurrence` · `drug_exposure` · `procedure_occurrence` ·
`device_exposure` · `measurement` · `observation` · `specimen` · `death` ·
`note` · `condition_era` · `drug_era` · `dose_era` · `fact_relationship` ·
`location` · `care_site` · `provider` · `cdm_source`

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
```

### 6. Explore the result

```bash
uv run streamlit run dashboard.py                  # http://localhost:8501
```

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
    │   └── omop/            # cdm_* OMOP CDM 5.4 tables
    ├── seeds/custom/        # custom concept mappings
    ├── macros/  tests/  snapshots/  analyses/
```

## Key engineering features

- **DuckDB-native OHDSI ETL** — runs the full MIMIC-IV → OMOP mapping locally,
  no cloud warehouse required.
- **Layered dbt design** with a disposable scratch database so the published
  OMOP database carries only the deliverable.
- **Portable configuration** — all data and database paths resolve through
  `env_var()`, so the same project runs in the container, in CI, or on a laptop.
- **Reproducible environment** — pinned via `uv`, containerized, dev-container ready.

## Technologies

dbt · DuckDB · OMOP CDM 5.4 · OHDSI vocabularies · Python · uv · Streamlit · Plotly

## License

See [LICENSE](LICENSE).
