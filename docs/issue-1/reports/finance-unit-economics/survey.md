# issue-1 phase-1 current-state survey — finance-unit-economics rulebook maturation

## Scope

issue #1 asks this rulebook to stop deciding its phase-1 proposal norms and
phase-2 deliverable norms "by feel," and instead ground both in an actual
survey of unit-economics analysis methodology. This document surveys the
role's own five plugin files as they exist today, to identify concretely
what is already load-bearing, what is a placeholder, and what is simply
absent. `docs/issue-1/reports/finance-unit-economics/scout-brief.md` covers
the external field survey; this file covers only the internal starting
point.

## Files surveyed

| File | State |
|---|---|
| `finance-unit-economics/.claude-plugin/plugin.json` | Real, minimal. Declares role = "단위경제상 성립하는가", use_when = "가격/비용 구조가 걸린 결정일 때", hand-off "실제 가격 숫자 결정은 → pricing." No dependency on core declared (consistent with issue-2's finding that core hooks fire via platform-level install, not a manifest edge). |
| `finance-unit-economics/agents/warrant-hunter.md` | Thin stub over core's `warrant/` plugin (core issue #63), per issue-2's already-landed core-canon-reference transition — not a vendored copy. Carries the mandate string and hand-off string only. **Its stance set is an explicit empty skeleton**: "enumerate this role's own stance set before shipping (deferred, not part of issue #2's task list)." No stances exist yet for this role's warrant-hunter to check claims against. |
| `finance-unit-economics/hooks/directive.sh` | Real, ~7 lines. Sources `core/hooks/lib/role-directive.sh` and calls `core_role_directive` with four strings: `you_decide`, `use_when`, `produces`, `hand_off`. The `produces` string is currently `"unit economics model (CAC/LTV/margin), sensitivity note"` — it names CAC/LTV/margin and a sensitivity note, but nothing in the plugin defines what "unit economics model" or "sensitivity note" must actually contain (no formula, no required assumption disclosure, no benchmark ratio). |
| `finance-unit-economics/hooks/hooks.json` | Real. Registers `directive.sh` on `SessionStart` and `produces-fields-gate.sh` on `PreToolUse` for `Write\|Edit\|MultiEdit\|NotebookEdit`. Matches the shape of other already-audited roles (issue-2 survey) — only two hooks, no role-specific PreToolUse content-shape checks beyond the one gate. |
| `finance-unit-economics/hooks/produces-fields-gate.sh` | Real but explicitly self-labeled placeholder. Fires only when a write target's path ends in `/reports/finance-unit-economics.md`. `REQUIRED_FIELDS = ["unit-economics-model", "sensitivity-note"]`, checked as case-insensitive substring (hyphen-or-space interchangeable) against the write's `content`/`new_string`. The file's own header comment says: **"Skeleton: field-presence checks are a placeholder (substring/heading match) — harden before treating as load-bearing."** It only checks that the *labels* "unit-economics-model" and "sensitivity-note" appear somewhere in the text — it does not check that a sensitivity section contains actual numbers, that a CAC/LTV figure is present, or that any formula or assumption is stated. A write could satisfy this gate by including the two heading strings with no real analysis under them. |

## What is missing

1. **No phase-1 proposal methodology is specified anywhere.** Nothing in
   the plugin or in contract v3 (as surveyed) says what a
   finance-unit-economics phase-1 proposal must contain, what counts as
   adequate evidence for an adopted claim, or what heading structure it
   must follow. issue-2's and issue-5's proposals establish a *de facto*
   house style (Decision requested / Order of operations / Out of scope,
   or a plain current-state survey), but no document ties that style, or
   any methodology requirement, specifically to this role's domain.
2. **The produces fields are minimal and unjustified by any documented
   methodology.** "unit economics model (CAC/LTV/margin), sensitivity
   note" names three metrics (CAC, LTV, margin) and one section
   (sensitivity note) with no citation, no formula, and no explanation of
   why these four items — and not, say, payback period, LTV:CAC ratio, or
   cohort retention — are the right minimum set for a "단위경제상
   성립하는가" go/no-go check.
3. **`produces-fields-gate.sh`'s checks are heading-only.** There is no
   mechanism today that would catch a record that has a
   "sensitivity-note" heading followed by no numbers, or a
   "unit-economics-model" heading with a bare assertion and no CAC/LTV
   figures. Hardening this (per the file's own TODO) requires first
   deciding what "real content" means — which is exactly what issue #1's
   phase-1 proposal is supposed to establish.
4. **warrant-hunter's stance set is empty.** Nothing in the current
   plugin enumerates the claims a "단위경제상 성립하는가" warrant-hunter
   invocation should challenge (e.g., "is the CAC figure sourced from
   real spend, or assumed?", "is the LTV horizon justified?"). This gap
   is out of issue #1's explicit task list (issue #2 deferred it) but is
   noted here because the phase-2 proposal in this issue will need to
   avoid silently overlapping with it.

## Conclusion

The plugin machinery (directive.sh, hooks.json, produces-fields-gate.sh)
is structurally sound and already follows the role-agnostic
core-canon-reference pattern from issue-2. What is missing is entirely on
the *content* side: no documented methodology backs the current
`produces` string or the current `REQUIRED_FIELDS` list, and the gate
cannot distinguish a real analysis from a heading with the right label.
This is the gap the field survey (scout-brief.md) and the proposal
(rulebook-maturation.md) are written to close.
