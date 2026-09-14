#!/usr/bin/env bash
#
# install.sh - installs exactly one artifact, the default CLAUDE.md, into
# ~/.claude/CLAUDE.md, as a symlink back to this repository.
#
# Safety contract:
#   - Idempotent: re-running leaves an already-managed link unchanged.
#   - Non-destructive: an existing regular file or directory at the target is
#     never touched; install.sh warns and skips it.
#   - This script never creates, overwrites, or merges ~/.claude/settings.json
#     or ~/.claude.json. It never even references them.
set -euo pipefail

# Where this script lives, resolved to the physical path.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# When run from a linked git worktree, point at the main checkout's source so
# the global symlink survives worktree removal. git-common-dir's parent is the
# main checkout root in every worktree configuration.
if git_common="$(git -C "$REPO_DIR" rev-parse --git-common-dir 2>/dev/null)"; then
  [[ "$git_common" == /* ]] || git_common="$REPO_DIR/$git_common"
  REPO_DIR="$(cd "$(dirname "$git_common")" && pwd -P)"
fi

SOURCE="$REPO_DIR/templates/claude/CLAUDE.md"
TARGET="$HOME/.claude/CLAUDE.md"

if [ ! -f "$SOURCE" ]; then
  echo "install.sh: error: $SOURCE not found. Run this script from the claude-config repository." >&2
  exit 1
fi

mkdir -p "$HOME/.claude"

state=""
if [ -L "$TARGET" ]; then
  if [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
    state="unchanged"
  else
    rm "$TARGET"
    state="updated"
  fi
elif [ -e "$TARGET" ]; then
  echo "install.sh: warning: $TARGET exists and is not a symlink managed by claude-config. Skipping." >&2
  echo "             Remove it manually if you want it managed by claude-config." >&2
  exit 0
else
  state="installed"
fi

if [ "$state" != "unchanged" ]; then
  ln -s "$SOURCE" "$TARGET"
fi

echo "install.sh: $state $TARGET -> $SOURCE"
