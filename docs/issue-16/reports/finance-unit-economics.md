# issue-16 phase-2 record — gate A+ final closeout (source guard)

loop_state: landed

## What was done / why

Executed the approved phase-1 proposal
(`docs/issue-16/proposals/2026-08-01-gate-a-plus-final-closeout.md`,
approved via the issue comment `APPROVE issue-16/finance-unit-economics`,
single-account mode): applied core issue #75's confirmed guarded
source-line form, verbatim, to all 7 of this plugin set's gate scripts —
`finance-unit-economics/hooks/produces-fields-gate.sh`,
`finance-evidence-chain/hooks/evidence-chain-gate.sh`,
`finance-proposal-shape/hooks/proposal-shape-gate.sh`,
`finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh`,
`finance-cac-payback/hooks/cac-payback-gate.sh`,
`finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh`,
`finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh`. Each
gate's `gate-lib.sh` source line now reads
`... || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`,
closing the fail-open path survey.md §1 found: an unguarded source that
fails when `CLAUDE_PLUGIN_ROOT_CORE` is unreachable leaves
`gate_kill_switch_active` undefined, which every gate's own
`gate_kill_switch_active ... || { exit 0; }` call site then reads as
"kill switch off" — silently allowing every write. This closes the one
input class (missing/misresolved core plugin root) not yet covered by
issue-13's A+ migration, necessary because this role's mandate (단위경제상
성립하는가) is enforced entirely by these 7 `PreToolUse` gates and a gate
that can silently fail open cannot verify that mandate at all in that
topology. No other line in any of the 7 scripts changed — additive only,
per core #75's own constraint on itself.

Per proposal §2, ported core #75's mandatory group-7 missing-core case
into each of the 7 `tests/*.test.sh` files: each new case points
`CLAUDE_PLUGIN_ROOT_CORE` at a nonexistent path and asserts the gate now
denies with exit code 2 (not the prior unguarded 127/traceback shape, and
not silent-allow). Full suite (existing cases + the 7 new missing-core
cases) ran green in the same commit that shipped the guard fix.

Per proposal §3, re-ran core's `compliance-check.sh`
(`tokenmaxxxer/tokenmaxxxer-core` PR #77, issue #75, installed at
`~/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core`)
against all 7 `hooks/` directories post-fix: 7/7 `ok`, 0 flagged — the
delta against survey.md's pre-fix baseline (7/7 `FAIL`, same check, same
directories) is the acceptance signal per the proposal's phase-2
reflection plan.

Per proposal §4, requirements 2 (hooks.json matcher/code coverage parity)
and 4 (README/manifest ghost-file/old-name cleanliness) took no action —
survey.md verified both already clean by direct execution/read, not by
trusting the issue's "잔여 없음" line, and this record cites that
verification rather than re-deriving it.

## Upstream basis

`docs/issue-16/proposals/2026-08-01-gate-a-plus-final-closeout.md` (this
issue's approved proposal), `docs/issue-16/reports/finance-unit-economics/survey.md`
(pre-fix 7/7-fail baseline, real-execution reproduction), core issue #75 /
PR #77 (`tokenmaxxxer/tokenmaxxxer-core`, merged commit `52bdc15`) —
the confirmed guarded source-line form, its `compliance-check.sh`
detection rule, and the mandatory group-7 missing-core test shape, all
reference-adopted here per `docs/handbooks/canon-scripts.md`'s
reference-not-copy rule (no canon script vendored; each gate continues to
source `gate-lib.sh` via
`${CLAUDE_PLUGIN_ROOT_CORE:-<plugin>/../../core}/hooks/lib/gate-lib.sh`,
now with the `||` guard appended on the same line).

## Open findings

None outstanding for this pass.

## Compliance-check record (before/after)

- **Before** (survey.md baseline, pre-fix, this repo's 7 `hooks/`
  directories against core's `compliance-check.sh`): 7/7 `FAIL` — every
  gate flagged "sources gate-lib.sh with no || guard on the same line —
  fail-open when core is unreachable".
- **After** (this commit, same check, same 7 directories): 7/7 `ok`, 0
  flagged.

## Gate tests

All 7 `tests/*.test.sh` files pass green, including the 7 new
missing-core cases (`CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent
path asserts exit 2, not silent-allow): `produces-fields-gate.test.sh`,
`evidence-chain-gate.test.sh`, `proposal-shape-gate.test.sh`,
`ltv-cac-band-gate.test.sh`, `cac-payback-gate.test.sh`,
`sensitivity-scenario-gate.test.sh`, `ltv-churn-assumption-gate.test.sh` —
`bash tests/<name>.test.sh`, exit 0 each, no regressions in any
pre-existing case.

## Unit-economics record (this issue's own PRODUCES fields)

## cac

$0 this cycle — no customer acquisition spend was made for this
implementation issue (rulebook-tooling gate-hardening, not a priced
product/feature launch).

## ltv

Not applicable this cycle: no priced offering changed. Working from
named-framework assumption, not fabricated citation: LTV would be
computed on contribution margin with the existing 5% monthly churn
baseline per `docs/issue-1/reports/finance-unit-economics/scout-brief.md`,
carried forward unchanged by this issue.

## ltv-cac-ratio

n/a this cycle (no CAC spend, no LTV change); ratio interpretation stays
at the existing 3:1 floor / 4:1-5:1 strong / <2:1 red flag bands,
unchanged by this gate-plumbing work.

## cac-payback-period

n/a this cycle: CAC / (Monthly ARPU x Gross Margin %) = $0 / (existing
ARPU x existing margin) = 0 months, since CAC is $0.

## sensitivity-note

base case: the added `|| exit 2` guard runs only on the source-failure
path (core unreachable), so it adds zero measurable cost when core
resolves normally, which is every real install. downside: if the sibling
`core` plugin is genuinely absent or misresolved, every gate in this set
now denies deterministically (exit 2, one stderr line naming the gate)
instead of the prior undefined 127/kill-switch-silent-allow shape — this
is the intended fail-closed behavior the fix exists to produce, not a
regression; the operational cost is that a broken core install now blocks
writes loudly instead of passing silently, which is exactly the tradeoff
this issue asked for.
