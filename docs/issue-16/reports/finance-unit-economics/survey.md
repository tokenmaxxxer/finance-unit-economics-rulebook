# issue-16 survey — gate A+ final closeout, real-code re-audit against the confirmed core standard

## Scope

Issue #16's body states "잔여 없음 — 확인 감사만" (no residual defects —
confirmation audit only) but still lists 4 concrete requirements and two
landed common preconditions to apply by reference: core issue #75
(gate-lib source-guard mandate + compliance-check detection + missing-core
mandatory test + `gate_bash_write_targets` py port) and on-the-record
issue #182 (`CLAUDE_PLUGIN_ROOT_CORE` injection in `spawn.py`). This
survey re-verifies each requirement against the actual files in this repo
as of `a5847f4` (issue-13's landed gate-lib migration), not against the
issue's own "no residuals" claim, because that claim predates core #75
landing (`tokenmaxxxer/tokenmaxxxer-core` PR #77, merged) and this repo's
gates were migrated to gate-lib *before* #75 existed.

## Scout skip record

Skip condition 2 applies: this task has no open design decision. Core
issue #75 already fixed the exact defect class in question and shipped
the canonical guarded source-line form, the `compliance-check.sh` check
that flags its absence, and the mandatory missing-core test shape — all
in `docs/handbooks/gate-house-standard.md` and
`core/hooks/tests/run-gate-lib-tests.sh` (cloned and read directly,
`tokenmaxxxer/tokenmaxxxer-core` PR #77). This role's remedy is to
reference-adopt that exact confirmed form, not to design a new one — the
same principle issue-13's proposal already applied ("core owns *how* a
gate safely reads its input... this role owns *what* the gate checks
for"). No scout sweep run.

## Requirement 1 — apply core #75's confirmed guard/rules

**Residual defect confirmed, contradicting the issue's "잔여 없음" note.**
All 7 gate scripts in this repo source `gate-lib.sh` without the `||`
guard core #75 made mandatory:

```
finance-cac-payback/hooks/cac-payback-gate.sh:19
finance-evidence-chain/hooks/evidence-chain-gate.sh:20
finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh:21
finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh:21
finance-proposal-shape/hooks/proposal-shape-gate.sh:16
finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh:19
finance-unit-economics/hooks/produces-fields-gate.sh:21
```

each line reads:

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

with no `|| { echo ... >&2; exit 2; }` fallback. Verified two ways:

1. Static grep — no `||` on any of the 7 lines.
2. **Real execution**: cloned `tokenmaxxxer/tokenmaxxxer-core` (PR #77,
   merged, contains the confirmed fix) and ran its actual
   `core/hooks/tests/compliance-check.sh` against each of this repo's 7
   `hooks/` directories. All 7 fail identically:
   ```
   compliance-check: FAIL — <gate>.sh:
     - sources gate-lib.sh with no || guard on the same line — fail-open
       when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)
   ```

**Mechanism** (per core #75's own doc comment, reproduced here because it
is the reason this is not cosmetic): if the source fails when core is
unreachable, no `gate_*` function is defined, `gate_kill_switch_active`
then resolves to "command not found" (exit 127), and every gate's own
`gate_kill_switch_active ... || { trap - EXIT; exit 0; }` call site reads
that 127 as "kill switch off" — **silently allowing every write**. This is
exactly the class of defect issue-13 already fixed for malformed-JSON
(survey.md §1's "silent allow, not deny") but the source line itself was
never in scope until core #75 named it.

`on-the-record #182` (`CLAUDE_PLUGIN_ROOT_CORE` injection in `spawn.py`)
does not change this analysis: the guard's job is to fail closed
regardless of *why* the variable is unset or points nowhere — injection
correctness upstream is not a substitute for the gate itself failing
closed on a bad value.

## Requirement 2 — hooks.json matcher / code coverage parity

**No residual defect found.** All 7 `hooks.json` files use the identical
matcher `Write|Edit|MultiEdit|NotebookEdit`
(`finance-*/hooks/hooks.json:5` or `:12` for the base plugin). Every gate
script's Python body reads `tool_input.file_path` / `.notebook_path` only
and branches on no other tool name — no gate references `"Bash"` or
`gate_bash_write_targets` anywhere (`grep -n "Bash\|gate_bash_write_targets"`
across all 7 `*-gate.sh` returned zero hits inside the Python bodies).
Checked the inverse direction too: no `tests/*.test.sh` constructs a
`"tool_name": "Bash"` payload that would exercise an unreachable branch —
all test payloads use `Write`/`Edit`/`MultiEdit`, matching what the
matcher actually advertises. Advertised and tested surface is identical
to production-reachable surface; nothing to fix here.

## Requirement 3 — missing-core case, full suite green, compliance-check record

- **Existing suite green, confirmed by direct execution** (not assumed):
  ran all 7 `tests/*.test.sh` files individually
  (`bash tests/produces-fields-gate.test.sh`, etc.) — all PASS, no
  failures, across content-logic, malformed-JSON, MultiEdit-parity,
  kill-switch, and path-normalization cases.
- **Missing-core case: absent.** `grep -n "missing-core" tests/*.sh`
  returns nothing. Core #75 made this case mandatory group 7 of
  `run-gate-lib-tests.sh` (`CLAUDE_PLUGIN_ROOT_CORE` pointed at a
  nonexistent path with no valid relative fallback → guarded source line
  must deny/exit 2, not silently allow). This repo's own test files have
  no equivalent per-gate case, and cannot until requirement 1's guard is
  actually applied (there is currently nothing for such a case to assert
  correctly — an unguarded source line does source-fail into 127, not a
  deterministic exit 2).
- **compliance-check pass record: does not exist in this repo.**
  `grep -rl "compliance-check"` inside this repo's own tree returns only
  `docs/issue-13/reports/finance-unit-economics.md` (a prose mention of
  the concept, not a recorded pass/fail run). No record file shows this
  repo's hooks actually run against `compliance-check.sh` and pass. This
  survey's own run (requirement 1, above) is the first real execution on
  record — and it currently **fails**, 7/7, until requirement 1 is fixed.

## Requirement 4 — README/manifest ghost files, old role names

**No residual defect found**, re-verified independently of the issue's
own claim:

- `.claude-plugin/marketplace.json`'s 7 `source` paths
  (`./finance-unit-economics`, `./finance-evidence-chain`,
  `./finance-proposal-shape`, `./finance-ltv-cac-band`,
  `./finance-cac-payback`, `./finance-sensitivity-scenario`,
  `./finance-ltv-churn-assumption`) all resolve to directories that exist
  in the tree — no ghost entries.
- `README.md`'s Layout section (rewritten by issue-13, per that issue's
  §4/proposal requirement) lists exactly the files that exist:
  `finance-unit-economics/hooks/{hooks.json,directive.sh,produces-fields-gate.sh}`,
  `finance-unit-economics/agents/warrant-hunter.md`, and each of the 6
  satellite `hooks/*-gate.sh` files, all confirmed present via `find`. The
  three previously-ghost entries issue-13's survey found
  (`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`)
  are gone from the README; it instead states plainly that core's own
  canon gates cover that role-agnostic ground.
- No occurrence of a pre-issue-160 role name anywhere in `README.md`,
  `finance-unit-economics/.claude-plugin/plugin.json`, or
  `.claude-plugin/marketplace.json` — every plugin description and
  manifest name string reads `finance-unit-economics` (or one of the 6
  satellite plugin names, all issue-10-era, none pre-taxonomy).

## Net finding

3 of 4 requirements are already clean (2, 4, and the non-missing-core
half of 3). Requirement 1 (and its missing-core-test/compliance-check-record
consequence under requirement 3) is a genuine, currently-failing residual
defect, confirmed by running core's own `compliance-check.sh` against
this repo's actual gates, not by re-reading the issue's own "잔여 없음"
assertion. Proposal below scopes phase 2 to that one gap.
