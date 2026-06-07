# Bank Campaign Causal Intelligence

## Overview

An analytics-engineering project on the [UCI Bank Marketing dataset](https://archive.ics.uci.edu/dataset/222/bank+marketing)
(~41,000 contacts from a Portuguese bank's direct-marketing campaigns). The
data is ingested into BigQuery, modelled with dbt, and analysed for the causal
effect of the campaign — not just its correlation with subscriptions.

## The Question

> **Did the marketing campaign actually work, or did the bank just keep calling
> people who would have said yes anyway?**

The headline metric (whether a client subscribed to a term deposit) is easy to
correlate with contact activity. The harder, more honest question is *causal*:
how much of the observed uplift is attributable to the campaign itself versus
selection effects in who got contacted. That analysis is the centrepiece
(Day 5).

Two data hazards are handled explicitly from day one:

- **`duration` is leakage.** Call duration is only known *after* a call ends, so
  it trivially predicts the outcome. It is flagged and excluded from all
  causal/predictive work.
- **`pdays == 999` is a sentinel**, not a real value — it means the client was
  never previously contacted. It is loaded as-is into `raw` and converted to
  `NULL` in the staging layer.

## Stack

| Layer            | Tool                                    |
| ---------------- | --------------------------------------- |
| Warehouse        | Google BigQuery (free tier)             |
| Ingestion        | Python (`google-cloud-bigquery`, pandas)|
| Transformation   | dbt (`dbt-bigquery`), layered raw → staging → marts |
| Analysis         | scikit-learn, scipy, statsmodels-style causal methods |
| Visualisation    | matplotlib, seaborn, Streamlit, Power BI|
| Narrative / docs | Anthropic API                           |

Auth is via a **service account** (not user auth) for reproducibility, and the
BigQuery schema is **explicitly typed** (no autodetect).

## Project Structure

```
bank-campaign-causal-intelligence/
├── data/raw/                       # source CSV (git-ignored)
├── src/
│   └── ingest.py                   # CSV -> BigQuery raw.campaign_contacts
├── dbt/
│   └── bank_campaign/              # dbt project (dbt-bigquery)
│       ├── dbt_project.yml
│       ├── profiles.yml            # service-account auth, raw/staging/marts
│       ├── macros/
│       │   └── generate_schema_name.sql
│       └── models/
│           ├── staging/
│           │   ├── _sources.yml
│           │   └── stg_campaign_contacts__test.sql
│           └── marts/
├── notebooks/                      # exploratory analysis
├── dashboards/                     # Streamlit / Power BI artifacts
├── credentials/                    # service-account key (git-ignored)
├── requirements.txt
└── README.md
```

## Status

**Day 1 of 7 — scaffolding & ingestion.**

- [x] Project scaffolding, `.gitignore`, pinned `requirements.txt`
- [x] Python ingestion script with explicit BigQuery schema
- [x] dbt project initialised (raw / staging / marts), service-account auth
- [x] Trivial dbt connection-test model
- [ ] GCP project + dataset created, credentials in place *(manual — see Setup)*
- [ ] `dbt debug` passing & test model materialised *(after credentials)*
- [ ] Days 2–7: staging, EDA, modelling, **causal analysis (Day 5)**, dashboard, write-up

## Setup

1. Create a GCP project `bank-campaign-causal` with BigQuery enabled (free tier).
2. Create a service account, grant it **BigQuery Data Editor** + **BigQuery Job
   User**, download its JSON key to `credentials/service-account.json`.
3. Create and populate the environment:
   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   $env:GCP_PROJECT_ID = "bank-campaign-causal"
   $env:GOOGLE_APPLICATION_CREDENTIALS = "$PWD\credentials\service-account.json"
   ```
4. Ingest the data:
   ```powershell
   python src/ingest.py
   ```
5. Verify the dbt connection:
   ```powershell
   cd dbt/bank_campaign
   $env:DBT_GCP_KEYFILE = "$PWD\..\..\credentials\service-account.json"
   dbt debug --profiles-dir .
   dbt run --profiles-dir .
   ```

## Headline Findings

_TBD — populated after the Day 5 causal analysis._
