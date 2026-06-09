"""Download the MIMIC-IV source files the dbt project reads.

The dbt models read the raw gzipped CSVs straight off disk via the
`read_mimic4` macro, which expects a flat per-module layout:

    <MIMIC_IV_PATH>/<module>/<table>.csv.gz

This script fetches exactly the modules the project uses and lays them out
that way. It downloads nothing else:

  * dbt seeds (mimic_iv_dbt/seeds/custom/custom_mapping.csv) ship in the repo
    and are loaded by `dbt seed` / `dbt build` -- not downloaded here.
  * The OMOP Athena vocabulary (OMOP_VOCAB_PATH) is a license-gated manual
    download from athena.ohdsi.org and cannot be scripted; see the README.

Requires a PhysioNet account with MIMIC-IV credentialed access. Credentials are
read from PHYSIONET_USER / PHYSIONET_PASSWORD (e.g. in .env) if set; otherwise
you are prompted for them at runtime.

Usage:
    python mimiciv.py download   # download the MIMIC-IV source files only
    python mimiciv.py build      # build the OMOP CDM with dbt (files must exist)
    python mimiciv.py all        # download then build (default)
"""

import os
import glob
import shutil
import argparse
import subprocess
import concurrent.futures
from getpass import getpass
from urllib.parse import urlparse

from dotenv import load_dotenv

# Pick up MIMIC_IV_PATH (and any credentials) from .env so paths match dbt.
load_dotenv()

# Where dbt looks for source data -- keep this default in sync with
# mimic_iv_dbt/dbt_project.yml (var: mimic4_path) and .env.example.
MIMIC_IV_PATH = os.environ.get(
    "MIMIC_IV_PATH", "/workspaces/mimic-iv-dbt/data/mimiciv"
)

# Where dbt looks for the OMOP Athena vocabulary -- keep in sync with
# mimic_iv_dbt/dbt_project.yml (var: vocab_path) and .env.example.
OMOP_VOCAB_PATH = os.environ.get(
    "OMOP_VOCAB_PATH", "/workspaces/mimic-iv-dbt/mimic_iv_dbt/data"
)

# The dbt project directory; profiles.yml lives here too.
DBT_PROJECT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mimic_iv_dbt")

# Dataset versions on PhysioNet (override via env if you need a different one).
MIMIC_IV_VERSION = os.environ.get("MIMIC_IV_VERSION", "3.1")
MIMIC_IV_NOTE_VERSION = os.environ.get("MIMIC_IV_NOTE_VERSION", "2.2")

PHYSIONET = "https://physionet.org/files"

# Only the modules the dbt staging models actually read:
#   hosp + icu  -> the core `mimiciv` dataset
#   note        -> the separate `mimic-iv-note` dataset (discharge, radiology)
# The `ed` module is intentionally omitted -- nothing references it.
MODULES = [
    {"module": "hosp", "url": f"{PHYSIONET}/mimiciv/{MIMIC_IV_VERSION}/hosp/"},
    {"module": "icu", "url": f"{PHYSIONET}/mimiciv/{MIMIC_IV_VERSION}/icu/"},
    {"module": "note", "url": f"{PHYSIONET}/mimic-iv-note/{MIMIC_IV_NOTE_VERSION}/note/"},
]


def download_module(module, url, username, password):
    """Recursively fetch a module's *.csv.gz into <MIMIC_IV_PATH>/<module>/.

    Uses wget with --cut-dirs so the PhysioNet path prefix
    (files/<dataset>/<version>/<module>/) is stripped and files land flat in
    the target directory, which is what `read_mimic4` expects.
    """
    target = os.path.join(MIMIC_IV_PATH, module)

    if glob.glob(os.path.join(target, "*.csv.gz")):
        print(f"[{module}] already present in {target}, skipping.")
        return

    os.makedirs(target, exist_ok=True)

    # Strip every path segment of the URL (files/<dataset>/<version>/<module>)
    # so downloaded files sit directly under `target`.
    cut_dirs = len([p for p in urlparse(url).path.split("/") if p])

    command = [
        "wget",
        "-r",                  # recurse into the module directory
        "-N",                  # only re-fetch if newer (idempotent)
        "-c",                  # continue partial downloads
        "-np",                 # never ascend to the parent directory
        "-nH",                 # drop the physionet.org host directory
        f"--cut-dirs={cut_dirs}",
        "-P", target,          # output root
        "-A", "*.csv.gz",      # accept only the data files
        "-R", "index.html*",   # never keep directory index pages
    ]
    if username and password:
        command += ["--user", username, "--password", password]
    command.append(url)

    print(f"[{module}] downloading from {url} -> {target}")
    subprocess.run(command, check=True)


