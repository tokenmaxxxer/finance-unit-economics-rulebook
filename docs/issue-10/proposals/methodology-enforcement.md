# issue-10 phase-1 proposal — finance-unit-economics methodology enforcement

Grounded in `docs/issue-10/reports/finance-unit-economics/survey.md`
(internal gaps) and
`docs/issue-10/reports/finance-unit-economics/scout-brief.md` (internal
field survey of `pricing-rulebook` and `implementation-rulebook`). This
is a proposal only — no plugin file is edited in this phase, per the
issue's "phase 1 ONLY" instruction. Canon scripts are referenced, never
copied (`docs/handbooks/canon-scripts.md`); nothing proposed below lives
under `core/hooks/`, so this is entirely role-owned, not a canon copy.

## 1. Directive deepening (phase 1 / phase 2, per facet)

`finance-unit-economics/hooks/directive.sh`'s four strings stay
one-line-each at `SessionStart` (the core `role-directive.sh` library's
`core_role_directive` signature is fixed and shared across all 43
rulebooks — reshaping it is out of this role's write scope). What
deepens is (a) the strings themselves, made phase-aware, and (b) a new
worked-reasoning handbook the strings point to, matching
`pricing-rulebook`'s split between a mechanical gate and
`docs/handbooks/pricing/methodology.md`'s reasoning.

**Proposed `directive.sh` content** (phase 2 executes this verbatim):

```bash
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
you_decide="YOU DECIDE: 단위경제상 성립하는가"
use_when="USE_WHEN: 가격/비용 구조가 걸린 결정일 때"
produces="PRODUCES (phase 1: evidence-backed methodology proposal; phase 2: unit economics record with CAC, LTV on margin, LTV:CAC ratio + band judgment, CAC payback period, sensitivity/scenario section with >=2 numeric scenarios — see docs/handbooks/finance-unit-economics/methodology.md for the full checklist and what is forbidden at each phase)"
hand_off="HAND-OFF: 실제 가격 숫자 결정은 → pricing. If the work drifts into an actual price recommendation, stop and hand off per this arrow rather than absorbing pricing's scope."
core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
```

**Proposed handbook**
(`docs/handbooks/finance-unit-economics/methodology.md`), phase-1 /
phase-2 facets each with executable criteria and explicit prohibitions
(full text phase 2 lands verbatim):

```markdown
# Finance-unit-economics methodology checklist

Worked guidance for `docs/issue-1/proposals/rulebook-maturation.md`. The
gate (`finance-unit-economics/hooks/methodology-gate.sh`) enforces the
mechanical minimum below; this handbook is the reasoning behind each
line. Companion to `finance-unit-economics/hooks/produces-fields-gate.sh`,
which checks field *presence*; this handbook (and the methodology gate)
cover field *quality*.

## Phase-1 proposal — steps, criteria, prohibitions

Steps, in order, within the single proposal document (no cross-write
sequencing — see "Why no state tracking" below):

1. **Survey first.** State the internal current-state gap this proposal
   closes, separately from any external claim.
2. **Name the field claim and its evidence.** For every adopted metric
   (CAC, LTV, LTV:CAC, CAC payback, sensitivity), cite either a real URL
   consulted this phase, or the explicit label "working from
   named-framework assumption, not fabricated citation." A framework
   name with neither a URL nor that label is not adequate evidence.
3. **State the chain**: field evidence → this role's mandate ("단위경제상
   성립하는가") → why the item is necessary to answer that mandate. A
   metric justified only by "this is common practice elsewhere" fails
   this step — the chain must terminate at this role's own mandate, not
   at general industry convention.
4. **Give the phase-2 reflection plan**: the exact `produces` string, the
   `REQUIRED_FIELDS` list, and the gate logic changes phase 2 will
   execute without re-deriving methodology.
5. **Name what phase 2 requests** in a "Decision requested" section.

Prohibited at phase 1: adopting a metric with a fabricated citation;
adopting a metric with no stated chain back to the mandate; a phase-2
reflection plan that only says "add the field" with no proposed gate
logic; silently expanding scope into pricing's own `얼마를, 어떤
구조로` decision (that drift routes through the hand-off line, recorded,
not absorbed).

## Phase-2 record — steps, criteria, prohibitions

The record (`docs/issue-<n>/reports/finance-unit-economics.md`) states
fielded fact, not plan:

1. **CAC** — formula and the spend/customer-count assumptions used,
   stated explicitly next to the number.
2. **LTV** — computed on margin, not gross revenue; the churn-rate /
   retention-horizon assumption stated explicitly.
3. **LTV:CAC ratio with a band judgment**, not a bare number: interpret
   against the field's accepted bands (≥3:1 floor, 4:1-5:1 strong, <2:1
   red flag, per `docs/issue-1/reports/finance-unit-economics/
   scout-brief.md`). A ratio with no band word attached is prohibited —
   it is indistinguishable from an unread number.
4. **CAC payback period**, computed as
   `CAC / (Monthly ARPU × Gross Margin %)`, with the formula visible next
   to the number — not because the formula is exotic, but because a bare
   payback number with no visible inputs cannot be checked by a reader.
5. **Sensitivity/scenario section with at least two distinct numeric
   scenarios** (e.g. base case vs. downside on churn or margin). A
   heading with one scenario, or numbers with no scenario labels, is
   prohibited — this is this role's whole value-add over a static
   number, and it is the item most likely to be satisfied by a
   token-only heading if not checked for real content.

Explicitly not required: full cohort-by-cohort retention curve modeling
or vintage-level reporting — that is FP&A-deliverable work requiring a
data/billing pipeline this thin advisory role does not own (per
`docs/issue-1/proposals/rulebook-maturation.md` (b)/(c)).

## Why no cross-write state tracking

`implementation-rulebook`'s coding role tracks a survey-before-hunt
sequence across *separate* write events with `hunt-state.sh` because
that sequence spans genuinely distinct documents produced at different
times. This role's "조사→근거→채택" order is intra-document: every
adopted metric's evidence and chain are required in the *same* phase-1
proposal write that names the metric (step 2/3 above), so a single
content check on that one write already enforces the order — there is
no second write whose absence or lateness needs tracking. Building a
state file for this would enforce a sequence that doesn't cross a write
boundary; if a future methodology round introduces a genuine
multi-write sequence, add tracking then, against that concrete need.
```

## 2. Methodology gate (`finance-unit-economics/hooks/methodology-gate.sh`)

New file, alongside (not replacing) `produces-fields-gate.sh`: the
existing gate keeps checking field *presence* + a nearby number; this
gate checks field *quality*, and — unlike the existing gate — also
covers the phase-1 proposal surface. Registered as a second command on
the same `PreToolUse` matcher in `hooks.json` (no structural change to
the matcher itself).

Path scoping improves on `pricing-rulebook`'s filename-substring regex
(scout-brief.md, performance axis 1): the phase-2 record path stays the
same fixed suffix `produces-fields-gate.sh` already uses
(`docs/issue-<n>/reports/finance-unit-economics.md`); the phase-1
proposal surface is scoped by `CLAUDE_ROLE == finance-unit-economics`
plus the fixed directory pattern `docs/issue-<n>/proposals/*.md`,
instead of guessing from the filename.

```bash
#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — finance-unit-economics-specific
# methodology QUALITY checks, on top of (never instead of)
# produces-fields-gate.sh's field PRESENCE checks and core canon's
# role-agnostic record-fields-gate.sh.
#
# Targets: docs/issue-<n>/proposals/*.md written under
# CLAUDE_ROLE=finance-unit-economics (phase-1 proposals) and
# docs/issue-<n>/reports/finance-unit-economics.md (phase-2 record).
#
# Kill switch: export FINANCE_UNIT_ECONOMICS_METHODOLOGY_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-finance-unit-economics}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

case "${FINANCE_UNIT_ECONOMICS_METHODOLOGY_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "methodology-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

FE_PAYLOAD="$payload" FE_ROLE="$role" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("%s: refused — %s\n" % (os.environ.get("FE_ROLE", "finance-unit-economics"), msg))
    sys.exit(2)

payload = os.environ.get("FE_PAYLOAD", "")
try:
    event = json.loads(payload)
except Exception:
    sys.exit(0)
if not isinstance(event, dict):
    sys.exit(0)

ti = event.get("tool_input")
if not isinstance(ti, dict):
    sys.exit(0)
target = None
for k in ("file_path", "notebook_path"):
    v = ti.get(k)
    if isinstance(v, str) and v:
        target = v
        break
if not target:
    sys.exit(0)
rel = target.replace("\\", "/")

is_record = rel.endswith("/reports/finance-unit-economics.md") or rel == "reports/finance-unit-economics.md"
is_proposal = (
    os.environ.get("FE_ROLE") == "finance-unit-economics"
    and re.search(r'(^|/)docs/issue-[0-9]+/proposals/[^/]+\.md$', rel) is not None
)
if not (is_record or is_proposal):
    sys.exit(0)

content = ti.get("content") or ti.get("new_string") or ""
low = content.lower()

def has_any(*needles):
    return any(n in low for n in needles)

missing = []

if is_proposal:
    mentions_metric = has_any("cac", "ltv", "payback", "sensitivity")
    if mentions_metric:
        sourced = has_any("http://", "https://", "working from named-framework assumption")
        if not sourced:
            missing.append("source-or-assumption-label")
        chained = has_any("mandate", "necessary", "→")  # arrow: evidence -> mandate -> necessity
        if not chained:
            missing.append("evidence-to-mandate-chain")
    if not has_any("required_fields", "produces"):
        missing.append("phase-2-reflection-plan")
    if not has_any("decision requested"):
        missing.append("decision-requested-section")

if is_record:
    if has_any("ltv:cac") or has_any("ltv-cac") or has_any("ltv/cac"):
        if not has_any("floor", "strong", "red flag", "3:1", "4:1", "5:1", "2:1"):
            missing.append("ratio-band-judgment")
    scenario_labels = re.findall(r'\bscenario\s*\d\b|\bbase case\b|\bdownside\b|\bupside\b|\bbull\b|\bbear\b', low)
    if has_any("sensitivity") and len(set(scenario_labels)) < 2:
        missing.append("sensitivity-two-scenarios")
    if has_any("payback") and not (has_any("cac") and has_any("arpu")):
        missing.append("payback-formula-visible")

if missing:
    deny(
        "finance-unit-economics methodology write is missing required element(s): "
        + ", ".join(missing)
        + ". Per docs/handbooks/finance-unit-economics/methodology.md, a phase-1 "
          "proposal must source or assumption-label every adopted metric, chain it "
          "to this role's mandate, give a concrete phase-2 reflection plan, and "
          "name a Decision requested section; a phase-2 record must give the "
          "LTV:CAC ratio a band judgment, show >=2 sensitivity scenarios, and keep "
          "the payback formula's inputs visible next to the number."
    )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
```

**`hooks.json` change**: add a second command to the existing
`PreToolUse` entry (matcher unchanged), so both gates run on every
Write/Edit/MultiEdit/NotebookEdit:

```json
"PreToolUse": [
  {
    "matcher": "Write|Edit|MultiEdit|NotebookEdit",
    "hooks": [
      { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/produces-fields-gate.sh" },
      { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/methodology-gate.sh" }
    ]
  }
]
```

## 3. Gate tests

New repo-root `tests/run-gate-tests.sh`, following
`implementation-rulebook`'s subprocess-harness shape (scout-brief.md).
Cases (phase 2 writes the runnable script; shape fixed here so phase 2
does not re-derive it):

- **allow** — phase-1 proposal with a sourced/assumption-labeled metric,
  an evidence→mandate chain, a `produces`/`REQUIRED_FIELDS` reflection
  plan, and a "Decision requested" heading.
- **deny** — same proposal with the "Decision requested" heading
  removed.
- **deny** — proposal naming `cac`/`ltv` with neither a URL nor the
  assumption-label phrase.
- **allow** — phase-2 record with a `3:1` band word next to
  `ltv:cac`, two labeled sensitivity scenarios, and `cac`+`arpu` both
  present near `payback`.
- **deny** — same record with the ratio number present but no band word.
- **deny** — same record with only one sensitivity scenario label.
- **allow, foreign-path** — a write to an unrelated file
  (`docs/issue-10/reports/qa.md`) is a no-op regardless of content, per
  the exemplar's foreign-path convention (scout-brief.md).
- **kill switch** — `FINANCE_UNIT_ECONOMICS_METHODOLOGY_GATE_OFF=1`
  allows a write that would otherwise be denied.

## 4. Agents / checklist

No new agent is proposed. The phase-1 and phase-2 checklists above are
the "repeated procedure" issue-10 asks for a checklist to cover; a new
agent would duplicate what the handbook + mechanical gate already
enforce, for a role whose entire scope is one advisory verdict per issue
(no multi-step build loop the way `coding`'s hunt/build cycle has).
`finance-unit-economics/agents/warrant-hunter.md` stays untouched, per
issue-1's scope note and this issue's own constraint against touching
canon-adjacent stubs outside scope.

## 5. Constraints check

- Canon scripts referenced, never copied: nothing above touches
  `core/hooks/`; `methodology-gate.sh` is a new role-owned file, the same
  shape as `pricing-rulebook`'s own role-owned `methodology-gate.sh`.
- Role boundary / `write_scope` unchanged: all proposed files live under
  `finance-unit-economics/`, `docs/handbooks/finance-unit-economics/`,
  and repo-root `tests/`; no other role's tree is touched.
- Adopted-methodology source: `docs/issue-1/proposals/
  rulebook-maturation.md` and `docs/issue-1/reports/finance-unit-economics/
  scout-brief.md` are the sole methodology sources reflected into the
  gate and handbook above — no new metric is invented in this proposal.

## Decision requested

Approve phase 2 to:

1. Replace `finance-unit-economics/hooks/directive.sh` with the content
   in §1.
2. Add `docs/handbooks/finance-unit-economics/methodology.md` with the
   content in §1.
3. Add `finance-unit-economics/hooks/methodology-gate.sh` with the
   content in §2, and register it in `finance-unit-economics/hooks/
   hooks.json` per §2's `PreToolUse` change.
4. Add `tests/run-gate-tests.sh` at the repo root covering the cases in
   §3.
5. Leave `finance-unit-economics/agents/warrant-hunter.md` and
   `finance-unit-economics/hooks/produces-fields-gate.sh` unchanged, per
   §4's no-new-agent call and §1's "on top of, not instead of" framing.
6. Record the phase-2 change and its rationale in
   `docs/issue-10/reports/finance-unit-economics.md` once executed.

