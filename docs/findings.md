# Findings

Findings from the UCI Bank Marketing dataset (41,188 contacts, Portuguese bank,
2008 to 2010). Every number is queried from the BigQuery marts rather than a
local CSV, and compared against the overall subscription base rate of 11.3%
(4,640 of 41,188). Figures are in [`reports/figures/`](../reports/figures).

These are descriptive correlations, not causal claims. Section 1 maps who
subscribes and which contact patterns look effective on the surface. Whether any
of it is a real campaign effect, rather than the bank re-calling people who would
have said yes anyway, is the Day 5 question.

---

## Section 1: The Subscription Landscape

Source notebooks:
[`notebooks/01_subscription_landscape.ipynb`](../notebooks/01_subscription_landscape.ipynb)
(demographics) and
[`notebooks/02_campaign_strategy.ipynb`](../notebooks/02_campaign_strategy.ipynb)
(contact strategy).

### Who subscribes (demographics)

- Life stage is the main demographic signal. Clients aged 60 and over subscribe
  at 39.6% (n=1,193), about 3.5x the 11.3% base rate, while the prime working
  ages 30 to 60 sit below base (30 to 45: 9.6%, 45 to 60: 9.2%). The best-converting
  demographics are mostly people outside the workforce.
  Figure: [subscription_rate_by_job_age.png](../reports/figures/subscription_rate_by_job_age.png)

- Job tells the same story more sharply. Students convert at 31.4% (n=875, 2.8x
  base) and retired clients at 25.2% (n=1,720, 2.2x base). At the bottom,
  blue-collar workers convert at 6.9% (n=9,254, 0.6x base). That is a 4.6x spread
  between the best and worst occupational segment.
  Figure: [subscription_rate_top_bottom_segments.png](../reports/figures/subscription_rate_top_bottom_segments.png)

- Top 3 and bottom 3 segments by job: students 31.4%, retired 25.2%, unemployed
  14.2% at the top; entrepreneur 8.5%, services 8.1%, blue-collar 6.9% at the
  bottom. The top three are all outside conventional employment, so job is
  probably acting as a proxy for age and life stage rather than an independent
  driver.

- Education matters modestly and is confounded. University-degree holders
  subscribe at 13.7% (n=12,168) versus 7.8% for basic.9y (n=6,045), a 1.8x gap.
  The 22% rate for `illiterate` rests on only 18 clients, so it is noise rather
  than a finding.
  Figure: [subscription_rate_by_education.png](../reports/figures/subscription_rate_by_education.png)

- Marital status is a weak signal that tracks age. Single clients subscribe at
  14.0% (n=11,568) versus 10.2% for married (n=24,928), a 1.4x gap that mostly
  reflects singles being younger.
  Figure: [subscription_rate_by_marital.png](../reports/figures/subscription_rate_by_marital.png)

- Financial standing barely matters. Housing loan (11.6% versus 10.9%) and
  personal loan (10.9% versus 11.3%) both sit close to the base rate. Credit
  `default` is effectively constant, with only 3 of 41,188 clients flagged, so it
  carries no usable signal.
  Figure: [subscription_rate_by_financial.png](../reports/figures/subscription_rate_by_financial.png)

### Which contact strategies look effective (campaign)

- Cellular is well ahead of telephone on the surface. Cellular contacts subscribe
  at 14.7% (n=26,144) versus 5.2% for telephone (n=15,044), a 2.8x gap. Whether
  the channel itself drives the lift or just marks a different era and client mix
  is not yet clear.
  Figure: [subscription_rate_by_channel.png](../reports/figures/subscription_rate_by_channel.png)

- Timing is mostly volume, and the two move in opposite directions. May alone
  holds 33% of all contacts but converts at just 6.4%, below base. The high-rate
  months are small: March 50.6%, December 48.9%, September 44.9%, October 43.9%,
  each under 2% of volume. The low-volume months look like curated follow-ups
  rather than a calendar effect.
  Figure: [subscription_rate_by_month.png](../reports/figures/subscription_rate_by_month.png)