def need_download():
    """True if any required module is missing its *.csv.gz files."""
    return any(
        not glob.glob(os.path.join(MIMIC_IV_PATH, m["module"], "*.csv.gz"))
        for m in MODULES
    )


def download():
    """Download every required MIMIC-IV module into MIMIC_IV_PATH."""
    if shutil.which("wget") is None:
        raise SystemExit("wget is required but was not found on PATH.")

    print(f"MIMIC-IV target directory: {MIMIC_IV_PATH}")

    username = password = None
    if need_download():
        # Use PHYSIONET_USER / PHYSIONET_PASSWORD from .env if set; otherwise prompt.
        username = os.environ.get("PHYSIONET_USER") or input("PhysioNet username: ")
        password = os.environ.get("PHYSIONET_PASSWORD") or getpass("PhysioNet password: ")
    else:
        print("All required modules already downloaded.")

    with concurrent.futures.ThreadPoolExecutor(max_workers=len(MODULES)) as executor:
        futures = [
            executor.submit(download_module, m["module"], m["url"], username, password)
            for m in MODULES
        ]
        for future in concurrent.futures.as_completed(futures):
            future.result()  # surface any download error

    print(f"\nDone. Modules available under {MIMIC_IV_PATH}: "
          f"{', '.join(m['module'] for m in MODULES)}")


def build():
    """Build the OMOP CDM with dbt. Requires the source files (and vocab) present.

    Credentials/paths from .env are already loaded into os.environ above, so the
    `dbt` subprocess inherits MIMIC_IV_PATH / OMOP_VOCAB_PATH automatically.
    """
    missing = [m["module"] for m in MODULES
               if not glob.glob(os.path.join(MIMIC_IV_PATH, m["module"], "*.csv.gz"))]
    if missing:
        raise SystemExit(
            f"MIMIC-IV source files missing for module(s): {', '.join(missing)}.\n"
            f"Run `python mimiciv.py download` first (expected under {MIMIC_IV_PATH})."
        )

    if not os.path.isfile(os.path.join(OMOP_VOCAB_PATH, "CONCEPT.csv")):
        raise SystemExit(
            f"OMOP Athena vocabulary not found in {OMOP_VOCAB_PATH} (CONCEPT.csv).\n"
            "It is a manual, license-gated download from https://athena.ohdsi.org "
            "-- unzip the bundle's *.csv files there (see the README), then re-run."
        )

    print("Building OMOP CDM with dbt...")
    subprocess.run(
        ["uv", "run", "dbt", "build",
         "--project-dir", DBT_PROJECT_DIR,
         "--profiles-dir", DBT_PROJECT_DIR],
        check=True,
    )
    db = os.environ.get("MIMIC_IV_DB_PATH", "./mimic_iv_omop.db")
    print(f"\nDone. OMOP CDM database: {db}")
    print("Explore it with: uv run streamlit run dashboard.py")


def main():
    parser = argparse.ArgumentParser(
        description="Download MIMIC-IV source data and/or build the OMOP CDM with dbt."
    )
    parser.add_argument(
        "mode",
        nargs="?",
        choices=["download", "build", "all"],
        default="all",
        help="download: fetch source files only; build: run dbt only (files must "
             "already be downloaded); all: download then build (default).",
    )
    args = parser.parse_args()

    if args.mode in ("download", "all"):
        download()
    if args.mode in ("build", "all"):
        build()


if __name__ == "__main__":
    main()
