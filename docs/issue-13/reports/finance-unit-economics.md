# issue-13 phase-2 record — gate A+ upgrade (audit remediation)

loop_state: landed

## What was done / why

Executed the approved phase-1 proposal
(`docs/issue-13/proposals/gate-a-plus-upgrade.md`, approved via the issue
comment `APPROVE issue-13/finance-unit-economics`): fixed all five audit
defects (survey.md §1-5) across all 7 gates in this plugin set
(`finance-unit-economics/hooks/produces-fields-gate.sh`,
`finance-evidence-chain`, `finance-proposal-shape`, `finance-ltv-cac-band`,
`finance-cac-payback`, `finance-sensitivity-scenario`,
`finance-ltv-churn-assumption`) by rewiring every gate onto core's shared
`gate-lib.sh`/`gate-lib.py` (issue-72, confirmed landed and installed as
the sibling `core` plugin at
`~/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core`)
instead of each gate's own hand-rolled JSON parse / kill switch / path
match / content extraction. This closes malformed-JSON-silent-allow
(now `gate_parse_json_or_deny`, denies), MultiEdit `edits[]` blindness
(now `gate_reconstruct_write`, honors each edit's own `replace_all`), and
un-normalized path matching (now `gate_normalize_path`, collapses `..`
before matching, anchored full-path regex instead of a bare `endswith`
suffix check) — necessary because a gate that can be silently bypassed by
malformed input, MultiEdit, or a crafted path cannot actually verify unit
economics soundness (단위경제상 성립하는가), which is this role's own
mandate every one of these gates exists to enforce. No canon script was
copied — `docs/handbooks/canon-scripts.md`'s reference-not-copy rule is
respected; each gate sources `gate-lib.sh` via
`${CLAUDE_PLUGIN_ROOT_CORE:-<plugin>/../../core}/hooks/lib/gate-lib.sh`,
the same resolution convention `finance-unit-economics/hooks/
directive.sh` already used for `role-directive.sh`.

Semantic checks upgraded from flat substring to
section/paragraph/windowed-adjacency per proposal §2's table:
`produces-fields-gate.sh` now requires each PRODUCES field as its own
markdown heading with numeric content scoped to that heading's own
section body; `evidence-chain-gate.sh` now requires the mandate word and
causal word in the SAME paragraph; `proposal-shape-gate.sh` now requires
`Decision requested` as a heading, not a body phrase;
`cac-payback-gate.sh` now requires cac/arpu within 150 chars of a
`payback` occurrence; `sensitivity-scenario-gate.sh` now counts scenario
labels only within the sensitivity/scenario section itself;
`ltv-churn-assumption-gate.sh` keeps its existing 60-char churn window
but additionally scopes it to the section containing the LTV occurrence.
`ltv-cac-band-gate.sh`'s existing 120-char proximity check (already the
best-in-repo precedent) is functionally unchanged, only its plumbing
migrated.

Audit item 4 (README) is reconciled: the Layout section now lists only
files that exist (the three ghost entries —
`record-fields-gate.sh`/`trailer-gate.sh`/`handbook-trigger-gate.sh` —
removed and replaced with an explicit statement that core's canon copies
cover that ground), and every kill-switch env var name is documented in
one table.

Audit item 5 (deny-reason delivery) was not independently reproducible
by static reading per survey.md §5; the migrated gates continue writing
denials to `sys.stderr` uniformly via each gate's own `deny()` wrapper,
and the mandatory test suite (below) asserts on captured stderr output
for every deny case, closing the gap the survey flagged (no prior test
exercised stderr capture at all).

## Upstream basis

`docs/issue-13/proposals/gate-a-plus-upgrade.md` (this issue's approved
proposal), `docs/issue-13/reports/finance-unit-economics/survey.md`
(audit-claim reproduction), core issue #72's landed
`core/hooks/lib/gate-lib.sh` + `gate-lib.py` +
`docs/handbooks/gate-house-standard.md` (the referenced shared library —
confirmed landed via the installed core plugin, commit
`22a7cadef5c1389433d130bb4c9742863fbe47c0`, 2026-08-01), core's own
`core/hooks/record-fields-gate.sh` (the canonical migration shape this
issue's 7 gates were adapted from).

## Open findings

None outstanding for this pass. `finance-unit-economics/agents/
warrant-hunter.md` and `finance-unit-economics/hooks/directive.sh` were
left unchanged (out of this issue's scope). The proposal's §0 precondition
check was re-verified at phase-2 start: core issue #72 has landed (its
`gate-lib.sh`/`gate-lib.py` interface matched proposal §1's contract with
no renames needed) and `core/hooks/tests/compliance-check.sh` (issue-72's
own compliance detector) runs clean against this repo's `hooks/`
directory — 7/7 gates `ok`, 0 flagged — recorded as evidence per the
gate-house-standard handbook's per-repo migration checklist step 4.

## Unit-economics record (this issue's own PRODUCES fields)

## cac

$0 this cycle — no customer acquisition spend was made for this
implementation issue (rulebook-tooling audit remediation, not a priced
product/feature launch).

## ltv

Not applicable this cycle: no priced offering changed. Working from
named-framework assumption, not fabricated citation: LTV would be
computed on contribution margin with the existing 5% monthly churn
baseline per `docs/issue-1/reports/finance-unit-economics/
scout-brief.md`, carried forward unchanged by this issue.

## ltv-cac-ratio

n/a this cycle (no CAC spend, no LTV change); ratio interpretation stays
at the existing 3:1 floor / 4:1-5:1 strong / <2:1 red flag bands,
unchanged by this gate-plumbing work.

## cac-payback-period

n/a this cycle: CAC / (Monthly ARPU x Gross Margin %) = $0 / (existing
ARPU x existing margin) = 0 months, since CAC is $0.

## sensitivity-note

base case: gate-lib migration adds one `importlib.util` module-load per
PreToolUse write on a matching path (7 gates), a few ms of Python
subprocess-startup overhead, no measurable cost impact. downside: if the
sibling `core` plugin is not installed (`CLAUDE_PLUGIN_ROOT_CORE`
unresolvable and no `../../core` sibling), every gate in this set fails
closed (denies every matching write, per `gate_trap_fail_closed`) rather
than silently passing — intended fail-closed behavior, not a defect, but
worth calling out since it makes core's own install a hard runtime
dependency for this plugin set, not just a build-time one.

## Gate tests

`tests/produces-fields-gate.test.sh` (new — this gate previously shipped
with no test file at all), `tests/evidence-chain-gate.test.sh`,
`tests/proposal-shape-gate.test.sh`, `tests/ltv-cac-band-gate.test.sh`,
`tests/cac-payback-gate.test.sh`, `tests/sensitivity-scenario-gate.test.sh`,
`tests/ltv-churn-assumption-gate.test.sh` — each covers, per issue-13's
mandatory case list: malformed JSON (deny), MultiEdit-introduced content
(deny, parity with Write), a `..`-traversal path that still ends in the
matched suffix (no-op/allow), an absolute-path fixture (same verdict as
the equivalent relative path), a kill-switch unrecognized value (stays
denying) and a recognized on-value (disables), plus one adjacency/
structural regression pair per gate's §2 upgrade row. `evidence-chain-gate.test.sh`
and `proposal-shape-gate.test.sh` additionally cover `CLAUDE_ROLE`
genuinely unset (gate still evaluates, does not no-op). All 7 pass
locally (`bash tests/<name>.test.sh`, exit 0 each; 77 assertions total,
0 failures) and `core/hooks/tests/compliance-check.sh` run against this
repo's `hooks/` directory reports 7/7 `ok`.