- More contacts go with lower subscription, at every step. The rate falls from
  13.0% at the 1st contact (n=17,642) to 5.5% at 6 or more contacts (n=3,385),
  declining all the way down (2: 11.5%, 3: 10.8%, 4: 9.4%, 5: 7.5%). The
  "persistence pays" story is not even directionally present in the raw data.
  This is the main thing to revisit in Day 5; it looks like reverse causation.
  Figure: [subscription_rate_by_n_contacts.png](../reports/figures/subscription_rate_by_n_contacts.png)

- Prior success is the strongest single signal, and the strongest confounder.
  Clients whose previous campaign ended in success subscribe at 65.1% (n=1,373),
  about 5.8x the base rate, versus 14.2% after a prior failure and 8.8% for the
  never-previously-contacted majority (n=35,563).
  Figure: [subscription_rate_by_prior_outcome.png](../reports/figures/subscription_rate_by_prior_outcome.png)

- Among previously-contacted clients, recency conversion is high across the board.
  For the small re-contacted pool (n=1,515), subscription runs 65 to 66% within 6
  days of the last contact and eases to 57% beyond 10 days. This subgroup overlaps
  heavily with prior success, so the level reflects who these clients are rather
  than the timing.
  Figure: [subscription_rate_by_days_since_last_contact.png](../reports/figures/subscription_rate_by_days_since_last_contact.png)

### Questions raised for causal analysis (Day 5)

Each effective-looking strategy above has a selection story behind it. Three
questions to resolve before any of them become recommendations:

1. Does calling clients more times cause subscription, or are repeat contacts
   just a marker of engaged prospects? The raw data shows the opposite of a
   persistence effect (13.0% down to 5.5% as contacts rise). Is that because
   extra calls suppress yes-saying, or because clients who say yes early leave
   the call list and only the harder "no" cases accumulate high contact counts?

2. Are May contacts more effective, or is it just volume? May holds a third of
   all contacts at a below-base 6.4% rate, while low-volume months convert at 44
   to 51%. Is month a real seasonal driver, or is it confounded by which leads
   get worked in the quiet months and by the macro conditions (euribor,
   employment) that come with each period?

3. The prior-success effect (65.1%, 5.8x base): is it the contact strategy or the
   pre-existing relationship? A client who already subscribed once is a very
   different person from a cold lead. Adjusting for this confounder is likely to
   absorb much of the apparent campaign uplift, which is what Day 5 needs to
   measure.

---

## Section 2: Experiment Framing

Source notebook:
[`notebooks/03_experiment_design.ipynb`](../notebooks/03_experiment_design.ipynb).
Day 3 found that subscription falls as contact count rises (13.0% down to 5.5%).
That motivates a concrete operational test:

> Hypothesis: capping campaign contacts at 3 (instead of unlimited) produces
> equal or higher subscription rates while using fewer call-centre resources.

This section specifies the experiment that would answer it cleanly. The dataset
is observational; nobody was randomized to a cap. So this is a design spec, and
the reference point for the Section 3 quasi-experiment.

- Unit of randomization is the client, not the call. The cap is a per-client rule
  ("stop after this person's 3rd contact"). Randomizing individual calls would
  let the same client land in both arms, which breaks the treatment definition,
  violates independence (calls to one client are correlated, so call-level units
  are pseudo-replicated and overstate power), and contaminates the cost metric
  the policy is meant to change.
- Primary metric: subscription rate (binary per client). Secondary: contacts per
  subscription, total contacts, high-value-segment conversion. H0: p_capped =
  p_uncapped; H1: p_capped is not equal to p_uncapped.
- Sample size, computed by hand with the two-proportion z-test rather than a
  library call: at base rate 11.3%, MDE = 1.0pp absolute (about 9% relative),
  alpha = 0.05, power = 0.80, this gives n = 16,295 per arm (32,590 total).

  $$ n_{\text{arm}} = \frac{\left(z_{1-\alpha/2}\sqrt{2\bar p(1-\bar p)} + z_{1-\beta}\sqrt{p_1(1-p_1)+p_2(1-p_2)}\right)^2}{(p_2-p_1)^2} $$

