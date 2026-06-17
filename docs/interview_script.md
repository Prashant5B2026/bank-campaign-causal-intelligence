# Interview walk-through: the contact-frequency causal analysis

Two versions of the same story, for different time budgets. Numbers come from
[`notebooks/05_causal_contact_effect.ipynb`](../notebooks/05_causal_contact_effect.ipynb)
and Section 5 of [`findings.md`](findings.md).

## 90-second version

The question I set out to answer was simple: does calling clients more often
actually hurt subscriptions, or does it just look that way?

When I first looked at the data, the pattern was striking and a bit alarming.
Subscription rate dropped steadily as contact count went up, from 13% on the
first contact down to about 5% by the sixth. If I split clients into a high-touch
group with 3 or more contacts and a low-touch group with fewer than 3, the
high-touch group subscribed about 3.7 percentage points lower. Taken at face
value, that says persistence backfires.

But I did not trust that number, because the two groups are not the same kind of
people. When I broke down each group by their prior campaign history, the
low-touch group was full of clients who had already subscribed in a previous
campaign. Those people convert around 60 to 65%, and they show up in the low-touch
group precisely because they said yes early and never needed more calls. So the
high-touch group is really the harder-to-convert pool, which makes contact look
worse than it is.

To handle that, I compared the high-touch and low-touch clients inside each prior
outcome group, where they are more alike, and then standardized those
within-group effects back to the whole population using a weighted average. I put
a 95% confidence interval on it with a thousand-sample bootstrap that I wrote out
as an explicit loop. After adjustment the effect went from -3.7 points to about
-2.4 points, with a confidence interval of roughly -3.0 to -1.8. I triangulated
with age as a second stratifier and got -3.4, almost unchanged, which told me
prior engagement was the real confounder, not age.

So the answer is: both, but not equally. About a third of the apparent harm was
selection, easy converters dropping off the call list. The remaining two thirds
is a real, still-negative effect. Persistence does not help and probably hurts a
little. The business takeaway is that a contact cap is low-risk and saves a lot of
calls, the budget should shift toward clients with a prior success who convert far
above base, and chasing prior failures with more calls does not pay off. The one
caveat I always add: this is an observational adjustment, so it controls for what
I stratified on but not for things I cannot see, like income or how urgently
someone needs to save.

## 30-second version

Calling clients more looked harmful: the group with 3 or more contacts subscribed
about 3.7 points lower than the group with fewer. But that group was also full of
harder-to-convert clients, because easy converters said yes early and never got
more calls. After I stratified by prior campaign history and standardized, the
effect shrank to about -2.4 points and stayed negative. So persistence does not
help, roughly a third of the scare was selection, and the bank should cap contacts
and move spend toward clients who already converted once.
