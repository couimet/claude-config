#!/usr/bin/env bash
#
# secret-scan.sh - lightweight secret scanner for this repository.
#
# Usage: secret-scan.sh [staged|tree]
#   staged (default): scan the lines a commit adds, each prefixed with ">".
#   tree: scan all tracked file contents (used by CI).
#
# Exits 1 when a likely secret is found. Matched content is never printed, so
# a real secret does not leak into hook or CI logs. The checks are heuristic
# and deliberately conservative; GitHub secret scanning and push protection on
# a public repository are the backstop this tool is not.
set -euo pipefail

mode="${1:-staged}"
case "$mode" in
  staged|tree) ;;
  *)
    echo "usage: $0 [staged|tree]" >&2
    exit 2
    ;;
esac

# Token-like values, private-key blocks, and credential field assignments.
PATTERN='ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|sk-[A-Za-z0-9-]{16,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(api[_-]?key|auth[_-]?token|access[_-]?token|client[_-]?secret|private[_-]?key|password|passwd|secret)[[:space:]]*[:=][[:space:]]*[^[:space:],;]{8,}'

emit_lines() {
  case "$mode" in
    staged)
      # Only the lines a commit is about to add. --output-indicator-new marks
      # each added line with '>', so the "+++ b/<path>" header keeps its own
      # leading '+' and an added line that starts with "++" is not mistaken for
      # a header. --text makes git emit a hunk for a binary file, and
      # --no-ext-diff with --no-textconv stop a local driver from replacing the
      # diff output. No --diff-filter, so a rename or a type change is read too.
      git diff --cached --no-ext-diff --no-textconv --text -U0 \
        --output-indicator-new='>' | grep -a '^>' || true
      ;;
    tree)
      local file
      while IFS= read -r -d '' file; do
        # Git stores a symlink as a blob that holds its target string, so scan
        # that string. `[ -f ]` follows the link and is false for a dangling
        # symlink, which would hide the target from this scan.
        if [ -L "$file" ]; then
          readlink -- "$file"
        elif [ -f "$file" ]; then
          cat -- "$file"
        fi
      done < <(git ls-files -z)
      ;;
  esac
}

matches=0
while IFS= read -r _matched; do
  matches=$((matches + 1))
done < <(emit_lines | grep -aE "$PATTERN" || true)

if [ "$matches" -gt 0 ]; then
  echo "secret-scan: $matches possible secret(s) matched in $mode content; commit blocked. Matched lines are suppressed." >&2
  exit 1
fi

echo "secret-scan: clean ($mode)"
exit 0
