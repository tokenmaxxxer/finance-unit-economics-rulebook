# issue-13 survey — finance-unit-economics gate audit gap (current grade C+)

## Scope

Issue #13 is a real-code audit (2026-08-01, grade C+) of the plugin set
landed by issue-10 (PR #12): base plugin `finance-unit-economics/` plus
six satellite plugins (`finance-evidence-chain`, `finance-proposal-shape`,
`finance-ltv-cac-band`, `finance-cac-payback`, `finance-sensitivity-scenario`,
`finance-ltv-churn-assumption`), each a `PreToolUse` gate on
`Write|Edit|MultiEdit|NotebookEdit`. This survey verifies each audit claim
against the actual files in this repo and checks the core precondition
("core issue #72 gate-house standard must land first, and be adopted by
reference, not reimplemented").

## Audit claim 1 — malformed JSON = silent allow (contradicts the trap)

Confirmed in all 7 gate scripts. Pattern (e.g.
`finance-cac-payback/hooks/cac-payback-gate.sh:25-28`):

```python
try:
    event = json.loads(os.environ.get("CP_PAYLOAD", ""))
except Exception:
    sys.exit(0)
```

`sys.exit(0)` is a clean success exit. The bash wrapper's `__fc` trap
(`hooks/*.sh:2`) only intercepts *unexpected* nonzero/non-2 exit codes —
`rc=0` is exactly what a legitimate allow looks like, so the trap cannot
tell "gate ran and found nothing wrong" apart from "gate could not even
parse its input." A hand-crafted or truncated payload silently passes
every gate. Same shape in `produces-fields-gate.sh:49-52`,
`evidence-chain-gate.sh:29-32`, `proposal-shape-gate.sh` (line ~24-27),
`ltv-cac-band-gate.sh:27-30`, `sensitivity-scenario-gate.sh` (line
~25-28), `ltv-churn-assumption-gate.sh` (line ~25-28) — grepped, all 7
match `except Exception:` immediately followed by `sys.exit(0)`.

## Audit claim 2 — MultiEdit's `edits[]` unread (bypass)

Confirmed. Every gate extracts content with:

```python
content = (ti.get("content") or ti.get("new_string") or "")
```

`Write`'s `tool_input` has `content`; `Edit`'s has `new_string`. But
`MultiEdit`'s `tool_input` shape is `{"file_path": ..., "edits": [{"old_string":
..., "new_string": ...}, ...]}` — there is no top-level `content` or
`new_string` key. `content` resolves to `""`. Every gate's check is
gated behind `if has(...)` / `if "<term>" in low` conditions that are
trivially false on an empty string, so **every gate no-ops on
MultiEdit**, regardless of what the edit actually writes. A required
field, a band judgment, a churn assumption — all can be introduced or
stripped via `MultiEdit` with zero gate involvement.

## Audit claim 3 — CLAUDE_ROLE unset = gate released without authorization

Two gates (`finance-evidence-chain`, `finance-proposal-shape`) read
`CLAUDE_ROLE`, but only to compute their own path-scope match — an unset
`CLAUDE_ROLE` defaults to `"finance-unit-economics"` (line: `role="${CLAUDE_ROLE:-finance-unit-economics}"`),
which does not release those two gates. The actual release is structural,
not a variable default: **README.md documents three hooks that do not
exist in the tree** —`hooks/record-fields-gate.sh`, `hooks/trailer-gate.sh`,
`hooks/handbook-trigger-gate.sh`. `finance-unit-economics/hooks/`
contains only `directive.sh` and `produces-fields-gate.sh`
(confirmed via `find`). Whatever those three were meant to enforce
(role-agnostic record-field minimum, commit-trailer discipline,
handbook-sync) is currently enforced by nothing — no `CLAUDE_ROLE` check
ever runs because no script exists to run one. This is the actual
"unauthorized release": the README's own claimed coverage is fiction,
and a reader (or a future editor) has no way to discover the gap short
of `find`-ing the tree directly. Confirmed against `README.md`'s Layout
section vs. `find ./finance-unit-economics -type f`.

## Audit claim 4 — path matching not absolute-normalized

Confirmed. Every gate matches with
`target.replace("\\", "/").endswith("/reports/finance-unit-economics.md")`
(record-path gates) or a regex anchored on a *relative* string
(`re.search(r'(^|/)docs/issue-[0-9]+/proposals/[^/]+\.md$', rel)`,
proposal-path gates). Neither resolves `..`, symlinks, or a path passed
with a different working-directory prefix. A `file_path` such as
`../../../elsewhere/docs/issue-9/reports/finance-unit-economics.md` or
one containing a `..` segment that still happens to end in the matched
suffix passes the `endswith`/`re.search` check without ever being
verified as actually resolving under the repo's `docs/` root.

## Audit claim 5 — deny reason not reliably reaching stderr

Every `deny()` helper across all 7 gates does write to `sys.stderr`
correctly today (`sys.stderr.write(...)`), and the bash wrapper does not
redirect stderr. This part of the audit line is **not independently
reproduced** by static reading alone — flagged for the phase-2
implementer to add a subprocess test asserting `stderr` capture (see
proposal §6), since a static read cannot rule out an environment where
Claude Code's own hook runner swallows stderr on rc=2. Not claiming this
is fine; claiming it needs a real subprocess test, which does not exist
today (`tests/` covers only content-logic allow/deny, not stderr
capture — checked `evidence-chain-gate.test.sh`, `cac-payback-gate.test.sh`).

## Audit claim 6 — semantic checks are substring, not section/adjacency

Confirmed, with the sole exception of `finance-ltv-cac-band`, which
already does proximity (bounded character window) matching. Every other
check is a flat `in`/`.find()` substring test over the *entire* document:

- `produces-fields-gate.sh`: `find_field` is `lower.find(needle)`
  anywhere in the file; the "numeric nearby" check uses a 400-char
  window from the field label's index — a window, not a section
  boundary, so a number belonging to an unrelated paragraph within 400
  chars still satisfies it.
- `evidence-chain-gate.sh`: `has(...)` is file-wide `in low` — a
  `mandate` word and a `necessary` word anywhere in the whole proposal,
  even in unrelated paragraphs on unrelated topics, satisfy the chain
  check.
- `proposal-shape-gate.sh`: `"decision requested" in low` file-wide —
  the phrase could appear in a quoted counter-example or a "not yet
  decided" sentence and still pass.
- `cac-payback-gate.sh`: `"cac" in low and "arpu" in low` file-wide — no
  adjacency to `payback` at all.
- `sensitivity-scenario-gate.sh`: scenario-label regex applied file-wide,
  not scoped to a sensitivity section.
- `ltv-churn-assumption-gate.sh`: bounded regex window (`[^.\n]{0,60}`)
  around `churn`/`ndr`, which is adjacency-aware within one sentence but
  not section-aware (a churn mention in an unrelated paragraph, if it
  happens to sit within 60 chars of a digit, still passes).

`finance-ltv-cac-band` is the existing best-in-repo precedent for
adjacency checking (`PROXIMITY_WINDOW = 120` chars around each ratio
token) — the proposal below generalizes this pattern rather than
inventing a new one.

## Core precondition status

Issue #13 makes core issue #72 ("gate-house standard: shared library,
standard harness, compliance detector") landing a precondition, and asks
the phase-2 implementation to reference that library rather than
reimplement it. **This repo has no `core/` directory and no
`docs/handbooks/gate-house-standard.md`.** `finance-unit-economics/hooks/directive.sh`
already resolves a sibling `core` plugin root at runtime
(`CLAUDE_PLUGIN_ROOT_CORE` env var, falling back to `../../core`
relative to the plugin), confirming `core` is installed as a *separate*
plugin at runtime, not vendored into this repo — so `gate-lib.sh` and
the gate-house standard doc are not readable from this workspace. The
proposal below is written as a design-time reference-adoption contract
(call `gate-lib.sh`'s named functions, do not reimplement their logic)
without having read the library's current interface, and flags that the
phase-2 implementer's first task must be reading the actual landed
`core/hooks/lib/gate-lib.sh` before writing code, since this survey
could not.

## Scout-brief precedent found

`docs/issue-1/reports/finance-unit-economics/scout-brief.md` and
`docs/issue-10/reports/finance-unit-economics/scout-brief.md` both exist
and follow the same shape: Mode/budget statement, "Must-bes the
exemplars establish," "Performance axes," "Adopt/skip," "Gap line,"
"Segment fit," "Sources." This survey's companion `scout-brief.md`
follows the same shape.
