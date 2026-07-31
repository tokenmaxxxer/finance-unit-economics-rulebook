# issue-5 phase-1 current-state survey — stub-check.sh copy recovery

## Scope

Issue #5 asks this rulebook (`finance-unit-economics`) to comply with core
canon decision #69: `stub-check.sh` must only be referenced/executed from
core's canonical install path (`core/hooks/tests/stub-check.sh`), never
vendored as a per-role copy. Delete this repo's copy, and if any
`hooks.json` registers it, remove that registration too. This is a
current-state survey only — no code change lands in this phase.

## Copies found

`find . -name 'stub-check.sh'` (repo-wide) returns exactly one hit:

- `finance-unit-economics/hooks/tests/stub-check.sh` — a full verbatim copy
  of core's `core/hooks/tests/stub-check.sh`. Its own header comment says:
  "Every rulebook copies this file verbatim and runs it over its own hooks/
  tree" — i.e. the copy was intentional at the time it was made.

No canonical/core copy of `stub-check.sh` exists inside this repo (there is
no `core/` directory here at all — core is an external, separately
installed plugin, not vendored or submoduled into this repo).

### Provenance

Per `docs/issue-2/reports/implementation.md` (lines 48-57), this copy was
placed here deliberately during issue-2 phase-2 execution, as "Task 5
acceptance check": `core/hooks/tests/stub-check.sh` was copied verbatim into
`finance-unit-economics/hooks/tests/stub-check.sh` and run once, to
produce and record the pass/fail evidence lines quoted there (e.g.
`stub-check: ok — no vendored 'trailer-gate.sh' under finance-unit-economics/hooks`).
At that time, per-rulebook vendoring of `stub-check.sh` itself was treated
as an acceptable, expected distribution mechanism (the script's own header
comment, quoted above, said as much). Core canon decision #69 supersedes
that: `stub-check.sh` itself is now also canon-only, reference-execution-only,
not to be copied into role trees. This copy is now itself the kind of drift
`stub-check.sh` was designed to detect (a locally-persisted copy of a file
core owns and fires/ships centrally), so it must be removed the same way as
the three gate scripts issue-2 already de-vendored.

## hooks.json registration check

`find . -name 'hooks.json'` returns exactly one hit:
`finance-unit-economics/hooks/hooks.json`. Full contents:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|NotebookEdit",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/produces-fields-gate.sh" }
        ]
      }
    ]
  }
}
```

`hooks.json` does **not** reference `stub-check.sh` anywhere — it only
registers `directive.sh` (SessionStart) and `produces-fields-gate.sh`
(PreToolUse). This matches `stub-check.sh`'s own role: it is not fired as a
live hook, it is a manually-run acceptance check (per the issue-2 Task 5
usage documented above), so there was never a `hooks.json` entry to begin
with. No `hooks.json` edit is needed for this issue — only the vendored
file itself needs removal.

## grep sweep for other stub-check references

`grep -rn "stub-check"` across the repo (excluding `.git/`) turns up:

- `finance-unit-economics/hooks/tests/stub-check.sh` — the copy itself (to
  be deleted).
- `docs/issue-2/proposals/core-canon-transition.md` and
  `docs/issue-2/reports/implementation.md` / `.../implementation/survey.md`
  — historical issue-2 documentation describing the Task-5 acceptance-check
  copy-and-run step. These are historical record and are out of scope for
  this issue to edit; phase 2 should add a new record (this issue's own
  `docs/issue-5/reports/implementation.md`), not rewrite issue-2's history.

## Summary of findings

1. One vendored copy: `finance-unit-economics/hooks/tests/stub-check.sh` —
   should be deleted.
2. No `hooks.json` registration of `stub-check.sh` exists — nothing to
   remove there.
3. Phase 2 needs to re-run `stub-check.sh` by reference against core's
   canonical install path (not a local copy) and record the pass/fail
   output in `docs/issue-5/reports/implementation.md`, per the same pattern
   issue-2 used for the three role-agnostic gates.
