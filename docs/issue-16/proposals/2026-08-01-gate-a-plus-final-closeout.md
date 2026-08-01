# issue-16 phase-1 proposal — gate A+ final closeout: apply core #75's confirmed source guard

Working from named-framework assumption, not fabricated citation, for
the cac/ltv/ltv:cac/payback/sensitivity field-quality bar itself — that
bar was already adopted in issue-1/issue-10 and re-affirmed at A+ level
in issue-13, and is not re-derived here. This proposal's own chain: the
source-guard fix is necessary because this role's mandate ("단위경제상
성립하는가") is enforced entirely by these 7 gates (cac/ltv/ltv:cac
band/payback/sensitivity, each a `PreToolUse` check), and a gate that
silently allows on a missing core cannot verify that mandate at all in
that topology — the fix is therefore chained directly to the mandate,
not to general industry convention.

Grounded in `docs/issue-16/reports/finance-unit-economics/survey.md`,
which independently re-ran core's own landed `compliance-check.sh`
(`tokenmaxxxer/tokenmaxxxer-core` PR #77, issue #75) against all 7 of
this role's gate directories and got 7/7 real FAILs on the missing `||`
source guard — not a re-statement of the issue's own "잔여 없음" line,
which predates #75 landing. Every fix below is necessary because this
role's own mandate (단위경제상 성립하는가) is enforced entirely by these 7
`PreToolUse` gates: a gate whose `gate-lib.sh` source line silently
degrades to a 127-reads-as-kill-switch-off allow the moment
`CLAUDE_PLUGIN_ROOT_CORE` is unreachable is not enforcing the mandate at
all in that topology, it is only enforcing it when core happens to be
reachable — the same "appearance of enforcement" argument issue-13's
proposal already made about malformed JSON and MultiEdit blindness,
now extended to the one input class (a missing/misresolved core plugin
root) issue-13 could not see because core issue #75 (the source of the
confirmed guard shape) had not yet landed at that time. **Phase 1 ONLY —
no hook, test, or manifest file is created or edited in this pass; this
document specifies what phase 2 must build, and does not request
approval for phase 2 to start.**

## 1. Apply the guard verbatim, all 7 gates

Per survey.md requirement 1 and core #75's own usage comment
(`core/hooks/lib/gate-lib.sh`, confirmed by direct read of the merged
PR #77 diff), every one of this role's 7 gate scripts' source line
changes from:

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

to the guarded form, one stderr message per gate naming itself (matching
the pattern all 7 of core's own gates already carry post-#75):

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
```

Applies to, verbatim except the `<gate-name>.sh` token:

| File | `<gate-name>.sh` token |
|---|---|
| `finance-unit-economics/hooks/produces-fields-gate.sh` | `produces-fields-gate.sh` |
| `finance-evidence-chain/hooks/evidence-chain-gate.sh` | `evidence-chain-gate.sh` |
| `finance-proposal-shape/hooks/proposal-shape-gate.sh` | `proposal-shape-gate.sh` |
| `finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh` | `ltv-cac-band-gate.sh` |
| `finance-cac-payback/hooks/cac-payback-gate.sh` | `cac-payback-gate.sh` |
| `finance-sensitivity-scenario/hooks/sensitivity-scenario-gate.sh` | `sensitivity-scenario-gate.sh` |
| `finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh` | `ltv-churn-assumption-gate.sh` |

No other line in any of the 7 scripts changes — survey.md confirmed
requirements 2 and 4 (matcher/code parity, README/manifest cleanliness)
are already clean, and the guard fix is additive only (core #75's own
constraint on itself, carried forward here: "no public function's
existing behavior changed").

## 2. Add the missing-core mandatory case to each gate's test file

Per survey.md requirement 3, port core #75's mandatory group 7 shape
(`run-gate-lib-tests.sh`) into each of this repo's 7
`tests/*.test.sh` files: one case per gate, `CLAUDE_PLUGIN_ROOT_CORE`
pointed at a nonexistent path with `CLAUDE_PROJECT_DIR` also isolated so
the `../../core` relative fallback cannot accidentally resolve, asserting
exit code 2 (deny), not 0 (allow) and not the current unguarded
125/traceback shape. Mirrors core's own harness's assertion:

```
got=$([ $rc = 0 ] && echo allow || { [ $rc = 2 ] && echo deny || echo "exit-$rc"; })
report deny "$got" "<gate>.sh: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere denies, not silent-allow"
```

Phase 2 must confirm the full 7-file suite (existing cases + the 7 new
missing-core cases, one per gate) is green in the same commit that ships
the guard fix (issue-16 requirement 3: "missing-core 케이스 포함 전 스위트
배송 상태 green").

## 3. Record a passing compliance-check run

Per survey.md requirement 3's second half, phase 2 must re-run core's
`compliance-check.sh` against all 7 `hooks/` directories after the guard
fix lands, confirm 7/7 pass (survey.md's baseline run, done against the
*pre-fix* state, is 7/7 fail — the delta is the acceptance signal), and
record the pass in `docs/issue-16/reports/finance-unit-economics.md`
(phase-2 record file, not written in this phase-1 pass) alongside the
commit that shipped the fix.

## 4. Requirements 2 and 4 — no phase-2 action

Survey.md found both already clean by direct verification (not by
trusting the issue's "잔여 없음" line): hooks.json matcher/code coverage
parity (no gate branches on `Bash`/`gate_bash_write_targets`, no test
exercises an unreachable branch) and README/manifest ghost-file/old-name
cleanliness (all 7 `marketplace.json` sources resolve, README Layout
section lists only existing files, no pre-issue-160 role name anywhere).
Phase 2 takes no action on these; re-stating them here only so the
phase-2 record can cite this proposal as having checked, not skipped,
both.

## Phase-2 reflection plan

After phase 2 ships §1-§3, the reflection check is mechanical and
re-runs the same two real-execution probes this survey used, not a
fresh design pass: (a) re-run core's `compliance-check.sh` against all 7
`hooks/` directories and confirm 7/7 pass where this survey recorded 7/7
fail; (b) re-run all 7 `tests/*.test.sh` files and confirm the 7 new
missing-core cases assert exit 2, plus every pre-existing case still
green. Both are pass/fail, not judgment calls, so phase-2's own record
file can state the before/after compliance-check delta directly instead
of re-deriving it.

## Constraints check

- No hook, test, or manifest file created/edited in this phase — only
  `docs/issue-16/reports/finance-unit-economics/survey.md` and this
  proposal.
- Nothing here approves phase 2 or asserts it may start; per contract
  v3 s19, phase 2 opens only on a qualifying PR/issue Approve.
- No `docs/issue-16/reports/finance-unit-economics.md` written (phase-2
  record file, forbidden pre-approval).

## Decision requested

Approve phase 2 to, in this order:

1. Apply §1's guarded source line verbatim to all 7 gate scripts.
2. Add §2's missing-core test case to each of the 7 `tests/*.test.sh`
   files and confirm the full suite (existing + 7 new cases) is green in
   the same commit.
3. Re-run core's `compliance-check.sh` against all 7 `hooks/`
   directories, confirm 7/7 pass, and record the before/after result in
   `docs/issue-16/reports/finance-unit-economics.md` citing this
   proposal, the survey's baseline 7/7-fail run, and the commit that
   shipped the fix.
