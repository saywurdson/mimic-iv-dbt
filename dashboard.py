"""Starter Streamlit dashboard for the MIMIC-IV -> OMOP CDM database.

Connects read-only to the DuckDB built by dbt and renders a handful of standard
OMOP CDM views (cohort size, demographics, visits over time, top concepts).
Concept names are resolved against the `vocab.concept` table when present and
fall back to raw concept ids otherwise, so the dashboard works even before the
vocabulary is loaded.

Run:  uv run streamlit run dashboard.py
"""

from __future__ import annotations

import os
from pathlib import Path

import duckdb
import pandas as pd
import plotly.express as px
import streamlit as st
from dotenv import load_dotenv

load_dotenv()

DATASET = "MIMIC-IV"
OMOP_SCHEMA = "omop"
VOCAB_SCHEMA = "vocab"
REPO_ROOT = Path(__file__).resolve().parent
DB_PATH = os.environ.get("MIMIC_IV_DB_PATH") or str(REPO_ROOT / "mimic_iv_omop.db")

st.set_page_config(page_title=f"{DATASET} OMOP Explorer", page_icon="🏥", layout="wide")


@st.cache_resource
def get_connection(path: str) -> duckdb.DuckDBPyConnection:
    return duckdb.connect(path, read_only=True)


@st.cache_data
def run_query(path: str, sql: str) -> pd.DataFrame:
    return get_connection(path).execute(sql).fetchdf()


def table_exists(path: str, schema: str, table: str) -> bool:
    df = run_query(
        path,
        f"""
        SELECT 1
        FROM information_schema.tables
        WHERE lower(table_schema) = lower('{schema}')
          AND lower(table_name) = lower('{table}')
        LIMIT 1
        """,
    )
    return not df.empty


def row_count(path: str, table: str) -> int | None:
    if not table_exists(path, OMOP_SCHEMA, table):
        return None
    return int(run_query(path, f"SELECT count(*) AS n FROM {OMOP_SCHEMA}.{table}")["n"][0])


def concept_label_expr(id_column: str, has_vocab: bool) -> str:
    """Return a SQL expression mapping a *_concept_id column to a display label."""
    if has_vocab:
        return f"coalesce(c.concept_name, 'concept ' || {id_column}::VARCHAR)"
    return f"'concept ' || {id_column}::VARCHAR"


def top_concepts(path: str, table: str, id_column: str, has_vocab: bool, limit: int = 10) -> pd.DataFrame:
    label = concept_label_expr(f"t.{id_column}", has_vocab)
    join = (
        f"LEFT JOIN {VOCAB_SCHEMA}.concept c ON c.concept_id = t.{id_column}"
        if has_vocab
        else ""
    )
    return run_query(
        path,
        f"""
        SELECT {label} AS concept, count(*) AS records
        FROM {OMOP_SCHEMA}.{table} t
        {join}
        WHERE t.{id_column} IS NOT NULL AND t.{id_column} <> 0
        GROUP BY 1
        ORDER BY records DESC
        LIMIT {limit}
        """,
    )


# ---------------------------------------------------------------------------- UI
st.title(f"🏥 {DATASET} → OMOP CDM 5.4 Explorer")
st.caption(f"DuckDB: `{DB_PATH}`  ·  schema: `{OMOP_SCHEMA}`")

if not Path(DB_PATH).exists():
    st.error(
        f"Database not found at `{DB_PATH}`.\n\n"
        "Build it first with `uv run dbt build --project-dir mimic_iv_dbt`, "
        "or point `MIMIC_IV_DB_PATH` at an existing OMOP database."
    )
    st.stop()

has_vocab = table_exists(DB_PATH, VOCAB_SCHEMA, "concept")
if not has_vocab:
    st.info("`vocab.concept` not found — showing raw concept ids instead of names.")

# --- KPI row ---------------------------------------------------------------
kpis = {
    "Persons": "person",
    "Visits": "visit_occurrence",
    "Conditions": "condition_occurrence",
    "Drug exposures": "drug_exposure",
    "Measurements": "measurement",
    "Procedures": "procedure_occurrence",
}
cols = st.columns(len(kpis))
for col, (label, table) in zip(cols, kpis.items()):
    n = row_count(DB_PATH, table)
    col.metric(label, f"{n:,}" if n is not None else "—")

st.divider()

# --- Demographics ----------------------------------------------------------
left, right = st.columns(2)

with left:
    st.subheader("Patients by gender")
    if table_exists(DB_PATH, OMOP_SCHEMA, "person"):
        label = concept_label_expr("p.gender_concept_id", has_vocab)
        join = (
            f"LEFT JOIN {VOCAB_SCHEMA}.concept c ON c.concept_id = p.gender_concept_id"
            if has_vocab
            else ""
        )
        gender = run_query(
            DB_PATH,
            f"""
            SELECT {label} AS gender, count(*) AS patients
            FROM {OMOP_SCHEMA}.person p
            {join}
            GROUP BY 1 ORDER BY patients DESC
            """,
        )
        st.plotly_chart(px.pie(gender, names="gender", values="patients", hole=0.4),
                        use_container_width=True)
    else:
        st.write("No `person` table.")

with right:
    st.subheader("Patients by year of birth")
    if table_exists(DB_PATH, OMOP_SCHEMA, "person"):
        yob = run_query(
            DB_PATH,
            f"""
            SELECT year_of_birth AS year, count(*) AS patients
            FROM {OMOP_SCHEMA}.person
            WHERE year_of_birth IS NOT NULL
            GROUP BY 1 ORDER BY 1
            """,
        )
        st.plotly_chart(px.bar(yob, x="year", y="patients"), use_container_width=True)
    else:
        st.write("No `person` table.")

# --- Visits over time ------------------------------------------------------
st.subheader("Visits per year")
if table_exists(DB_PATH, OMOP_SCHEMA, "visit_occurrence"):
    visits = run_query(
        DB_PATH,
        f"""
        SELECT extract('year' FROM visit_start_date) AS year, count(*) AS visits
        FROM {OMOP_SCHEMA}.visit_occurrence
        WHERE visit_start_date IS NOT NULL
        GROUP BY 1 ORDER BY 1
        """,
    )
    st.plotly_chart(px.line(visits, x="year", y="visits", markers=True),
                    use_container_width=True)
else:
    st.write("No `visit_occurrence` table.")

# --- Top concepts ----------------------------------------------------------
st.divider()
top_specs = [
    ("Top conditions", "condition_occurrence", "condition_concept_id"),
    ("Top drugs", "drug_exposure", "drug_concept_id"),
    ("Top measurements", "measurement", "measurement_concept_id"),
]
for title, table, id_col in top_specs:
    st.subheader(title)
    if table_exists(DB_PATH, OMOP_SCHEMA, table):
        df = top_concepts(DB_PATH, table, id_col, has_vocab)
        st.plotly_chart(
            px.bar(df.sort_values("records"), x="records", y="concept", orientation="h"),
            use_container_width=True,
        )
    else:
        st.write(f"No `{table}` table.")
