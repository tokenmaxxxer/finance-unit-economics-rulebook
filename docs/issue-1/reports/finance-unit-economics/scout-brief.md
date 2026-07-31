# issue-1 scout brief — unit-economics analysis methodology field survey

Scope: what does the field (VC/operator frameworks + standard cost-accounting
treatment) treat as the must-have components of a unit-economics analysis,
and which of those apply to this role's narrow mandate ("단위경제상
성립하는가" — a thin advisory gate, not a full FP&A deliverable)?

## Must-have components across the field

1. **CAC (Customer Acquisition Cost)** — fully loaded acquisition spend
   divided by customers acquired in the period; the denominator side of
   every ratio below.
2. **LTV/CLV (Customer Lifetime Value)**, computed on **gross margin**,
   not gross revenue — a commonly flagged error is using revenue instead
   of margin-adjusted contribution in the LTV numerator.
3. **LTV:CAC ratio** — the field's dominant single go/no-go signal.
   Reported medians cluster around 3:1–4:1 (Optifai ~3.2:1 across 939
   SaaS companies, Benchmarkit ~3.5:1); 3:1 is treated as the accepted
   floor, 4:1–5:1 as strong, and below 2:1 as a capital-efficiency red
   flag.
4. **CAC payback period** — months for a customer's gross profit to
   recover CAC (`CAC / (Monthly ARPU × Gross Margin %)`). Field median is
   reported around 15–18 months for B2B SaaS, with elite targets under
   12 months; the ratio and the payback period are explicitly warned to
   be evaluated *together*, not in isolation (a 2.5:1 ratio with a
   9-month payback can beat a 4:1 ratio with a 36-month payback).
5. **Contribution margin / gross margin per unit** — target range cited
   around 70–85% gross margin for SaaS; this is the multiplier that
   converts revenue-based LTV into a defensible margin-based LTV.
6. **Cohort-based analysis** — cohort-based LTV, not a single blended
   average, is called out as "the only honest version" for lifetime
   value, because blended averages hide retention curve shape and vintage
   effects.
7. **Sensitivity/scenario disclosure** — presenting both cohort and
   blended views and disclosing sensitivity ranges (not a single point
   estimate) is treated as standard practice, since CAC/LTV/payback all
   depend on assumptions (churn curve, discount rate/horizon, margin
   trend) that materially change the conclusion.

## Performance axes strong analyses compete on

- **Rigor of assumptions/sensitivity vs. speed/simplicity** — a full
  cohort-by-cohort model with scenario ranges is more defensible but
  slower to produce than a single blended-average CAC/LTV snapshot.
- **Ratio-only vs. ratio+payback-together** — the field explicitly warns
  that LTV:CAC alone can rank a worse business above a better one; the
  stronger analyses always pair the ratio with payback period and
  margin trend before calling a verdict.
- **Point estimate vs. exposed-assumption range** — weaker teardowns
  present one number; stronger ones expose the churn/margin/horizon
  assumptions driving that number so a reader can judge robustness.

## Adopt / skip for this role

- **Adopt**: CAC, LTV (margin-based), LTV:CAC ratio with a stated
  interpretation band, and a mandatory sensitivity/scenario section
  covering at minimum the churn-rate and margin assumptions driving the
  LTV figure. These four are cheap to require as explicit fields and
  directly answer "단위경제상 성립하는가."
- **Adopt**: CAC payback period, specifically *because* the field
  explicitly warns the ratio alone can mislead — pairing it with payback
  is the cheapest way to avoid a false-positive go signal.
- **Skip**: full cohort-by-cohort retention curve modeling and
  vintage-level reporting. That is a genuine FP&A deliverable's job (the
  a16z/Bessemer teardown format assumes a data team and a billing
  system), not a thin advisory gate's. This role's mandate is a go/no-go
  economic-viability signal with assumptions exposed, not a full
  cohort analytics report — full cohort modeling is out of scope per the
  hand-off boundary (real pricing/cohort work belongs downstream of this
  role's advisory check, and detailed cohort infrastructure is not this
  plugin's job to require).

## Gap vs. current plugin state

The current plugin already names CAC/LTV/margin and a sensitivity note
(directive.sh's `produces` string) and enforces their *headings* via
`produces-fields-gate.sh` (survey.md). What the field survey adds that is
currently missing: (a) LTV:CAC ratio as an explicit required figure with
an interpretation band, not just "margin" as a bare word; (b) CAC payback
period, absent entirely today; (c) a requirement that the sensitivity
section actually vary an assumption (churn/margin/horizon) with numbers,
not just carry the heading text, closing the gap the gate's own comment
flags ("harden before treating as load-bearing").

## Sources

- [SaaS Unit Economics: CAC, LTV, Payback, and the Metrics That Decide Funding — Dodo Payments](https://dodopayments.com/blogs/saas-unit-economics)
- [The Complete SaaS Unit Economics Guide (2026 Edition) — CloudZero](https://www.cloudzero.com/blog/saas-unit-economics/)
- [SaaS Unit Economics: The CFO's Definitive Framework — DualEntry](https://www.dualentry.com/blog/saas-unit-economics)
- [LTV:CAC Ratio Benchmarks 2026 + Free 4-Quadrant Calculator — Foundry CRO](https://foundrycro.com/blog/ltv-cac-ratio-benchmarks-2026/)
- [SaaS Unit Economics: The Complete Founder Guide to CAC, LTV, and Payback (2026) — Raise Ready Book](https://www.raisereadybook.com/blog/the-saas-unit-economics-bible-the-complete-guide-for-founders.html)
- [Introducing a16z Growth's Guide to Growth Metrics — a16z](https://a16z.com/introducing-a16z-growths-guide-to-growth-metrics/)
- [Metrics & KPIs: Expert Guides to Using Data for Growth — a16z](https://a16z.com/category/company-building/metrics-and-kpis/)

Note: results were consolidated by the web-search tool from multiple SaaS
finance blogs (Dodo Payments, CloudZero, DualEntry, Foundry CRO, Raise
Ready Book) plus a16z's own metrics guide category page; no single
canonical Bessemer document surfaced with a direct URL, so the Bessemer
"12 metrics" framing is treated as corroborating background rather than a
cited primary source. The named-framework baseline (contribution-margin
accounting, CAC/LTV, cohort analysis, sensitivity/scenario analysis) is
well-established textbook/industry vocabulary independent of any single
URL above.
