# Findings

Quantified, leakage-aware findings from the UCI Bank Marketing dataset
(41,188 contacts, Portuguese bank, 2008–2010). Every number is queried live
from the BigQuery marts — never a local CSV — and anchored to the **overall
subscription base rate of 11.3%** (4,640 / 41,188). Figures referenced below
live in [`reports/figures/`](../reports/figures).

> ⚠️ **These are descriptive correlations, not causal claims.** Section 1 maps
> *who* subscribes and *which contact patterns look effective on the surface*.
> Whether any of it is a real campaign effect — versus the bank simply
> re-calling people who would have said yes anyway — is the Day 5 question.

---

## Section 1: The Subscription Landscape

Source notebooks:
[`notebooks/01_subscription_landscape.ipynb`](../notebooks/01_subscription_landscape.ipynb)
(demographics) and
[`notebooks/02_campaign_strategy.ipynb`](../notebooks/02_campaign_strategy.ipynb)
(contact strategy).

### Who subscribes — demographics

- **Life stage dominates the demographic signal.** Clients aged **60+ subscribe
  at 39.6%** (n=1,193) — **3.5× the 11.3% base rate** — while the prime working
  ages 30–60 sit *below* base (30–45: 9.6%, 45–60: 9.2%). The campaign's "best"
  demographics are precisely the people *outside* the workforce.
  → [subscription_rate_by_job_age.png](../reports/figures/subscription_rate_by_job_age.png)

- **Job tells the same story, sharper.** **Students convert at 31.4%** (n=875,
  2.8× base) and **retired clients at 25.2%** (n=1,720, 2.2× base); at the bottom,
  **blue-collar workers convert at just 6.9%** (n=9,254, 0.6× base). That is a
  **4.6× spread** between the best and worst occupational segment.
  → [subscription_rate_top_bottom_segments.png](../reports/figures/subscription_rate_top_bottom_segments.png)

- **Top 3 / bottom 3 segments (by job):** students 31.4%, retired 25.2%,
  unemployed 14.2% on top; entrepreneur 8.5%, services 8.1%, blue-collar 6.9% on
  the bottom. Note the top three are all outside conventional employment — job is
  very likely a **proxy for age and life stage**, not an independent lever.

- **Education moves the needle modestly and is confounded.** University-degree
  holders subscribe at **13.7%** (n=12,168) vs **7.8%** for basic.9y (n=6,045) —
  a 1.8× gap. The eye-catching 22% for `illiterate` rests on **n=18** and is
  noise, not a finding.
  → [subscription_rate_by_education.png](../reports/figures/subscription_rate_by_education.png)

- **Marital status is a weak signal that tracks age.** Single clients subscribe
  at **14.0%** (n=11,568) vs **10.2%** for married (n=24,928) — a 1.4× gap that
  largely reflects singles skewing younger.
  → [subscription_rate_by_marital.png](../reports/figures/subscription_rate_by_marital.png)

- **Financial standing barely matters.** Housing loan (11.6% vs 10.9%) and
  personal loan (10.9% vs 11.3%) both hug the base rate. Credit `default` is
  effectively a constant — only **3 of 41,188** clients are flagged — so it
  carries no usable signal.
  → [subscription_rate_by_financial.png](../reports/figures/subscription_rate_by_financial.png)

### Which contact strategies look effective — campaign

- **Cellular crushes telephone on the surface.** Cellular contacts subscribe at
  **14.7%** (n=26,144) vs **5.2%** for telephone (n=15,044) — a **2.8× gap**.
  Whether the channel *causes* the lift or merely marks a different era and
  client mix is unresolved.
  → [subscription_rate_by_channel.png](../reports/figures/subscription_rate_by_channel.png)

- **Timing is dominated by volume skew, and the two move inversely.** **May
  alone holds 33% of all contacts but converts at just 6.4%** — *below* base. The
  high-rate months are tiny: March 50.6%, December 48.9%, September 44.9%,
  October 43.9%, each on **<2% of volume**. This is a textbook volume-vs-
  effectiveness trap — the low-volume months are almost certainly curated
  follow-ups, not a calendar effect.
  → [subscription_rate_by_month.png](../reports/figures/subscription_rate_by_month.png)

- **More contacts correlate with *lower* subscription — monotonically.** Rate
  falls from **13.0% at the 1st contact** (n=17,642) to **5.5% at 6+ contacts**
  (n=3,385), declining at every step in between (2→11.5%, 3→10.8%, 4→9.4%,
  5→7.5%). The naive "persistence pays" story is *not even directionally* present
  in the raw data. Flagged hard for Day 5 — this looks like reverse causation.
  → [subscription_rate_by_n_contacts.png](../reports/figures/subscription_rate_by_n_contacts.png)

- **Prior success is the single strongest signal — and the strongest
  confounder.** Clients whose *previous* campaign ended in success subscribe at
  **65.1%** (n=1,373) — **5.8× the base rate** — versus 14.2% after a prior
  failure and 8.8% for the never-previously-contacted majority (n=35,563).
  → [subscription_rate_by_prior_outcome.png](../reports/figures/subscription_rate_by_prior_outcome.png)

- **Among previously-contacted clients, recency conversion is uniformly high.**
  For the small re-contacted pool (n=1,515), subscription runs **65–66% within
  6 days** of the last contact and eases to **57% beyond 10 days** — but this
  subgroup overlaps heavily with prior-success, so the level reflects *who these
  clients are*, not the timing.
  → [subscription_rate_by_days_since_last_contact.png](../reports/figures/subscription_rate_by_days_since_last_contact.png)

> ### ❓ Questions raised for causal analysis (Day 5)
>
> Every "effective strategy" above is shadowed by a selection story. Three to
> resolve before any of these become recommendations:
>
> 1. **Does calling clients more times *cause* subscription, or are repeat
>    contacts a proxy for engaged prospects?** The raw data shows the *opposite*
>    of a persistence effect (13.0% → 5.5% as contacts rise). Is that because
>    extra calls suppress yes-saying, or because clients who say yes early exit
>    the call list and only the hard "no"s accumulate high contact counts?
>
> 2. **Are May-month contacts more effective, or is it just volume?** May holds
>    a third of all contacts at a below-base 6.4% rate, while sub-2%-volume
>    months convert at 44–51%. Is month a genuine seasonal driver, or is it
>    confounded by *which* leads get worked in the quiet months and by the
>    macro-economic conditions (euribor, employment) baked into each period?
>
> 3. **The `prior_outcome = success` effect (65.1%, 5.8× base) — is it the
>    contact strategy or the pre-existing client relationship?** A client who
>    already subscribed once is a fundamentally different person from a cold
>    lead. Adjusting for this confounder is likely to absorb most of the apparent
>    "campaign uplift" — which is exactly what Day 5 must quantify.
