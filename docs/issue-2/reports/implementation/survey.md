# issue-2 phase-1 current-state survey — core canon reference transition

## Scope

issue #2 asks this rulebook (`finance-unit-economics`) to stop vendoring copies
of machinery core has since promoted to canon (core issue #63: warrant-hunt;
core issue #66: the three role-agnostic gates + the directive.sh
boilerplate), and to reference core canon instead. This is a current-state
survey only — no code change lands in this phase.

Scout skip record: this issue is an internal interaction-protocol/infra
refactor bound entirely by contract v3 and the two already-landed core PRs
(core #63/#66) — there is no external product category or comparable field
to benchmark against, and the decisions in scope (path resolution, which
role-unique bits survive) are fixed by reading core's own source, not by
market comparison. Scouting is skipped per the "spec leaves no external
design surface open" condition; this survey substitutes a direct read of
the core canon source (below) for the scout sweep.

## This repo's current vendored copies

| File | Role-agnostic in core? | Notes |
|---|---|---|
| `finance-unit-economics/agents/warrant-hunter.md` | yes (core #63, `core/warrant/` plugin) | header explicitly says "adapted from implementation-rulebook's agents/warrant-hunter.md" — a copy, not role-authored from scratch, except the mandate/stance text |
| `finance-unit-economics/hooks/trailer-gate.sh` | yes (core #66) | our copy's logic is byte-equivalent in shape to core's; only role-token substitution (`FINANCE_UNIT_ECONOMICS_PAYLOAD` env name, message prefix) differs |
| `finance-unit-economics/hooks/handbook-trigger-gate.sh` | yes (core #66) | our copy is an explicit placeholder (`exit 0 # placeholder verdict`); core's version is the real, hardened implementation (operational-surface pattern list + handbook-touched check) |
| `finance-unit-economics/hooks/record-fields-gate.sh` | **partially** — see gap below | our copy enforces this role's own PRODUCES fields (`unit-economics-model`, `sensitivity-note`); core's canon copy enforces contract §20's generic structural fields (what/why/upstream/loop_state/open-findings) and does **not** know this role's field names |
| `finance-unit-economics/hooks/directive.sh` | n/a — directive.sh stays per-role by design | core ships `hooks/lib/role-directive.sh` with `core_role_directive()`; every role's directive.sh becomes a ~10-line stub sourcing it and passing 4 role-unique strings |
| `finance-unit-economics/hooks/hooks.json` | registers the 3 gates locally | core's own `hooks.json` already fires `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh` (and `board-gate.sh`/`approval-gate.sh`/`gh-guard.sh`) globally via `"matcher": ".*"` for every role, once core is installed as a plugin — confirmed empirically: `board-gate.sh` (core-only, never vendored here) already fired against this very session before any of today's changes |

## Gap found: record-fields-gate.sh is not a pure duplicate

Core's `record-fields-gate.sh` (core issue #66) checks contract §20's
role-agnostic structural minimum (what-was-done / why / upstream / own
loop_state / open-findings, plus next-steps when loop_state is
non-terminal). It has **no knowledge of any role's PRODUCES list**. Our
local copy instead hardcodes `REQUIRED_FIELDS = ["unit-economics-model",
"sensitivity-note"]` — this role's own PRODUCES fields from
`roles/finance-unit-economics.json` (per issue-170). Deleting our copy and
relying on core's canon copy alone would **drop the PRODUCES-field
enforcement**, not just deduplicate it. Core's file offers no injected-config
point for role-specific required fields (unlike its `RECORD_FIELDS_
TERMINAL_STATES` env var for the loop_state-terminality axis). This is a
genuine behavior difference, not copy-paste drift, and is the one place in
the issue's task list phase 1 must flag for a phase-2 design decision
rather than a mechanical stub.

## RECORD_FIELDS_TERMINAL_STATES (task item 4)

Core's `record-fields-gate.sh` supports a `RECORD_FIELDS_TERMINAL_STATES`
env var (space-separated `loop_state` values) precisely for the case where
a role's terminal states genuinely differ from core's default. This role's
rulebook is still skeleton (issue-170) and has not yet defined its own
`loop_state` vocabulary or written a real record, so there is no evidence
yet of a role-specific terminal-state set to preserve. Flagged as open in
the proposal rather than guessed.

## Install mechanism (no `plugin.json`/marketplace dependency exists)

`finance-unit-economics/.claude-plugin/plugin.json` declares no dependency
on core, and `.claude-plugin/marketplace.json` lists only this repo's own
plugin. Yet core's own gates (`board-gate.sh`, `approval-gate.sh`,
`gh-guard.sh`) already fire in this very session (confirmed: a `cd` outside
the sandboxed worktree was refused by `board-gate.sh`, a core-only file
never vendored in this repo). Core install is therefore orchestrated
outside this repo's own manifest (session/marketplace configuration at the
platform level), not by a `plugin.json` dependency field. Phase 1's
proposal does not need to add a dependency declaration to make core's
already-registered hooks fire; it only needs to stop this repo's own
`hooks.json` from re-registering copies core already covers.

## `core/hooks/tests/stub-check.sh`

Read in full. It (a) fails if any of the three canon gate filenames are
found anywhere under a rulebook's `hooks/` tree (drift signal), and (b)
structurally validates `directive.sh`: every non-blank/non-comment line
must be the `role-directive.sh` source line, a plain variable assignment,
or the `core_role_directive` call — anything else (a case statement, a
guard, a raw `cat`/`echo`) fails as "regrown boilerplate." This is the
acceptance check task item 5 asks phase 2 to run and record the result of.
