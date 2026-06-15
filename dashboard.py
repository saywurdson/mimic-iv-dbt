"""Streamlit dashboard for the MIMIC-IV -> OMOP CDM database.

Connects read-only to the DuckDB built by dbt and renders the clinical KPI marts
(the `marts.kpi_*` tables) as critical-care summary views: cohort size, outcomes
(mortality, readmission, length of stay), demographics, the most common
conditions, drugs, procedures, and measurements, plus Emergency Department flow
(visits, triage acuity, disposition, chief complaints) and payer/DRG billing
breakdowns sourced from the MIMIC-IV-ED module and the cost/payer OMOP tables.

The marts pre-compute every aggregate, so this app only reads small summary
tables rather than scanning the raw OMOP clinical tables. Build them with
`uv run python mimiciv.py build` (or `dbt build --select marts` if the OMOP
layer already exists).

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
MARTS_SCHEMA = "marts"
REPO_ROOT = Path(__file__).resolve().parent
DB_PATH = os.environ.get("MIMIC_IV_DB_PATH") or str(REPO_ROOT / "mimic_iv_omop.db")

# Display order for the age bands produced by kpi_admission_base.
AGE_BAND_ORDER = ["0 (neonate)", "1-17", "18-44", "45-64", "65-89", "90+"]

st.set_page_config(page_title=f"{DATASET} OMOP Explorer", layout="wide")


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


def mart(path: str, name: str) -> pd.DataFrame:
    """Read a marts.kpi_* table, or return an empty frame if it is missing."""
    if not table_exists(path, MARTS_SCHEMA, name):
        return pd.DataFrame()
    return run_query(path, f"SELECT * FROM {MARTS_SCHEMA}.{name}")


def fmt(value: float, unit: str) -> str:
    if unit == "percent":
        return f"{value:.1f}%"
    if unit == "days":
        return f"{value:.1f} d"
    return f"{value:g}"


def top_concept_chart(path: str, name: str, title: str, limit: int = 15) -> None:
    st.subheader(title)
    df = mart(path, name)
    if df.empty:
        st.write(f"`{MARTS_SCHEMA}.{name}` not found.")
        return
    df = df.sort_values("n_patients", ascending=False).head(limit)
    fig = px.bar(
        df.sort_values("n_patients"),
        x="n_patients",
        y="concept_name",
        orientation="h",
        labels={"n_patients": "patients", "concept_name": ""},
    )
    st.plotly_chart(fig, width="stretch")


# UI -------------------------------------------------------------------------
st.title(f"{DATASET} OMOP CDM 5.4 Explorer")
st.caption(f"DuckDB: `{DB_PATH}`  schema: `{MARTS_SCHEMA}`")

if not Path(DB_PATH).exists():
    st.error(
        f"Database not found at `{DB_PATH}`.\n\n"
        "Build it first with `uv run python mimiciv.py build`, "
        "or point `MIMIC_IV_DB_PATH` at an existing OMOP database."
    )
    st.stop()

if not table_exists(DB_PATH, MARTS_SCHEMA, "kpi_cohort_summary"):
    st.error(
        "The `marts` KPI tables were not found in this database.\n\n"
        "Build them with `uv run python mimiciv.py build` "
        "(or `dbt build --select marts` if the OMOP layer already exists)."
    )
    st.stop()

st.caption(
    "MIMIC-IV is critical-care data, de-identified by shifting each patient's "
    "dates into the future, so length-of-stay, age, and readmission intervals are "
    "exact while calendar dates are not. Patients over 89 are shown as the `90+` "
    "age band."
)

# Headline KPI cards ---------------------------------------------------------
cohort = mart(DB_PATH, "kpi_cohort_summary").iloc[0]
outcomes = mart(DB_PATH, "kpi_outcomes")
o = {row.metric: (row.value, row.unit) for row in outcomes.itertuples()}

cards = [
    ("Patients", f"{int(cohort.n_patients):,}"),
    ("Hospital admissions", f"{int(cohort.n_hospital_admissions):,}"),
    ("ICU stays", f"{int(cohort.n_icu_stays):,}"),
    ("Deaths", f"{int(cohort.n_deaths):,}"),
    ("In-hospital mortality", fmt(*o["in_hospital_mortality_rate"]) if "in_hospital_mortality_rate" in o else "N/A"),
    ("30-day readmission", fmt(*o["30_day_readmission_rate"]) if "30_day_readmission_rate" in o else "N/A"),
]
for col, (label, value) in zip(st.columns(len(cards)), cards):
    col.metric(label, value)

st.divider()

# Outcomes -------------------------------------------------------------------
st.subheader("Outcomes")
rate_keys = [
    ("in_hospital_mortality_rate", "In-hospital mortality"),
    ("30_day_mortality_rate", "30-day mortality"),
    ("30_day_readmission_rate", "30-day readmission"),
    ("admissions_with_icu_pct", "Admissions with ICU"),
]
rate_cols = st.columns(len(rate_keys))
for col, (key, label) in zip(rate_cols, rate_keys):
    col.metric(label, fmt(*o[key]) if key in o else "N/A")

st.markdown("**Length of stay** (median with interquartile range)")
los_rows = []
for stay, prefix in [("Hospital", "hospital_los"), ("ICU", "icu_los")]:
    if f"{prefix}_median" in o:
        los_rows.append(
            {
                "stay": stay,
                "median": o[f"{prefix}_median"][0],
                "p25": o[f"{prefix}_p25"][0],
                "p75": o[f"{prefix}_p75"][0],
            }
        )
if los_rows:
    los = pd.DataFrame(los_rows)
    los["err_plus"] = los["p75"] - los["median"]
    los["err_minus"] = los["median"] - los["p25"]
    fig = px.bar(
        los,
        x="median",
        y="stay",
        orientation="h",
        labels={"median": "days", "stay": ""},
        error_x="err_plus",
        error_x_minus="err_minus",
    )
    st.plotly_chart(fig, width="stretch")

st.divider()

# Demographics ---------------------------------------------------------------
demo = mart(DB_PATH, "kpi_demographics")
st.subheader("Demographics")
left, mid, right = st.columns(3)

with left:
    st.markdown("**Gender**")
    g = demo[demo["dimension"] == "gender"]
    if not g.empty:
        st.plotly_chart(
            px.pie(g, names="category", values="n_patients", hole=0.4),
            width="stretch",
        )

with mid:
    st.markdown("**Age band**")
    a = demo[demo["dimension"] == "age_band"]
    if not a.empty:
        st.plotly_chart(
            px.bar(
                a,
                x="category",
                y="n_patients",
                labels={"category": "", "n_patients": "patients"},
                category_orders={"category": AGE_BAND_ORDER},
            ),
            width="stretch",
        )

with right:
    st.markdown("**Race (top 10)**")
    r = demo[demo["dimension"] == "race"].sort_values("n_patients", ascending=False).head(10)
    if not r.empty:
        st.plotly_chart(
            px.bar(
                r.sort_values("n_patients"),
                x="n_patients",
                y="category",
                orientation="h",
                labels={"n_patients": "patients", "category": ""},
            ),
            width="stretch",
        )

st.divider()

# Most common clinical concepts ---------------------------------------------
c1, c2 = st.columns(2)
with c1:
    top_concept_chart(DB_PATH, "kpi_top_conditions", "Top conditions")
    top_concept_chart(DB_PATH, "kpi_top_procedures", "Top procedures")
with c2:
    top_concept_chart(DB_PATH, "kpi_top_drugs", "Top drugs")
    top_concept_chart(DB_PATH, "kpi_top_measurements", "Top measurements")

st.divider()

# Emergency Department -------------------------------------------------------
# Sourced from the MIMIC-IV-ED module (kpi_ed_* marts). The whole section is
# skipped with a hint when those marts are absent (e.g. the ED source data was
# not present at build time), so the rest of the dashboard still renders.
st.subheader("Emergency Department")
ed_summary = mart(DB_PATH, "kpi_ed_summary")
if ed_summary.empty:
    st.info(
        "ED marts not found. They come from the MIMIC-IV-ED module — rebuild with "
        "`uv run python mimiciv.py build` once `data/mimiciv/ed/` is present."
    )
else:
    e = ed_summary.iloc[0]
    ed_cards = [
        ("ED visits", f"{int(e.n_ed_visits):,}"),
        ("ED patients", f"{int(e.n_ed_patients):,}"),
        ("ED → inpatient", f"{int(e.n_ed_to_inpatient):,}"),
        ("ED → inpatient rate", fmt(e.ed_to_inpatient_pct, "percent") if pd.notna(e.ed_to_inpatient_pct) else "N/A"),
        ("Median ED stay", f"{e.ed_los_hours_median:.1f} h" if pd.notna(e.ed_los_hours_median) else "N/A"),
    ]
    for col, (label, value) in zip(st.columns(len(ed_cards)), ed_cards):
        col.metric(label, value)

    breakdowns = mart(DB_PATH, "kpi_ed_breakdowns")
    b1, b2, b3 = st.columns(3)

    with b1:
        st.markdown("**Triage acuity** (1 = most urgent)")
        a = breakdowns[breakdowns["dimension"] == "acuity"].sort_values("category")
        if not a.empty:
            st.plotly_chart(
                px.bar(
                    a,
                    x="category",
                    y="n_visits",
                    labels={"category": "acuity", "n_visits": "ED stays"},
                ),
                width="stretch",
            )

    with b2:
        st.markdown("**Disposition**")
        d = breakdowns[breakdowns["dimension"] == "disposition"]
        if not d.empty:
            st.plotly_chart(
                px.pie(d, names="category", values="n_visits", hole=0.4),
                width="stretch",
            )

    with b3:
        st.markdown("**Arrival transport**")
        t = breakdowns[breakdowns["dimension"] == "arrival_transport"]
        if not t.empty:
            st.plotly_chart(
                px.pie(t, names="category", values="n_visits", hole=0.4),
                width="stretch",
            )

    st.markdown("**Top chief complaints**")
    cc = mart(DB_PATH, "kpi_ed_chief_complaints")
    if cc.empty:
        st.write(f"`{MARTS_SCHEMA}.kpi_ed_chief_complaints` not found.")
    else:
        cc = cc.sort_values("n_visits", ascending=False).head(15)
        st.plotly_chart(
            px.bar(
                cc.sort_values("n_visits"),
                x="n_visits",
                y="chief_complaint",
                orientation="h",
                labels={"n_visits": "ED stays", "chief_complaint": ""},
            ),
            width="stretch",
        )

st.divider()

# Payer mix and DRG billing --------------------------------------------------
p1, p2 = st.columns(2)

with p1:
    st.subheader("Payer mix")
    st.caption("Share of hospital admissions by primary insurance.")
    payer = mart(DB_PATH, "kpi_payer_mix")
    if payer.empty:
        st.write(f"`{MARTS_SCHEMA}.kpi_payer_mix` not found.")
    else:
        st.plotly_chart(
            px.pie(payer, names="payer", values="n_admissions", hole=0.4),
            width="stretch",
        )

with p2:
    top_concept_chart(DB_PATH, "kpi_top_drg", "Top DRGs")
