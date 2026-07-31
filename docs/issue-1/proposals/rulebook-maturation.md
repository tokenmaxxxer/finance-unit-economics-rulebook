# issue-1 phase-1 proposal — finance-unit-economics rulebook maturation

Grounded in `docs/issue-1/reports/finance-unit-economics/survey.md`
(internal current-state gaps) and
`docs/issue-1/reports/finance-unit-economics/scout-brief.md` (external
field survey). This is a proposal only — no plugin file is edited in this
phase.

## (a) Phase-1 proposal norms

A finance-unit-economics phase-1 proposal must:

1. Include an internal current-state survey of this role's own plugin
   files (what exists / what's placeholder / what's missing), separate
   from any external field survey — matching the pattern this document
   and its companion survey.md follow.
2. Include a scout brief citing at least the following angles before
   adopting any methodology claim: CAC/LTV definitions and formulas,
   LTV:CAC benchmark ratios, CAC payback period, contribution-margin
   accounting, and cohort vs. blended reporting. Each adopted claim must
   carry either a source URL (if web access was available) or an
   explicit "working from named-framework assumption, not fabricated
   citation" label — never an invented citation.
3. State, for every adopted item, the logical chain: field evidence →
   this role's stated mandate ("단위경제상 성립하는가") → why the item is
   necessary to answer that mandate, not merely common practice
   elsewhere.
4. Include a concrete phase-2 plugin reflection plan (proposed
   `produces` string, proposed `REQUIRED_FIELDS` list, proposed gate
   logic) that phase 2 can execute without re-deriving methodology.
5. End with a "Decision requested" section naming exactly what the
   approver is being asked to approve for phase 2, following the
   heading style of `docs/issue-5/proposals/implementation.md`.

Adequate evidence for an adopted claim = a named, checkable framework
(CAC, LTV, contribution margin, cohort analysis, sensitivity/scenario
analysis are all standard cost-accounting/VC-operator vocabulary) backed
by either a real URL consulted this phase, or — if search were
unavailable — an explicit assumption label. Fabricated citations or
unlabeled "common knowledge" claims are not adequate evidence.

## (b) Phase-2 deliverable norms

A finance-unit-economics phase-2 record
(`docs/issue-<n>/reports/finance-unit-economics.md`) must contain, at
minimum:

1. **CAC figure** with the formula and the spend/customer-count
   assumptions used to compute it stated explicitly (not just a number).
2. **LTV figure** computed on **margin**, not gross revenue, with the
   churn-rate/retention-horizon assumption stated explicitly.
3. **LTV:CAC ratio**, plus an explicit interpretation against the field's
   accepted bands (≥3:1 floor, 4:1–5:1 strong, <2:1 red flag per
   scout-brief.md) — a bare ratio number with no interpretation does not
   satisfy this.
4. **CAC payback period** (`CAC / (Monthly ARPU × Gross Margin %)`),
   because the field survey explicitly warns the LTV:CAC ratio alone can
   rank a worse business above a better one — payback is the cheapest
   corrective check, and cheap enough to always require alongside the
   ratio rather than treat as optional.
5. **Sensitivity/scenario section containing actual numbers** — at
   minimum one varied assumption (churn rate or margin) shown across at
   least two scenarios, not merely a heading with no numeric content.
   This item stays **mandatory, not softened**: this role's mandate is a
   go/no-go signal, and a go/no-go signal without exposed sensitivity is
   indistinguishable from a guess dressed as a conclusion — the entire
   value this role adds over "look at one static number" is showing how
   the verdict moves when the assumption moves.

Explicitly **not required**: full cohort-by-cohort retention curve
modeling or vintage-level reporting. Per scout-brief.md's adopt/skip
call, that is genuine FP&A-deliverable work requiring a data/billing
pipeline this thin advisory role does not own — requiring it here would
turn a lightweight gate into a data-engineering project and blur the
hand-off boundary below.

