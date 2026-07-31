# issue-1 phase-2 record — finance-unit-economics rulebook maturation

loop_state: landed

## What was done

Reflected the approved `docs/issue-1/proposals/rulebook-maturation.md`
(decision requested items 1-3) into this role's plugin:

1. `finance-unit-economics/hooks/directive.sh` — `produces` string
   updated to: `"unit economics record (CAC, LTV on margin, LTV:CAC ratio
   + band, CAC payback period), sensitivity/scenario section with
   numbers"`, replacing the prior bare "unit economics model
   (CAC/LTV/margin), sensitivity note".
2. `finance-unit-economics/hooks/produces-fields-gate.sh` —
   `REQUIRED_FIELDS` expanded from `["unit-economics-model",
   "sensitivity-note"]` to `["cac", "ltv", "ltv-cac-ratio",
   "cac-payback-period", "sensitivity-note"]`. Added a numeric-content
   check (`NUMERIC_REQUIRED_FIELDS`): for `cac`, `ltv`,
   `cac-payback-period`, and `sensitivity-note`, the gate scans a window
   following the field label for a digit or currency/percent symbol and
   refuses if none is found — a heading with no numbers no longer
   satisfies the gate.
3. `finance-unit-economics/hooks/hooks.json` — left unchanged (no
   structural change was needed; only the command target's internal
   logic changed).
4. `finance-unit-economics/agents/warrant-hunter.md` — left unchanged;
   stays a thin stub over core canon's `warrant/` plugin (issue-2), not
   copied or edited by this issue.

## Why

Per proposal section (c): this role's mandate is "단위경제상 성립하는가,"
and the field survey found the LTV:CAC ratio alone can rank a worse
business above a better one, and that sensitivity disclosure is what
separates a viability signal from a static number. The prior two-field
gate (`unit-economics-model`, `sensitivity-note`) accepted heading-only,
number-free records — the exact gap `survey.md` and `scout-brief.md` both
flagged. The new five-field list and numeric-content check make the gate
enforce the phase-1 methodology (CAC/LTV/ratio+band/payback/sensitivity,
each with real numbers) instead of enforcing section titles alone.

## Upstream basis

- `docs/issue-1/proposals/rulebook-maturation.md` (this issue's approved
  phase-1 proposal)
- `docs/issue-1/reports/finance-unit-economics/survey.md` (internal
  current-state survey)
- `docs/issue-1/reports/finance-unit-economics/scout-brief.md` (external
  field survey: CAC/LTV formulas, LTV:CAC bands, payback period,
  contribution margin, cohort vs. blended reporting)
- Approval: issue-level comment `APPROVE issue-1/finance-unit-economics`
  by `JiwonJung94` (approvers.md account), single-account mode, posted
  2026-07-31.

## CAC

Not applicable to this record. This is a plugin-reflection record, not a
unit-economics analysis of a target deal or product — no CAC figure
exists to report here. The CAC formula and worked figures this gate now
requires are content that phase-2 *users* of this role will produce in
their own records; this record documents the gate that will enforce that,
not an instance of it.

## LTV

Not applicable to this record, per the same scope note as CAC above — no
unit-economics analysis subject is in scope for issue-1.

## LTV:CAC ratio

Not applicable to this record, per the same scope note above.

## CAC payback period

Not applicable to this record, per the same scope note above.

## Sensitivity note

Not applicable to this record, per the same scope note above.

## Evidence — gate behavior verification

Ran `finance-unit-economics/hooks/produces-fields-gate.sh` directly
against two synthetic `PreToolUse` payloads targeting
`docs/issue-1/reports/finance-unit-economics.md`:

- All five fields present as bare headings, no numbers nearby → refused
  (`rc=2`): `finance-unit-economics: refused — finance-unit-economics.md
  field(s) present as heading only, with no numeric content nearby: cac,
  ltv, cac-payback-period, sensitivity-note`.
- All five fields present with numeric content (e.g. `$120 per customer`,
  `4.2 to 1 strong band`, `6 months`, `churn 5% vs 10% scenario`) →
  passed (`rc=0`, no output).

`bash -n` confirmed both edited scripts remain syntactically valid.

## Open findings

None. All phase-2 decision-requested items are complete: `directive.sh`
and `produces-fields-gate.sh` reflect the approved methodology,
`hooks.json` and `warrant-hunter.md` are confirmed unchanged per scope,
and the gate's new behavior is verified against both a failing and a
passing synthetic payload.
