# Proposal: switch to core canon for warrant-hunter + role-agnostic gates

Phase 1 proposal for issue #2. No execution in this phase; awaits Approve
per contract v3 s19.

## Task 1 — warrant-hunter.md: reference, not copy

Replace `finance-unit-economics/agents/warrant-hunter.md`'s body with a
short pointer to core's `warrant/` plugin (core #63), keeping only this
role's own decision boundary and stance set (currently a skeleton mandate,
already role-specific):

- Keep: the `단위경제상 성립하는가` mandate line, the hand-off note
  (`실제 가격 숫자 결정은 → pricing`), and — once written — this role's own
  stance enumeration (the file currently defers this: "enumerate this
  role's own stance set before shipping").
- Remove: the generic "rotating-stance background hunt agent" framing,
  scope/read-only boilerplate — that description now lives once in core's
  `warrant/` plugin.
- New file should say plainly it is a role-specific configuration of core's
  `warrant/` plugin, not a standalone agent definition, mirroring how
  `directive.sh` becomes a stub over `role-directive.sh` (task 3).

## Task 2 — delete the three vendored gate copies + their hooks.json entries

Delete:
- `finance-unit-economics/hooks/trailer-gate.sh`
- `finance-unit-economics/hooks/handbook-trigger-gate.sh`
- `finance-unit-economics/hooks/record-fields-gate.sh` — **but only after
  task 4's open question is resolved** (see below); deleting it today would
  silently drop this role's own PRODUCES-field enforcement, since core's
  canon copy checks contract §20's generic structural fields only, not any
  role's PRODUCES list (survey.md, "Gap found").

Remove the corresponding three entries from
`finance-unit-economics/hooks/hooks.json`'s `PreToolUse` block. Core's own
`hooks.json` already registers these three gates (plus `board-gate.sh`,
`approval-gate.sh`, `gh-guard.sh`) globally via `"matcher": ".*"`, and core
is already active in this session's install (survey.md, "Install
mechanism") — so removing the local registration does not stop the gates
from firing, it only stops the duplicate local copy from firing a second
time under a role-specific env-var name.

`hooks.json` after task 2 keeps only the `SessionStart` → `directive.sh`
entry; the `PreToolUse` block becomes empty and should be dropped entirely
(or left as `{"hooks": {"SessionStart": [...]}}` with no `PreToolUse` key).

## Task 3 — directive.sh → stub form

Replace `finance-unit-economics/hooks/directive.sh` with the stub shape
`core/hooks/lib/role-directive.sh` documents and
`core/hooks/tests/stub-check.sh` mechanically enforces (source line + 4
variable assignments + one `core_role_directive` call, nothing else):

```sh
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: 단위경제상 성립하는가" \
  "USE_WHEN: 가격/비용 구조가 걸린 결정일 때" \
  "PRODUCES (required record fields): unit economics model (CAC/LTV/margin), sensitivity note" \
  "HAND-OFF: 실제 가격 숫자 결정은 → pricing"
```

Preserved role-unique content: the four strings above, taken verbatim from
the current directive.sh's heredoc body — nothing else in the current file
is role-specific (kill-switch name pattern, `CLAUDE_ROLE` guard, opening
line, RECORD line are all the boilerplate core factored out per its own
`role-directive.sh` header comment).

One divergence to flag, not silently drop: the current directive.sh's kill
switch is `FINANCE_UNIT_ECONOMICS_CYCLE_OFF`; `core_role_directive` derives
the same name from `CLAUDE_ROLE` automatically (`tr` upper-cased + `_`), so
behavior is preserved without restating the variable name — confirmed by
reading `role-directive.sh`'s own body, not assumed.

## Task 4 — RECORD_FIELDS_TERMINAL_STATES: open question, not yet set

This role's rulebook is still skeleton-stage (issue-170) with no written
record and no defined `loop_state` vocabulary of its own. There is no
current evidence of a role-specific terminal-state set that differs from
core's default. Proposal: **do not set `RECORD_FIELDS_TERMINAL_STATES`
in task 2's phase-2 execution** unless this role's own loop_state
vocabulary is defined first and shown to diverge from core's default set.
If task 4 is judged blocking by the approver, the alternative is to define
this role's loop_state vocabulary as part of phase 2's execution before
touching the gate files — flagging that as a scope question for the
Approve decision rather than deciding it unilaterally here.

Separately, this is where task 2's record-fields-gate.sh deletion must be
resolved: core's canon copy has no per-role PRODUCES-field configuration
point (only the terminal-states axis is configurable). Phase 2 must choose
one of:
(a) delete our copy and accept the loss of PRODUCES-field enforcement,
    relying on §20's generic structural check alone;
(b) keep a thin role-owned copy of only the PRODUCES-field check, no longer
    duplicating the §20 structural logic core now owns; or
(c) raise a follow-up core issue proposing a PRODUCES-field configuration
    point on core's canon gate, analogous to `RECORD_FIELDS_TERMINAL_STATES`.
This proposal does not pick one — it is exactly the kind of design decision
phase 2 execution should carry into the PR, informed by the approver's
judgment on how much of core's gate promotion this role needs to lean on
immediately versus in a follow-up.

## Task 5 — stub-check.sh acceptance

Phase 2 execution copies `core/hooks/tests/stub-check.sh` into this repo
(the same way `parse-check.sh` is already distributed per its own header,
per stub-check.sh's own comment) and runs it against
`finance-unit-economics/hooks/`, recording the pass/fail output in
`docs/issue-2/reports/implementation.md` (phase-2 output, written only
after Approve).

## What is out of scope for this proposal

- `finance-unit-economics/agents/warrant-hunter.md`'s actual stance-set
  content (the file itself defers this to "before shipping" — not part of
  issue #2's task list).
- Any change to this role's own PRODUCES fields, `write_scope`, or
  hand-off target — those are issue-170 territory, untouched here.
- Sequencing note from the issue: this transition must land before this
  repo's "룰북 성숙화" phase 2 — noted for the approver, not actioned here.
