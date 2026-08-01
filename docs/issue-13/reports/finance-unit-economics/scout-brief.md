# issue-13 scout brief — gate A+ upgrade (substring → structural checks)

Mode: batched-sequential, single session. 2 stages: (1) internal —
`core`'s gate-house standard artifacts (`core/hooks/lib/gate-lib.sh`,
`docs/handbooks/gate-house-standard.md`) were sought but are **not
present in this repo** (`core` resolves as a separate installed plugin
at runtime per `finance-unit-economics/hooks/directive.sh:2`'s
`CLAUDE_PLUGIN_ROOT_CORE` fallback; no `core/` tree, no
`docs/handbooks/gate-house-standard.md` exist in this checkout).
Scouting for that half fell back to internal precedent only: this role's
own best-in-repo adjacency implementation (`finance-ltv-cac-band`'s
`PROXIMITY_WINDOW` check) and issue-10's own scout-brief (pricing/
implementation-rulebook exemplars, already on record). (2) external —
one web search was run (below), since the design question ("substring
vs. structural/adjacency gate checks") is a generic-enough tooling
question that a single search meaningfully bounds it; not a deep
research pass, matching this phase's bounded-sweep budget. Stopped after
one search round — result converged with what the internal exemplar
(`ltv-cac-band`) already independently arrived at, so a second round
would not change the design (saturation).

## External finding

Semantic/language-aware diff tooling treats line-based/substring
matching as brittle: a classical line-diff "works well if each piece of
information is stored on a separate line, but adding line breaks... is
enough to break the matching," while structural approaches "distinguish
between relevant and irrelevant changes" and validate on structure/
adjacency, not raw text presence (SemanticDiff blog,
semanticdiff.com/blog/semanticdiff-vs-difftastic). This generalizes
directly to this issue's own audit line 2 ("시맨틱 검사를 부분문자열에서
섹션/인접성/구조 검사로"): a file-wide substring check is the same
failure mode as a naive line diff — content anywhere in the document
satisfies it, regardless of section or adjacency to the concept it's
supposed to modify.

## Internal finding

`finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh` already implements
bounded-window proximity matching (`PROXIMITY_WINDOW = 120` chars around
each ratio-token occurrence) — the only one of the 7 shipped gates that
does. This is the pattern to generalize to the other 6, not a new
invention (see proposal §2).

## Adopt / skip

- **Adopt**: proximity/adjacency-window matching generalized from
  `ltv-cac-band`'s existing pattern to every other gate's checks;
  section-header scoping (only check content under the relevant `##`
  heading, not the whole document) as the next tier up from a raw
  character window, for checks that have a natural section anchor
  (sensitivity scenarios, decision-requested).
- **Skip**: full AST/markdown-parse structural diffing — over-built for
  a plain-text methodology gate; a section-scoped + proximity-windowed
  regex check is proportionate to this role's existing weight (per
  issue-10 scout-brief's "segment fit" finding, unchanged here).

## Sources

- `finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh` (this repo)
- `finance-unit-economics/hooks/directive.sh` (this repo, confirms `core`
  is an external plugin, not vendored)
- `docs/issue-10/reports/finance-unit-economics/scout-brief.md` (this repo)
- [SemanticDiff vs. Difftastic: How do they differ?](https://semanticdiff.com/blog/semanticdiff-vs-difftastic/)
