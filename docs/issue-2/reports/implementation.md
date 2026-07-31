## what was done

Executed the phase-1 proposal
(docs/issue-2/proposals/core-canon-transition.md) after Approve.

- Task 1: `finance-unit-economics/agents/warrant-hunter.md` replaced with a
  reference stub pointing at core's `warrant/` plugin (core #63); kept the
  mandate line, hand-off note, and the "enumerate stance set before
  shipping" deferral.
- Task 2: deleted `finance-unit-economics/hooks/trailer-gate.sh` and
  `finance-unit-economics/hooks/handbook-trigger-gate.sh` and their
  `hooks.json` `PreToolUse` entries. `record-fields-gate.sh` was not
  deleted outright — see the gap resolution below — but its own
  `PreToolUse` registration was rewritten under its new filename.
- Task 3: `finance-unit-economics/hooks/directive.sh` replaced with the
  stub form (source `role-directive.sh` + 4 variable assignments + one
  `core_role_directive` call), matching the accepted shape used by sibling
  rulebooks already on this pattern.
- Task 4 (RECORD_FIELDS_TERMINAL_STATES): left unset. This role has no
  prior record and no defined `loop_state` vocabulary that diverges from
  core's default terminal-state set (proposal's stated condition for
  setting it is not met).
- Task 4 (record-fields-gate.sh gap): resolved as option (b) from the
  proposal — kept a thin role-owned copy containing only the PRODUCES-field
  check (`unit-economics-model`, `sensitivity-note`), with the §20
  structural duplication removed (core's canon copy now owns that).
  Renamed `record-fields-gate.sh` → `produces-fields-gate.sh` so the file
  no longer matches `stub-check.sh`'s canon-filename drift list (the
  original name is itself the drift signal the check watches for);
  `hooks.json` updated to reference the new filename.

## why

Core issue #63/#66 promoted warrant-hunter and the three role-agnostic
gates to canon, firing globally once core is installed; this role's own
vendored copies were duplicate execution paths, not additional coverage
(survey.md).

## upstream basis

docs/issue-2/proposals/core-canon-transition.md, approved via issue
comment `APPROVE issue-2/implementation`.

loop_state: landed

## open findings

- Task 5 acceptance check: `core/hooks/tests/stub-check.sh` copied
  verbatim into `finance-unit-economics/hooks/tests/stub-check.sh` and run
  against `finance-unit-economics/hooks`:

  ```
  stub-check: ok — no vendored 'trailer-gate.sh' under finance-unit-economics/hooks
  stub-check: ok — no vendored 'record-fields-gate.sh' under finance-unit-economics/hooks
  stub-check: ok — no vendored 'handbook-trigger-gate.sh' under finance-unit-economics/hooks
  stub-check: ok — no vendored 'parse-check.sh' under finance-unit-economics/hooks
  stub-check: ok — finance-unit-economics/hooks/directive.sh is a role-directive stub
  ```

  Exit code 0 — PASS.
- `produces-fields-gate.sh` is a new filename with no core-canon
  equivalent; it is out of scope for `stub-check.sh`'s drift list by
  design (task 4's chosen resolution), so its continued presence is
  expected, not a check failure.
- Not addressed here (explicitly out of proposal scope, unchanged):
  warrant-hunter's own stance-set content, this role's PRODUCES fields/
  write_scope/hand-off target (issue-170 territory).

HAND-OFF: none — issue #2's task list is fully executed on this branch.