- The dataset is large enough to detect smaller effects. Split 50/50, the 41,188
  clients give 20,594 per arm, more than a 1pp test needs, so the data can in
  principle resolve effects down to about 0.9pp. Statistical power is not the
  binding constraint here; group comparability is (see Section 3).
  Figure: [experiment_sample_size_vs_mde.png](../reports/figures/experiment_sample_size_vs_mde.png)
- Guardrails, declared before analysis: (1) cost per subscription
  (contacts/subscriber) must not rise; (2) conversion among high-value segments
  (retired, management, student) must not drop; (3) weak segments (blue-collar,
  6.9%) must not be over-contacted.
- Threats to validity. Novelty effect does not apply here (this is retrospective,
  not a live test). Primacy and change-aversion are low risk for a rollout, and
  not relevant to this analysis. Selection is the real threat: clients who reached
  contact 6 are systematically different from those who stopped at 2 (harder to
  reach, harder to convince, and not yet converted), so any many-versus-few
  comparison mixes the cap with engagement.

## Section 3: Observational Quasi-Experiment Results

Source notebook:
[`notebooks/04_quasi_experiment.ipynb`](../notebooks/04_quasi_experiment.ipynb).
With no randomized data, the closest observational proxy is Treatment = 1 to 3
contacts (n=33,553) and Control = 4 or more contacts (n=7,635). The analysis is
framed like an experiment, while being clear that the groups are not randomized.

- The naive lift is large but not trustworthy. Treatment subscribes at 12.2%
  (Wilson 95% CI [11.8%, 12.5%]) versus Control at 7.3% ([6.7%, 7.9%]): +4.9pp,
  or +67.5% relative, with two-proportion z = 12.2 and p close to 0. At face
  value you would cap immediately.
  Figure: [quasi_group_subscription_rates.png](../reports/figures/quasi_group_subscription_rates.png)
- But the groups are not comparable, and the balance check fails where it matters
  most. Chi-square of independence (arm by covariate) shows demographics are only
  mildly skewed: education is actually balanced (chi-square 5.2, p=0.64), and job
  (p=7e-4) and marital (p=0.03) shift only a little. The campaign-engagement
  covariates are imbalanced by a huge margin: prior outcome chi-square 252,
  p~1.6e-55; contact month chi-square 764, p~1e-158; channel p~3e-31; the
  prior-contact flag p~8e-28.
  Figure: [quasi_covariate_imbalance.png](../reports/figures/quasi_covariate_imbalance.png)
- The confounder is the same one from Day 3. The Treatment group is 2.7x richer
  in previously-successful clients (3.78% versus 1.38%) and lighter in
  never-contacted cold leads (85.1% versus 91.8%). The 4+ group is mostly cold
  leads receiving many calls, the kind of clients who were always going to convert
  less, cap or no cap. Contact count is a consequence of engagement, not a
  randomized assignment.
- The guardrails all "pass", but for the wrong reason. Contacts per subscription,
  high-value conversion, and blue-collar contact load all look better in
  Treatment, but each is the same selection effect in a different form (engaged
  clients convert quickly and also accrue few contacts). Guardrails only reassure
  when the groups are comparable, and here they are not.
- Business impact is real on cost and bounded on subscriptions. A cap at 3 would
  have saved 28,044 calls, 26.5% of the 105,754 total. The subscription cost
  depends entirely on whether late contacts cause conversions: somewhere between
  losing 555 subscribers (12%, conservative assumption) and losing none
  (optimistic assumption). The width of that band is the confounding.
  Figure: [quasi_contact_cap_tradeoff.png](../reports/figures/quasi_contact_cap_tradeoff.png)

Bottom line: these groups are not randomized, so the naive +67% lift mixes the
contact cap with client engagement; clients who needed 4 or more calls (cold
leads, no prior success) were always going to convert less. The resource saving
is genuine and large, but the subscription effect is only bounded, not estimated.
Day 5 measures that confounding, adjusting for prior outcome, channel, and macro
context, and turns these bounds into an estimate of whether a contact cap helps,
hurts, or is roughly free.

