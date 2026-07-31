# issue-10 scout brief — finance-unit-economics methodology enforcement

Mode: batched-sequential, single session (not parallel subagents) — the
comparison set is exactly two known-good internal exemplars named by the
issue itself (`implementation-rulebook`, and `pricing-rulebook`'s
`methodology-gate.sh`), both local checkouts under
`/home/jwjung/tokenmaxxxer/rulebooks/`. No web search was run: the field
being scouted is this monorepo's own canon-governed rulebook family, not
an external domain, so the "best comparable systems" are these sibling
plugins, read directly rather than fanned across search angles. 2 stages
used (read implementation-rulebook's hook machine + tests; read
pricing-rulebook's methodology-gate.sh + handbook), well under the
5-stage/3-minute budget; stopped once both named exemplars were read in
full — a third round would not have changed any design decision
(saturation).

## Must-bes the exemplars establish

- **Fail-closed on internal error** (`implementation-rulebook`
  `coding/hooks/coding-progress-gate.sh`,
  `pricing-rulebook` `pricing/hooks/methodology-gate.sh`): every gate
  traps unexpected exit codes and denies rather than silently allowing.
  Source: `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh:1-3,221-223`.
- **Kill switch per gate**, env-var named after the gate
  (`PRICING_METHODOLOGY_GATE_OFF`, this role's own
  `FINANCE_UNIT_ECONOMICS_CYCLE_OFF` pattern already in
  `produces-fields-gate.sh`). Source:
  `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh:19-28`.
- **Presence-only field checks are not enough**: pricing's
  `methodology-gate.sh` checks for *labeled* numbers ("labeled-numbers"),
  not bare digits — the same gap this role's own issue-1 proposal
  flagged for its own numeric-content check. Source: same file, lines
  194-203.
- **A worked-reasoning handbook accompanies the mechanical gate**
  (`pricing-rulebook` `docs/handbooks/pricing/methodology.md`): the gate
  enforces the floor, the handbook carries the "why," split into a
  phase-1 checklist and a phase-2 checklist. Source:
  `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/docs/handbooks/pricing/methodology.md:1-58`.
- **Real subprocess gate tests, allow/deny pairs, foreign-path no-op
  case** (`implementation-rulebook` `tests/run-gate-tests.sh`): every
  gate gets at least one allow case, one deny case, and one case proving
  the gate ignores writes outside its own target path. Source:
  `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh:1-70`.
- **State tracking is reserved for genuine cross-write ordering**
  (`implementation-rulebook`'s `hunt-state.sh`/`hunt-guard.sh` enforce a
  survey-before-hunt sequence across *separate* write events); neither
  `pricing-rulebook` nor this role's own methodology has that shape —
  pricing's gate re-checks every methodology element on every single
  write instead. Source:
  `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/hunt-state.sh:1-47`
  vs. `pricing-rulebook/pricing/hooks/methodology-gate.sh` (stateless).

## Performance axes the exemplars compete on

1. **Path-scoping precision** — pricing's gate matches proposal files by
   a filename-substring regex (`.*pricing.*\.md`), which is fragile
   (breaks if a proposal isn't named with the role word). This role can
   do better by scoping on the fixed record path
   (`produces-fields-gate.sh`'s existing pattern) for phase 2, and on
   `CLAUDE_ROLE` env value for phase-1 proposals instead of filename
   guessing.
2. **Depth of the "quality," not "presence," check** — how much of the
   methodology's actual judgment (band interpretation, scenario count)
   a mechanical regex can catch before it must give up and require a
   human approver's read.

## Adopt / skip

- **Adopt**: fail-closed trap, per-gate kill switch, worked-reasoning
  handbook alongside the gate, subprocess allow/deny/foreign-path test
  triad, gating both phase-1 proposal and phase-2 record surfaces (not
  phase-2 only, closing this role's current gap).
- **Adopt, improved**: scope phase-1 proposal matching by `CLAUDE_ROLE`
  rather than pricing's filename-substring regex.
- **Skip**: cross-write state tracking (`hunt-state.sh`-style). This
  role's methodology has no genuine separate-write ordering constraint
  to enforce — see survey.md's sequencing section and the proposal's
  justification below. Building a state machine for a constraint that
  is actually intra-document would be enforcement theater, not a real
  gate.

## Gap line

Current state already meets: fail-closed shape is present in
`produces-fields-gate.sh`'s own `__fc` trap; the per-role kill-switch
convention is present. Missing relative to the field: phase-1 proposal
methodology gating (absent entirely), quality checks beyond
label+bare-number (band interpretation, scenario count, source
labeling), a worked-reasoning handbook, and any gate test.

## Segment fit

This role is a thin advisory gate (five fields, one hand-off line), not
a multi-step build role like `coding`. The right bar is `pricing-rulebook`
(same tier: single-verdict advisory role with a phase-1/phase-2 split),
not `implementation-rulebook`'s full hunt-state machine — matching that
role's state-tracking weight here would be over-building for a
methodology with no real cross-write sequence.

## Sources

- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/docs/handbooks/pricing/methodology.md`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/hunt-state.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`
