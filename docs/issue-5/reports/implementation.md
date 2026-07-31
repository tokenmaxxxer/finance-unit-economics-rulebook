# issue-5 phase-2 record — stub-check.sh copy recovery

loop_state: landed

## What was done

Deleted the vendored `finance-unit-economics/hooks/tests/stub-check.sh`
copy (the only one the phase-1 survey found) and removed the now-empty
`finance-unit-economics/hooks/tests/` directory. Confirmed
`finance-unit-economics/hooks/hooks.json` had no `stub-check.sh`
registration to remove (it only registers `directive.sh` and
`produces-fields-gate.sh`). Ran core's canonical `stub-check.sh` by
reference (never copied into this repo) against
`finance-unit-economics/hooks` both before and after the deletion to
confirm the hooks tree stays clean.

## Why

core issue #69 confirmed canon: `stub-check.sh` is run only from core's own
installed copy (`core/hooks/tests/stub-check.sh`); a rulebook keeping its
own copy is drift, not a legitimate stub, per
`docs/handbooks/canon-scripts.md`. This repo's `finance-unit-economics/hooks/tests/stub-check.sh`
was exactly such a copy, identified in issue-5's phase-1 survey and
approved for removal in the phase-1 proposal.

## Upstream basis

- docs/issue-5/proposals/implementation.md (this issue's approved phase-1
  proposal, PR #6, merged)
- docs/issue-5/reports/implementation/survey.md (phase-1 current-state
  survey that located the vendored copy)
- core #69 canon decision + docs/handbooks/canon-scripts.md

## Evidence — before deletion

```
stub-check: ok — no vendored 'trailer-gate.sh' under finance-unit-economics/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under finance-unit-economics/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under finance-unit-economics/hooks
stub-check: ok — no vendored 'parse-check.sh' under finance-unit-economics/hooks
stub-check: ok — finance-unit-economics/hooks/directive.sh is a role-directive stub
```

(stub-check.sh checks the four role-agnostic gate files plus
directive.sh's stub shape; it does not check its own vendoring, so this
run reflects pre-existing cleanliness, not the drift issue #5 targets —
the drift itself was fixed by direct deletion in the next step.)

## Evidence — after deletion

```
stub-check: ok — no vendored 'trailer-gate.sh' under finance-unit-economics/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under finance-unit-economics/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under finance-unit-economics/hooks
stub-check: ok — no vendored 'parse-check.sh' under finance-unit-economics/hooks
stub-check: ok — finance-unit-economics/hooks/directive.sh is a role-directive stub
```

## Open findings

None. All phase-1 proposal items are complete: the vendored
`stub-check.sh` copy is deleted, no `hooks.json` entry existed to remove,
and core-referenced stub-check passes cleanly against
`finance-unit-economics/hooks` both before and after the change.