---

## Section 5: Causal Analysis: Does Persistence Hurt, or Are Subscribers Just Leaving Early?

Source notebook:
[`notebooks/05_causal_contact_effect.ipynb`](../notebooks/05_causal_contact_effect.ipynb).
Method: stratification and standardization with weighted means (the g-formula
with stratum weights). Pandas and numpy only, with the Wilson interval and the
bootstrap written out by hand; no regression or machine learning. Treatment = 3
or more contacts this campaign; Control = fewer than 3.

The naive comparison makes persistence look harmful. Clients with 3 or more
contacts subscribe at 8.70% (n=12,976) versus 12.45% for those with fewer than 3
(n=28,212), a naive ATE of -3.74pp (bootstrap 95% CI [-4.30, -3.10]).
Figure: [naive_ate.png](../reports/figures/naive_ate.png)

But the two arms are not comparable. The low-contact Control group holds more
prior-success clients (4.0% versus 1.9% in Treatment) and more prior failures
(11.7% versus 7.3%), while Treatment is almost entirely never-contacted cold
leads (90.8% `nonexistent`). Prior-success clients convert at about 60 to 66%,
and they reached low contact counts because they said yes early. So the
high-contact bucket is structurally the harder-to-convert pool. Comparing within
each `prior_outcome` stratum shrinks the effect at every level (`nonexistent`
-2.3pp, `failure` -1.0pp, `success` -7.9pp).
Figure: [stratum_ates.png](../reports/figures/stratum_ates.png)

Standardizing those within-stratum effects back to the full population gives an
ATE of -2.39pp (bootstrap 95% CI [-2.98, -1.76]). Triangulating with age_bucket
as the stratifier instead gives -3.41pp ([-4.00, -2.78]), barely different from
the naive number, which confirms that prior engagement, not age, is the
confounder doing the work.
Figure: [ate_comparison.png](../reports/figures/ate_comparison.png)

| Method                          | ATE (pp) | 95% CI           |
| ------------------------------- | -------- | ---------------- |
| Naive (raw)                     | -3.74    | [-4.30, -3.10]   |
| Standardized by prior_outcome   | -2.39    | [-2.98, -1.76]   |
| Standardized by age_bucket      | -3.41    | [-4.00, -2.78]   |

The gap between the naive row and the prior_outcome row, about 1.35pp or 36% of
the naive effect, is the selection effect from easy converters leaving the call
list early.

How much was real and how much was selection. Roughly a third of the naive harm
was selection: prior-success clients said yes on an early call and never reached
high contact counts, which pushed the low-contact group's rate up and made
contact look worse than it is. The other two thirds survive adjustment. The
effect stays negative inside every stratum, including prior-success, so the
honest answer is "both, but not equally": subscribers leaving early explains a
real part of the steep raw gradient, and a smaller, still-negative contact effect
of about -2.4pp remains after adjusting for prior engagement. Persistence does
not appear to help, and it may modestly hurt.

Business implication. Three moves follow, in order of confidence. First, a
contact cap is low-risk: no stratum shows any gain from more contacts, and Day 4
showed a cap at 3 would save about 26% of all calls, so the bank can cut volume
without an expected loss in subscriptions. Second, reallocate budget toward
`prior_outcome=success` clients, who convert at 58 to 66% versus an 11.3% base;
they are by far the highest-yield pool and should be contacted, but lightly,
since extra contacts reduce their conversion the most. Third, stop spending hard
on `prior_outcome=failure` clients: they convert at about 13 to 14% and extra
contacts move them by only about -1pp, so persistence does not rescue them.

Limitations. Stratification only adjusts for the variables we stratify on. This
analysis controls for prior outcome and age, but unmeasured confounders such as
income, urgency to save, or existing product holdings are not captured and could
still bias the standardized estimate. This is an observational adjustment, not a
randomized experiment, so the remaining -2.4pp should be read as a well-adjusted
association rather than a proven causal effect. The randomized test that would
settle it is specified in Section 2.
