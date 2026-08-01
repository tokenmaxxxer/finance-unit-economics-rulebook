#!/usr/bin/env bash
# Shared test-only helper (not shipped in any plugin) for locating the real
# installed core plugin (issue-72's gate-lib.sh/.py). This repo does not
# vendor core (reference-not-copy rule); the gates' own
# ${CLAUDE_PLUGIN_ROOT_CORE:-../../core} fallback only resolves at real
# plugin-install time, not from a bare git checkout run via
# `bash tests/*.test.sh`, so tests must locate and export
# CLAUDE_PLUGIN_ROOT_CORE explicitly before invoking any gate.
find_core_root() {
  if [ -n "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]; then
    return 0
  fi
  local c
  for c in \
    "$HOME/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core" \
    $(find "$HOME/.claude/plugins/marketplaces" -maxdepth 6 -type d -name core -path '*tokenmaxxxer-core*' 2>/dev/null)
  do
    if [ -n "$c" ] && [ -f "$c/hooks/lib/gate-lib.sh" ]; then
      export CLAUDE_PLUGIN_ROOT_CORE="$c"
      return 0
    fi
  done
  return 1
}

if ! find_core_root; then
  echo "SKIP: core plugin (issue-72 gate-lib.sh/.py) not found on this machine — cannot exercise gate-lib-backed gates" >&2
  exit 0
fi

# run_gate <gate-script> <project-dir> <json-payload> [extra env NAME=VAL ...]
run_gate() {
  local gate="$1" dir="$2" payload="$3"
  shift 3
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$dir" CLAUDE_PLUGIN_ROOT_CORE="$CLAUDE_PLUGIN_ROOT_CORE" "$@" bash "$gate"
}

mk_project() {
  mktemp -d
}
