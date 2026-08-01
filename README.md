# finance-unit-economics-rulebook

Rulebook for the `finance-unit-economics` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 단위경제상 성립하는가
- **use_when**: 가격/비용 구조가 걸린 결정일 때
- **produces**: unit economics model (CAC/LTV/margin), sensitivity note
- **write_scope**: []
- **hand-off**: 실제 가격 숫자 결정은 → pricing

## Install

```
claude plugin marketplace add tokenmaxxxer/finance-unit-economics-rulebook
claude plugin install finance-unit-economics
```

## Layout

This repo ships one base plugin plus six satellite plugins, each a
`PreToolUse` gate on `Write|Edit|MultiEdit|NotebookEdit`. Role-agnostic
concerns (contract §20 record-field minimum, commit trailer, handbook
sync) are enforced by core's own canon gates
(`record-fields-gate.sh`/`trailer-gate.sh`/`handbook-trigger-gate.sh`,
installed as the sibling `core` plugin) — this repo does not vendor
copies of them.

- `finance-unit-economics/.claude-plugin/plugin.json` — base plugin manifest
- `finance-unit-economics/hooks/hooks.json` — SessionStart + PreToolUse wiring
- `finance-unit-economics/hooks/directive.sh` — SessionStart role directive
- `finance-unit-economics/hooks/produces-fields-gate.sh` — this role's own
  PRODUCES-field gate (cac/ltv/ltv-cac-ratio/cac-payback-period/
  sensitivity-note as headings, each with numeric content in its own
  section); the role-agnostic §20 minimum core's `record-fields-gate.sh`
  has no per-role hook for
- `finance-unit-economics/agents/warrant-hunter.md` — rotating-stance hunt agent
- `finance-evidence-chain/hooks/evidence-chain-gate.sh` — every metric
  named in a phase-1 proposal sourced or assumption-labeled, chained to
  this role's mandate within the same paragraph
- `finance-proposal-shape/hooks/proposal-shape-gate.sh` — phase-1
  proposal names a phase-2 reflection plan and a `## Decision requested`
  heading
- `finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh` — LTV:CAC ratio
  carries a band judgment within 120 chars of the ratio token
- `finance-cac-payback/hooks/cac-payback-gate.sh` — CAC payback period
  shows CAC/ARPU inputs within 150 chars of the `payback` occurrence
- `finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh` — the
  sensitivity/scenario section itself carries >=2 distinct labeled scenarios
- `finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh` — an
  LTV figure states its churn/NDR assumption within the same section
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

Each satellite plugin is self-contained
(`<plugin>/.claude-plugin/plugin.json`, `<plugin>/hooks/hooks.json`,
its own gate script) and registered standalone in
`.claude-plugin/marketplace.json`.

### Kill switches

Every gate fails closed (malformed JSON, an internal error, or an
unrecognized `_OFF` value all deny/stay active — only a recognized
on-spelling `1`/`true`/`yes`/`on` disables a gate, per core's
`gate_kill_switch_active`, issue-72). Env vars, one per gate:

| Plugin | Kill switch |
|---|---|
| `finance-unit-economics` (produces-fields-gate.sh) | `FINANCE_UNIT_ECONOMICS_CYCLE_OFF` |
| `finance-evidence-chain` | `FINANCE_EVIDENCE_CHAIN_GATE_OFF` |
| `finance-proposal-shape` | `FINANCE_PROPOSAL_SHAPE_GATE_OFF` |
| `finance-ltv-cac-band` | `FINANCE_LTV_CAC_BAND_GATE_OFF` |
| `finance-cac-payback` | `FINANCE_CAC_PAYBACK_GATE_OFF` |
| `finance-sensitivity-scenario` | `FINANCE_SENSITIVITY_SCENARIO_GATE_OFF` |
| `finance-ltv-churn-assumption` | `FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF` |

### Gate-lib reference (issue-72 / issue-13)

Every gate above sources core's shared `gate-lib.sh`/`gate-lib.py`
(`${CLAUDE_PLUGIN_ROOT_CORE:-<plugin>/../../core}/hooks/lib/`) by
reference, never by copy, for fail-closed JSON parsing, absolute-path
normalization, and full `Write`/`Edit`/`MultiEdit` content
reconstruction (`replace_all`-honoring). See
`docs/issue-13/reports/finance-unit-economics.md` for the migration
record and `tests/*.test.sh` for the mandatory input-plumbing/adjacency
regression suite.
