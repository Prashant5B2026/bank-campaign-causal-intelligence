"""Load the UCI Bank Marketing dataset into BigQuery.

Reads data/raw/bank-additional-full.csv (semicolon-delimited, quoted) and loads
it into BigQuery as `raw.campaign_contacts` using an EXPLICIT typed schema
(no autodetect).

Notes on the source data
------------------------
* The CSV is delimited with ';' and the economic columns use dots in their
  names (emp.var.rate, cons.price.idx, cons.conf.idx, nr.employed). BigQuery
  column names cannot contain dots, so they are renamed to underscores here.
* `pdays == 999` means "client was never previously contacted". We load the
  value AS-IS (no nulling here) and handle the 999 -> NULL conversion in the
  dbt staging layer, so the raw table is a faithful copy of the source.
* `duration` is a leakage feature (only known after a call completes). It is
  loaded for completeness but must be excluded from any causal/predictive work.

Auth
----
Uses a service account. Point GOOGLE_APPLICATION_CREDENTIALS at the key file
(or rely on the default path credentials/service-account.json) and set
GCP_PROJECT_ID to your project.

Usage
-----
    python src/ingest.py
    python src/ingest.py --csv data/raw/bank-additional-full.csv --replace
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import pandas as pd
from google.cloud import bigquery
from google.oauth2 import service_account

# Repo root = parent of this file's directory (src/).
REPO_ROOT = Path(__file__).resolve().parents[1]

DEFAULT_CSV = REPO_ROOT / "data" / "raw" / "bank-additional-full.csv"
DEFAULT_KEYFILE = REPO_ROOT / "credentials" / "service-account.json"

DATASET = "raw"
TABLE = "campaign_contacts"
LOCATION = "US"

# Source column name -> BigQuery-safe column name (dots are illegal in BQ).
RENAME_MAP = {
    "emp.var.rate": "emp_var_rate",
    "cons.price.idx": "cons_price_idx",
    "cons.conf.idx": "cons_conf_idx",
    "nr.employed": "nr_employed",
}

# Explicit, ordered schema. No autodetect.
SCHEMA: list[bigquery.SchemaField] = [
    bigquery.SchemaField("age", "INT64", mode="REQUIRED"),
    bigquery.SchemaField("job", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("marital", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("education", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("default", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("housing", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("loan", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("contact", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("month", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("day_of_week", "STRING", mode="NULLABLE"),
    # Leakage feature: known only after the call. Flagged, not dropped here.
    bigquery.SchemaField("duration", "INT64", mode="NULLABLE"),
    bigquery.SchemaField("campaign", "INT64", mode="NULLABLE"),
    # 999 == "never previously contacted"; converted to NULL in staging.
    bigquery.SchemaField("pdays", "INT64", mode="NULLABLE"),
    bigquery.SchemaField("previous", "INT64", mode="NULLABLE"),
    bigquery.SchemaField("poutcome", "STRING", mode="NULLABLE"),
    bigquery.SchemaField("emp_var_rate", "FLOAT64", mode="NULLABLE"),
    bigquery.SchemaField("cons_price_idx", "FLOAT64", mode="NULLABLE"),
    bigquery.SchemaField("cons_conf_idx", "FLOAT64", mode="NULLABLE"),
    bigquery.SchemaField("euribor3m", "FLOAT64", mode="NULLABLE"),
    bigquery.SchemaField("nr_employed", "FLOAT64", mode="NULLABLE"),
    bigquery.SchemaField("y", "STRING", mode="NULLABLE"),
]

# Pandas dtypes mirroring the BigQuery schema, so the DataFrame we hand to
# the client already matches and nothing is silently re-typed.
DTYPES: dict[str, str] = {
    "age": "int64",
    "job": "string",
    "marital": "string",
    "education": "string",
    "default": "string",
    "housing": "string",
    "loan": "string",
    "contact": "string",
    "month": "string",
    "day_of_week": "string",
    "duration": "int64",
    "campaign": "int64",
    "pdays": "int64",
    "previous": "int64",
    "poutcome": "string",
    "emp_var_rate": "float64",
    "cons_price_idx": "float64",
    "cons_conf_idx": "float64",
    "euribor3m": "float64",
    "nr_employed": "float64",
    "y": "string",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load bank marketing CSV into BigQuery.")
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Path to the source CSV.")
    parser.add_argument(
        "--project",
        default=os.environ.get("GCP_PROJECT_ID"),
        help="GCP project id (defaults to $GCP_PROJECT_ID).",
    )
    parser.add_argument(
        "--keyfile",
        type=Path,
        default=Path(os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", DEFAULT_KEYFILE)),
        help="Service-account JSON key (defaults to $GOOGLE_APPLICATION_CREDENTIALS "
        "or credentials/service-account.json).",
    )
    parser.add_argument(
        "--replace",
        action="store_true",
        help="Truncate the table before loading (default appends are disabled; "
        "without this flag the load also truncates for idempotency).",
    )
    return parser.parse_args()


def load_dataframe(csv_path: Path) -> pd.DataFrame:
    """Read the semicolon-delimited CSV and normalise column names."""
    if not csv_path.exists():
        sys.exit(f"ERROR: CSV not found at {csv_path}. Download it into data/raw/ first.")

    df = pd.read_csv(csv_path, sep=";", quotechar='"')
    df = df.rename(columns=RENAME_MAP)

    expected = list(DTYPES.keys())
    missing = [c for c in expected if c not in df.columns]
    if missing:
        sys.exit(f"ERROR: source is missing expected columns: {missing}")

    df = df[expected].astype(DTYPES)
    return df


def build_client(project: str | None, keyfile: Path) -> bigquery.Client:
    if not project:
        sys.exit("ERROR: set --project or $GCP_PROJECT_ID to your GCP project id.")
    if not keyfile.exists():
        sys.exit(
            f"ERROR: service-account key not found at {keyfile}. "
            "Create one in the GCP console and save it there (see README)."
        )
    credentials = service_account.Credentials.from_service_account_file(str(keyfile))
    return bigquery.Client(project=project, credentials=credentials, location=LOCATION)


def ensure_dataset(client: bigquery.Client) -> None:
    dataset_ref = bigquery.Dataset(f"{client.project}.{DATASET}")
    dataset_ref.location = LOCATION
    client.create_dataset(dataset_ref, exists_ok=True)
    print(f"Dataset ready: {client.project}.{DATASET}")


def main() -> None:
    args = parse_args()

    df = load_dataframe(args.csv)
    print(f"Read {len(df):,} rows x {len(df.columns)} columns from {args.csv.name}")
    never_contacted = int((df["pdays"] == 999).sum())
    print(f"Note: pdays == 999 (never previously contacted) in {never_contacted:,} rows "
          "-> left as-is; converted to NULL in dbt staging.")

    client = build_client(args.project, args.keyfile)
    ensure_dataset(client)

    table_id = f"{client.project}.{DATASET}.{TABLE}"
    job_config = bigquery.LoadJobConfig(
        schema=SCHEMA,
        autodetect=False,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    load_job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    load_job.result()  # wait for completion

    table = client.get_table(table_id)
    print(f"Loaded {table.num_rows:,} rows into {table_id} ({len(table.schema)} columns).")


if __name__ == "__main__":
    main()
