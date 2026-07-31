# issue-10 phase-1 survey — finance-unit-economics current-state

## What exists today

- `finance-unit-economics/hooks/directive.sh` — sources core's
  `role-directive.sh` and supplies four one-line strings (`YOU DECIDE`,
  `USE_WHEN`, `PRODUCES`, `HAND-OFF`), echoed verbatim at `SessionStart`.
  No phase distinction, no judgment criteria, no prohibitions — a single
  summary line per facet.
- `finance-unit-economics/hooks/produces-fields-gate.sh` — a `PreToolUse`
  gate scoped only to `docs/issue-<n>/reports/finance-unit-economics.md`
  (the phase-2 record). Checks five field labels
  (`cac, ltv, ltv-cac-ratio, cac-payback-period, sensitivity-note`) are
  present, and that four of them carry a numeric token nearby. This is
  the phase-2 reflection landed by issue-1 (`docs/issue-1/proposals/
  rulebook-maturation.md` (b)/(d)).
- `finance-unit-economics/hooks/hooks.json` — registers `directive.sh` on
  `SessionStart` and `produces-fields-gate.sh` on
  `Write|Edit|MultiEdit|NotebookEdit`.
- `finance-unit-economics/agents/warrant-hunter.md` — a thin stub over
  core's `warrant/` plugin (issue-2 core-canon-reference transition),
  explicitly out of this issue's scope per issue-1's own scope note.
- No `docs/handbooks/finance-unit-economics/` directory — no worked
  reasoning doc exists for why the five fields are the right five, unlike
  the sibling `pricing-rulebook`'s
  `docs/handbooks/pricing/methodology.md`.
- No repo-root `tests/` directory — no gate has an automated pass/fail
  test in this repo, unlike `implementation-rulebook`'s
  `tests/run-gate-tests.sh`.

## Gaps against issue-10's four asks

1. **Directive depth** — `PRODUCES` is one line
   (`"unit economics record (CAC, LTV on margin, LTV:CAC ratio + band,
   CAC payback period), sensitivity/scenario section with numbers"`).
   It names *what* fields, not *how to judge* them (e.g. what "strong"
   vs. "red flag" means for the ratio, what counts as an adequate
   sensitivity scenario) or *what is forbidden* (e.g. claiming a
   ratio verdict with no band interpretation, a sensitivity heading with
   no second scenario). Phase-1/phase-2 are not distinguished in the
   directive text at all — `produces-fields-gate.sh` only fires on the
   phase-2 record path; nothing currently gates the phase-1 proposal's
   own methodology quality (evidence chain, source labeling,
   phase-2-reflection-plan shape) the way `pricing-rulebook`'s
   `methodology-gate.sh` gates *both* surfaces.
2. **Methodology gate** — `produces-fields-gate.sh` checks field
   *presence* and *a nearby number*, but not field *quality*: an
   `ltv-cac-ratio` section with a bare number and no band judgment passes
   today, as does a `sensitivity-note` section with exactly one scenario
   (issue-1's proposal (b).5 requires "at least two scenarios," but the
   current gate never counts scenarios). It also does not touch the
   phase-1 proposal surface at all.
3. **Gate tests** — none exist for `produces-fields-gate.sh` today; a
   regression here would only surface in production.
4. **Agents/checklist** — no checklist doc exists; whether one is
   warranted is an open call this proposal must make.

## Sequencing question (issue-10's "조사→근거→채택" example)

The issue names ordering enforcement as conditional ("방법론상 순서
제약이 있으면"). This role's adopted methodology
(`docs/issue-1/proposals/rulebook-maturation.md` (a).3) states the
evidence chain as something each phase-1 proposal must show *within the
same document* (field evidence → mandate → necessity, all in one write),
not as a sequence of separate gated writes with a hard temporal order
between them (contrast `implementation-rulebook`'s coding role, where
`hunt-state.sh` tracks a survey-before-hunt state machine across
*distinct* write events). Whether that intra-document framing is
sufficient, or whether phase separation itself (proposal write must
precede record write) needs cross-write state tracking, is resolved in
the proposal below.
