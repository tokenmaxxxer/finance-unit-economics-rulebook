# issue-5 phase-1 proposal — stub-check.sh copy recovery

## Decision requested

Approve phase 2 to:

1. **Delete** `finance-unit-economics/hooks/tests/stub-check.sh` (the sole
   vendored copy found in the survey). If `finance-unit-economics/hooks/tests/`
   becomes empty as a result, remove the now-empty directory too.
2. **No `hooks.json` change is needed** — `finance-unit-economics/hooks/hooks.json`
   never registered `stub-check.sh` (it only registers `directive.sh` and
   `produces-fields-gate.sh`), so there is nothing to unregister.
3. **Run `stub-check.sh` by reference** against core's canonical install
   path (core's own `hooks/tests/stub-check.sh`, resolved via the installed
   core plugin — not a path inside this repo) over this repo's
   `finance-unit-economics/hooks/` tree, and record the full pass/fail
   output in `docs/issue-5/reports/implementation.md` as phase-2 evidence,
   the same way issue-2's Task 5 recorded it.

## Order of operations (phase 2)

1. Locate core's installed canonical `stub-check.sh` path in the current
   session (do not copy it into this repo).
2. Run it by reference against `finance-unit-economics/hooks`, capture
   output.
3. Delete `finance-unit-economics/hooks/tests/stub-check.sh` (and the
   `tests/` directory if left empty).
4. Re-run the same reference check to confirm the drift signal it exists to
   catch (a locally vendored copy of a core canon file) no longer fires for
   `stub-check.sh` itself.
5. Write `docs/issue-5/reports/implementation.md` recording both run
   outputs (before/after) and the deletion.

## Out of scope

- No changes to `docs/issue-2/*` (historical record, not this issue's to
  edit).
- No changes to `directive.sh` or `produces-fields-gate.sh` — issue #5 is
  scoped to `stub-check.sh` only, per core canon decision #69.
- No changes to the three role-agnostic gate files — already de-vendored
  under issue-2.