## (c) Justification tied to mandate and hand-off boundary

This role's mandate is "단위경제상 성립하는가" — does the decision hold up
unit-economically — and its hand-off line is explicit: "실제 가격 숫자
결정은 → pricing" (actual pricing-number decisions go to the pricing
role). Every item adopted in (b) is chosen because it is load-bearing for
a *viability signal*, not a *pricing recommendation*:

- CAC/LTV/ratio/payback are the field's own minimum set for answering
  "does this hold up," independent of what the eventual price point is.
- The sensitivity requirement keeps this role's output honest about
  assumption-dependence, which is exactly what a downstream pricing
  decision needs disclosed — this role hands off an economic viability
  read with exposed assumptions, not a number to plug into a price.
- Full cohort/vintage modeling is excluded precisely because it would
  start producing pricing-relevant granularity this role is not
  chartered to own; that level of detail, if ever needed, is downstream
  work, consistent with the hand-off boundary already declared in
  `plugin.json`.

## (d) Plugin reflection plan (phase 2 — not executed this phase)

**Scope note**: only this role's own thin plugin files
(`finance-unit-economics/hooks/directive.sh`,
`finance-unit-economics/hooks/hooks.json`,
`finance-unit-economics/hooks/produces-fields-gate.sh`) are proposed for
edits below. `finance-unit-economics/agents/warrant-hunter.md` and any
core canon reference are explicitly **not** to be copied, duplicated, or
edited by this plan — per issue-2's already-landed core-canon-reference
transition, warrant-hunter stays a thin stub over core's `warrant/`
plugin, and its empty stance set is out of this issue's scope.

1. **`directive.sh`** — proposed `produces` string:
   `"unit economics record (CAC, LTV on margin, LTV:CAC ratio + band, CAC payback period), sensitivity/scenario section with numbers"`
   (replaces the current bare "unit economics model (CAC/LTV/margin),
   sensitivity note").

2. **`produces-fields-gate.sh`** — proposed full `REQUIRED_FIELDS` list:
   ```
   REQUIRED_FIELDS = [
       "cac",
       "ltv",
       "ltv-cac-ratio",
       "cac-payback-period",
       "sensitivity-note",
   ]
   ```
   (field-name tokens to be finalized to match whatever heading
   convention phase 2's record template adopts; shown here as the
   methodology-derived minimum set, one entry per (b) item 1-5 above,
   contribution margin folded into the LTV assumption disclosure rather
   than kept as a separate field since margin already gates the LTV
   number itself).

3. **Additional PreToolUse gate logic needed** (beyond heading
   presence): the gate should not stop at substring/heading match for
   `sensitivity-note` — it should also check that the sensitivity
   section's text contains at least one numeric token (e.g. a
   percentage or currency-formatted number) near the heading, so a
   heading with no numbers still fails the gate. The same numeric-content
   check should apply to the `cac`, `ltv`, and `cac-payback-period`
   fields, closing the exact gap survey.md and scout-brief.md both flag:
   today's gate is satisfied by the label alone.

4. **`hooks.json`** — no structural change anticipated (still one
   `SessionStart` + one `PreToolUse` registration); only the command
   target's internal logic changes via item 2/3 above.

## Decision requested

Approve phase 2 to:

1. Update `finance-unit-economics/hooks/directive.sh`'s `produces` string
   to the wording in (d) item 1.
2. Update `finance-unit-economics/hooks/produces-fields-gate.sh`'s
   `REQUIRED_FIELDS` to the five-field list in (d) item 2, and add the
   numeric-content check described in (d) item 3.
3. Leave `finance-unit-economics/agents/warrant-hunter.md` and
   `finance-unit-economics/hooks/hooks.json` unchanged, per the scope
   note in (d).
4. Record the phase-2 change and its rationale in
   `docs/issue-1/reports/finance-unit-economics.md` once executed.
