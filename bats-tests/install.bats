#!/usr/bin/env bats

# BATS tests for install.sh. Every test runs against a scratch HOME so the
# real ~/.claude on this machine is never touched.

ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
INSTALL="$ROOT/install.sh"
SOURCE="$ROOT/templates/claude/CLAUDE.md"

setup() {
  export HOME
  HOME="$(mktemp -d "${TMPDIR:-/tmp}/claude-config-test.XXXXXX")"
}

teardown() {
  rm -rf "$HOME"
}

@test "fresh install symlinks ~/.claude/CLAUDE.md to the repo file" {
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  [ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$SOURCE" ]
  diff -q "$HOME/.claude/CLAUDE.md" "$SOURCE"
  [[ "$output" == *installed* ]]
}

@test "re-running is idempotent and reports unchanged" {
  run "$INSTALL"
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  [ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$SOURCE" ]
  [[ "$output" == *unchanged* ]]
}

@test "replaces an unrelated symlink at the target" {
  mkdir -p "$HOME/.claude"
  ln -s /somewhere/else/CLAUDE.md "$HOME/.claude/CLAUDE.md"
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$SOURCE" ]
  [[ "$output" == *updated* ]]
}

@test "leaves an existing regular file untouched and warns" {
  mkdir -p "$HOME/.claude"
  printf 'local CLAUDE.md the user owns\n' > "$HOME/.claude/CLAUDE.md"
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.claude/CLAUDE.md" ]
  [ ! -L "$HOME/.claude/CLAUDE.md" ]
  [[ "$output" == *warning* ]]
  [ "$(cat "$HOME/.claude/CLAUDE.md")" = 'local CLAUDE.md the user owns' ]
}

@test "leaves an existing directory at the target untouched and warns" {
  mkdir -p "$HOME/.claude/CLAUDE.md"
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ -d "$HOME/.claude/CLAUDE.md" ]
  [ ! -L "$HOME/.claude/CLAUDE.md" ]
  [[ "$output" == *warning* ]]
}

@test "installs correctly from another working directory" {
  cd "$HOME"
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  [ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$SOURCE" ]
}

@test "never creates or modifies settings.json or .claude.json" {
  mkdir -p "$HOME/.claude"
  printf '{"permissions":{"allow":[]}}\n' > "$HOME/.claude/settings.json"
  printf '{"mcpServers":{}}\n' > "$HOME/.claude.json"
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.claude/settings.json")" = '{"permissions":{"allow":[]}}' ]
  [ "$(cat "$HOME/.claude.json")" = '{"mcpServers":{}}' ]
}

@test "fresh install creates no settings.json or .claude.json" {
  run "$INSTALL"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/settings.json" ]
  [ ! -e "$HOME/.claude.json" ]
}
