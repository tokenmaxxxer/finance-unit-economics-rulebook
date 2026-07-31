# issue-10 phase-2 record — finance-unit-economics methodology enforcement as a plugin set

loop_state: landed

## What was done / why

Executed the approved phase-1 proposal
(`docs/issue-10/proposals/methodology-enforcement.md`, approved via the
issue comment `APPROVE issue-10/finance-unit-economics`): the adopted
finance-unit-economics methodology (`docs/issue-1/proposals/
rulebook-maturation.md`) is now mechanically enforced as a set of six
independently registerable plugins, instead of remaining a one-line
directive summary plus unenforced documentation. Each plugin owns
exactly one methodology concern, fail-closed, self-contained
(`.claude-plugin/plugin.json`, `hooks/hooks.json`, gate script, own
kill switch), and is registered standalone in `.claude-plugin/
marketplace.json`. No canon script was copied — each gate is a new,
role-owned script the same shape `pricing-rulebook`'s own role-owned
`methodology-gate.sh` used, split one concern per file.

## Upstream basis

`docs/issue-1/proposals/rulebook-maturation.md` (methodology adoption),
`docs/issue-1/reports/finance-unit-economics/scout-brief.md` (LTV:CAC
bands), `docs/issue-10/proposals/methodology-enforcement.md` (this
issue's revised phase-1 plugin-set proposal).

## Open findings

None outstanding for this pass. The `finance-unit-economics` base
plugin's `agents/warrant-hunter.md`, `hooks/directive.sh`, and
`hooks/produces-fields-gate.sh` were left unchanged per the proposal's
§2/§5 calls and this issue's constraint against touching canon-adjacent
stubs outside scope.

## Plugins added

- `finance-evidence-chain` — phase-1: every adopted metric sourced or
  assumption-labeled, chained to this role's own mandate (two-signal
  chain: mandate word + causal-necessity word).
- `finance-proposal-shape` — phase-1: proposal names a concrete
  phase-2 reflection plan (`produces`/`REQUIRED_FIELDS`) and a
  "Decision requested" section.
- `finance-ltv-cac-band` — phase-2: LTV:CAC ratio carries a band
  judgment (≥3:1 floor / 4:1-5:1 strong / <2:1 red flag) proximate to
  the ratio token, not merely present anywhere in the file.
- `finance-cac-payback` — phase-2: CAC payback period shows its
  formula inputs (CAC, ARPU) visibly next to the number.
- `finance-sensitivity-scenario` — phase-2: sensitivity section
  carries at least two distinct labeled numeric scenarios.
- `finance-ltv-churn-assumption` — phase-2: LTV figure states its
  churn-rate/NDR assumption explicitly, separate from the LTV:CAC band
  judgment.

## Unit-economics record (this issue's own PRODUCES fields)

- **CAC** — no new customer acquisition spend was made for this
  implementation issue (rulebook-tooling work, not a priced
  product/feature launch); CAC is $0 this cycle, ARPU unaffected.
- **LTV** — not applicable this cycle: no priced offering changed.
  Working from named-framework assumption, not fabricated citation:
  LTV would be computed on contribution margin with an assumed 5%
  monthly churn baseline per `docs/issue-1/reports/
  finance-unit-economics/scout-brief.md`, carried forward unchanged
  by this issue.
- **LTV:CAC ratio** — n/a this cycle (no CAC spend, no LTV change);
  ratio interpretation stays at the existing 3:1 floor / 4:1-5:1
  strong / <2:1 red flag bands, unchanged by this plugin-set work.
- **CAC payback period** — n/a this cycle: CAC / (Monthly ARPU × Gross
  Margin %) = $0 / (existing ARPU × existing margin) = 0 months, since
  CAC is $0.
- **Sensitivity/scenario section** — base case: plugin-set adds gate
  latency of roughly 1-5ms per PreToolUse write (six additional
  Python-subprocess gates on matching paths), no measurable cost
  impact. Downside: if `python3` is unavailable on a contributor's
  PATH, every gate in the set fails closed (denies the write) rather
  than silently passing, per each gate's `deny "requires python3..."`
  branch — this is the intended fail-closed behavior, not a defect.

## Gate tests

`tests/evidence-chain-gate.test.sh`, `tests/proposal-shape-gate.test.sh`,
`tests/ltv-cac-band-gate.test.sh`, `tests/cac-payback-gate.test.sh`,
`tests/sensitivity-scenario-gate.test.sh`,
`tests/ltv-churn-assumption-gate.test.sh` — each covers allow/deny
cases per the proposal §6 table, a foreign-path no-op case, and its
kill switch. All six pass locally (`bash tests/<name>.test.sh`, exit 0).
