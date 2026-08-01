# issue-13 phase-1 proposal — finance-unit-economics gate A+ upgrade

Grounded in `docs/issue-13/reports/finance-unit-economics/survey.md`
(each audit claim independently reproduced against the actual landed
code from PR #12) and `docs/issue-13/reports/finance-unit-economics/scout-brief.md`
(structural/adjacency matching precedent, internal + one external
search: [SemanticDiff vs. Difftastic](https://semanticdiff.com/blog/semanticdiff-vs-difftastic/)).
Working from named-framework assumption, not fabricated citation, for
the cac/ltv/payback/sensitivity field-quality bar itself — that bar was
already adopted in issue-1/issue-10 and is not re-derived here; this
proposal only tightens *how* each gate mechanically checks for it. Every
metric named below is necessary because it is the mandate (단위경제상
성립하는가) this role's own gates already enforce — the evidence-to-mandate
chain is: a gate that can be silently bypassed (malformed JSON,
MultiEdit, un-normalized paths) or satisfied by a substring anywhere in
the file cannot actually verify unit economics soundness, so it is not
enforcing the mandate at all, only performing the appearance of
enforcing it. **Phase 1 ONLY** — no hook, test, or `marketplace.json`
file is created or edited in this pass; this document specifies what
phase 2 must build.

## 0. Precondition status (must be re-checked before phase 2 starts)

Per issue #13's stated precondition, core issue #72's gate-house
standard must land, and this role's gates must call into it rather than
reimplement it. **This repo currently has no `core/` tree and no
`docs/handbooks/gate-house-standard.md`** — `core` is installed as a
separate sibling plugin at runtime (confirmed via
`finance-unit-economics/hooks/directive.sh`'s `CLAUDE_PLUGIN_ROOT_CORE`
resolution), so this proposal cannot cite `gate-lib.sh`'s actual
function names or signatures; it specifies the *contract* (§1) rather
than the call sites. **Phase 2's first action must be reading the
landed `core/hooks/lib/gate-lib.sh` and `docs/handbooks/gate-house-standard.md`
and reconciling every function name below against what actually
shipped** before writing any gate code. If core issue #72 has not
landed by the time phase 2 opens, phase 2 is blocked, not free to
reimplement the missing pieces itself.

## 1. Forbid reimplementation — reference-adopt core's gate-lib

Every one of the 7 gates in this plugin set currently reimplements, from
scratch, in its own Python heredoc: JSON-payload parsing, target-path
extraction, fail-closed error handling, and content extraction from
`tool_input`. This is the root cause of audit claims 1-4 (survey §1-4):
the same four bugs (silent-allow-on-malformed-JSON, MultiEdit blindness,
un-normalized path matching, and the general shape of "did the author
actually handle every tool_input variant") had to be independently
gotten wrong 7 times because there was no shared library to get right
once.

**Phase 2 requirement**: every gate's bash wrapper and Python body must
call `core`'s shared gate library instead of reimplementing:

- **Payload parse + fail-closed on malformed JSON**: `gate-lib.sh` (or
  its Python counterpart, whichever core issue #72 ships) must own
  "malformed JSON => deny (exit 2), not exit 0." No gate script in this
  plugin set may catch a JSON parse exception and locally decide to
  `sys.exit(0)`. If core's library exposes this as a Python helper, call
  it; if it is a bash-level pre-check before the Python heredoc even
  runs, gate the heredoc invocation on it.
- **Tool-input content extraction, ALL of Write/Edit/MultiEdit/NotebookEdit**:
  core's library must own the "given a `PreToolUse` event for any of
  these four tool names, return the full set of resulting text spans"
  logic, including iterating `tool_input.edits[]` for `MultiEdit`. No
  gate in this plugin set may do its own `ti.get("content") or
  ti.get("new_string")` shortcut.
- **Absolute-path normalization + repo-root-relative scoping**: core's
  library must own resolving `file_path`/`notebook_path` to an absolute,
  `..`-resolved path before any suffix/regex match is attempted. No gate
  in this plugin set may match on a raw, un-normalized string.
- **Fail-closed trap-at-top**: keep this role's existing `trap __fc EXIT`
  pattern (survey found no bug in the trap itself, only in what it fails
  to catch), but the trap must wrap a call into core's kill-switch
  recognizer too (§1 killswitch note below), not just the local
  `${X_GATE_OFF:-}` case statement, if core's standard defines a
  shared killswitch-value vocabulary.
- **Kill-switch unrecognized value = active, not disabled**: audit line
  1's fail-closed principle extends to the kill switch itself — today's
  `case "${FOO_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac`
  already treats any non-empty, non-off-like value as "kill switch on,"
  which is correct (unrecognized value => gate *disabled* is the
  audit's actual complaint pattern, and today's `*) exit 0` branch is
  reached by *any* truthy-looking value, which is the intended
  behavior). Phase 2 must keep this shape but adopt core's canonical
  off-value vocabulary if `gate-lib.sh` defines one, instead of each
  gate hand-rolling its own `""|0|false|no|off` list, so a future
  7th gate cannot drift from the other 6's accepted spelling.
- **Deny-reason delivery**: keep writing to `sys.stderr` (survey found
  no static bug here), but call core's `deny`/`emit_denial` helper if
  one exists, so the message format is uniform across all 43 rulebooks'
  gates, not just internally consistent within this one plugin set.

**What stays role-owned** (not moved to core): the actual methodology
content of each check — which fields are required, what a "band
judgment" or "churn assumption" looks like, the mandate string. Core
owns *how a gate safely reads its input and fails closed*; this role
owns *what the gate is checking for*. This mirrors this proposal's own
issue-10 precedent (`docs/issue-10/proposals/methodology-enforcement.md`
§8: "Canon scripts referenced, never copied").

## 2. Substring → section/adjacency/structural upgrade, gate by gate

Per scout-brief.md, `finance-ltv-cac-band`'s existing
`PROXIMITY_WINDOW`-based check is the pattern to generalize, not a new
invention. Below, "current" cites the exact substring behavior from
survey.md §6; "target" specifies the structural replacement.

| Gate | Current check (substring) | Target check (structural) |
|---|---|---|
| `produces-fields-gate.sh` | `lower.find(needle)` anywhere in file; numeric check is a flat 400-char window from the label | **Section-scoped**: require each `REQUIRED_FIELDS` entry to appear as its own markdown heading (`^#+\s*<field>`, case-insensitive, adjacency-normalized for `-`/space); the numeric-content check then searches only within that heading's own section body (from the heading to the next heading of equal-or-higher level), not a flat character window that can spill into an adjacent field's section |
| `evidence-chain-gate.sh` | `has(...)` file-wide for mandate word / causal word | **Same-paragraph adjacency**: mandate word and causal word must occur within the same paragraph (blank-line-delimited block), not merely anywhere in the document — closes the case where "mandate" appears in one section and "necessary" in a wholly unrelated one |
| `proposal-shape-gate.sh` | `"decision requested" in low` file-wide | **Heading-anchored**: require `"decision requested"` to appear as a markdown heading (`^#+\s*decision requested`), not as a phrase floating in body text (e.g. inside a quoted counter-example) |
| `cac-payback-gate.sh` | `"cac" in low and "arpu" in low` file-wide, no tie to `"payback"` | **Windowed adjacency around `"payback"`**: `cac` and `arpu` must each occur within a bounded window (proposed: 150 chars, matching `ltv-cac-band`'s existing 120-char precedent scaled up slightly for a two-term check) of a `"payback"` occurrence, not merely anywhere in the file |
| `sensitivity-scenario-gate.sh` | scenario-label regex applied file-wide | **Section-scoped**: scenario labels must be counted only within the section following a heading matching `sensitivity|scenario`, not the whole document |
| `ltv-churn-assumption-gate.sh` | 60-char window around `churn`/`ndr` (already adjacency-aware within a sentence) | **Upgrade to section-scoped, keep the window**: the existing 60-char sentence-level window stays (it already correctly rejects "churn mentioned nowhere near a number"), but is additionally required to fall within the section containing the `ltv` occurrence it is meant to qualify, not just anywhere in the document that happens to have a churn+digit pair within 60 chars |
| `ltv-cac-band-gate.sh` | already adjacency-aware (`PROXIMITY_WINDOW = 120`) | **No functional change** — this is the reference implementation the other 6 are upgraded to match; phase 2 should still route its window/normalization helpers through core's shared library per §1, but the check logic itself is not the audit's target |

## 3. MANDATORY TEST CASES phase 2 must satisfy

Every case below is chosen specifically because a flat substring check
passes it (false allow, or false deny for the foreign-path cases) while
the structural/adjacency check in §2 correctly reverses the verdict. All
cases are in addition to — not a replacement for — the existing
allow/deny/foreign-path/kill-switch triad each gate already has
(survey confirmed these exist for content logic today; the gap is the
input-plumbing and adjacency cases below).

### Input-plumbing cases (apply to all 7 gates identically)

1. **Malformed JSON payload** → expected: **deny** (exit 2, stderr
   message). Today: silent allow (survey §1). This is the single
   highest-priority regression test — every gate needs it.
2. **`MultiEdit` tool_input with `edits: [{old_string, new_string}, ...]`,
   no top-level `content`/`new_string`, and a `new_string` that
   introduces content which would fail the gate if written via `Write`**
   → expected: **deny**, same verdict as the equivalent `Write`. Today:
   silent no-op allow (survey §2) because `content` resolves to `""`.
3. **`file_path` containing a `..` segment that resolves outside
   `docs/issue-<n>/reports/` or `docs/issue-<n>/proposals/` but whose
   raw string still ends in a matched suffix** (e.g.
   `docs/issue-9/reports/../../elsewhere/finance-unit-economics.md`) →
   expected: **no-op / not-a-match** (gate must not fire on a path that
   does not actually resolve under the scoped directory). Today: an
   `endswith`/`re.search` on the raw string could incorrectly fire or
   incorrectly no-op depending on the exact string shape — the point of
   the test is that normalization decides the outcome deterministically,
   not string luck.
4. **Kill-switch env var set to an unrecognized, non-empty value** (e.g.
   `FINANCE_CAC_PAYBACK_GATE_OFF=maybe`) → expected: gate stays **denying**
   (active) on content that would otherwise be denied, per §1's
   fail-closed kill-switch requirement — same as an explicit `1`, not
   the same as `0`/`off`/unset.
5. **`CLAUDE_ROLE` unset entirely** (not empty string — the variable
   genuinely absent from the environment) on a proposal-path write
   scoped to `finance-evidence-chain` / `finance-proposal-shape` →
   expected: gate **still evaluates** (does not silently no-op) — proves
   the earlier README-ghost-file gap (survey §3) cannot recur once these
   two gates' role-default behavior is retested explicitly, not just
   assumed from reading the source.

### Adjacency/structural cases (per §2's table, one pair per upgraded gate)

6. **`produces-fields-gate.sh`**: a document with `## cac` heading and a
   number, and a stray occurrence of the literal string `ltv` inside the
   `## cac` section's prose (but no real `## ltv` heading or LTV figure
   anywhere else) → expected: **deny**, missing `ltv`. Today: passes,
   because `lower.find("ltv")` finds the stray substring anywhere.
7. **`evidence-chain-gate.sh`**: a proposal with `"mandate"` in paragraph
   1 and `"necessary"` in paragraph 9 (unrelated topic) → expected:
   **deny**, no same-paragraph chain. Today: passes (file-wide `has`).
8. **`proposal-shape-gate.sh`**: a proposal containing the sentence
   "we have not written a Decision requested section yet" (phrase
   present, not as a heading, and semantically the opposite of
   satisfying the requirement) → expected: **deny**. Today: passes
   (substring `"decision requested" in low`).
9. **`cac-payback-gate.sh`**: a record with `cac` and `arpu` each defined
   in an early glossary section, and `"payback"` mentioned 2000
   characters later with neither term repeated nearby → expected:
   **deny**, formula inputs not visible near the number. Today: passes
   (file-wide `and`).
10. **`sensitivity-scenario-gate.sh`**: a record with two scenario labels
    (`"base case"`, `"downside"`) appearing under an unrelated `## Risks`
    heading, and the actual `## Sensitivity` section containing only one
    labeled scenario → expected: **deny** (the real sensitivity section
    is under-specified). Today: passes (file-wide label count >= 2).
11. **`ltv-cac-band-gate.sh`** (regression guard, not a new gap): a
    record with a band word (`"strong"`) 500 characters from any
    `ltv:cac`/`ltv-cac` occurrence → expected: **deny**, stays denied
    after any refactor — this is the existing correct behavior; the
    mandatory test just needs to survive the §1 gate-lib migration
    without regressing.

## 4. README reconciliation (audit item 4)

Phase 2 must rewrite `README.md`'s Layout section to list only files
that exist: `finance-unit-economics/hooks/directive.sh`,
`finance-unit-economics/hooks/produces-fields-gate.sh`, and each of the
6 satellite plugins' own `hooks/*.sh` (currently entirely undocumented
in the root README, which only describes the base plugin). Remove the
three ghost entries (`record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`) or replace them with an explicit statement
that core's canon copy now covers that ground (per
`produces-fields-gate.sh`'s own header comment, which already says this
for `record-fields-gate.sh` specifically — the README was never updated
to match). Document every kill-switch env var name (7 gates = 7 switch
names) in one table, since today they are discoverable only by reading
each script's header comment individually.

## 5. Constraints check

- No hook, test, or plugin file created/edited in this phase — only
  `docs/issue-13/reports/finance-unit-economics/{survey.md,scout-brief.md}`
  and this proposal.
- Nothing in this proposal approves phase 2 or asserts core issue #72
  has landed — §0 states the precondition is unverified from this
  workspace and must be re-checked.
- No `docs/issue-13/reports/finance-unit-economics.md` written (phase-2
  record file, forbidden pre-approval).

## Decision requested

Approve phase 2 to, in this order:

1. Confirm core issue #72 has landed and read the actual
   `core/hooks/lib/gate-lib.sh` + `docs/handbooks/gate-house-standard.md`
   interface; reconcile §1's function contract against what actually
   shipped (rename/adjust as needed — §1 is a contract, not verbatim
   code, because this workspace could not read the real library).
2. Rewire all 7 gates in this plugin set to call core's shared library
   for payload parsing, MultiEdit-inclusive content extraction, absolute
   path normalization, fail-closed malformed-JSON handling, and (if
   defined) a shared kill-switch value vocabulary and deny-emission
   helper — removing each gate's local reimplementation of these four
   concerns.
3. Upgrade each gate's methodology check per §2's table
   (section-scoped / paragraph-adjacent / windowed, generalizing
   `ltv-cac-band`'s existing proximity pattern).
4. Add every test case in §3 to each affected gate's test file under
   `tests/`, and confirm the full suite is green in the same commit that
   ships the code (issue #13 requirement 3: "배송 상태에서 전 스위트
   green").
5. Rewrite `README.md` per §4.
6. Record the phase-2 change in `docs/issue-13/reports/finance-unit-economics.md`
   once executed, citing this proposal and the actual `gate-lib.sh`
   functions called.
