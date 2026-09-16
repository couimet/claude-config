#!/usr/bin/env bats

# BATS tests for scripts/secret-scan.sh. Every test runs inside a scratch git
# repository under BATS_TEST_TMPDIR, so the working tree of this repository is
# never staged, committed, or modified.
#
# Secret-shaped fixtures are built at run time. A literal token or credential
# assignment in this file would be flagged by the scanner under test, both by
# the pre-commit hook and by `make scan`.

ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
SCAN="$ROOT/scripts/secret-scan.sh"

# ghp_ followed by 36 alphanumerics, the shape of a GitHub personal token.
github_token() {
  printf 'ghp_%s' "$(printf 'a%.0s' $(seq 1 36))"
}

# A credential field assignment, the second alternative in the scanner pattern.
api_key_line() {
  printf 'api_key: %s' "$(printf 'k%.0s' $(seq 1 24))"
}

setup() {
  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email "bats@example.invalid"
  git -C "$REPO" config user.name "BATS"
  git -C "$REPO" config commit.gpgsign false
  cd "$REPO"
}

commit_all() {
  git add -A
  git commit -q -m "scratch"
}

@test "defaults to staged mode and reports clean content" {
  echo "harmless content" > notes.txt
  git add notes.txt

  run "$SCAN"

  [ "$status" -eq 0 ]
  [[ "$output" == *"clean (staged)"* ]]
}

@test "accepts staged as an explicit mode" {
  echo "harmless content" > notes.txt
  git add notes.txt

  run "$SCAN" staged

  [ "$status" -eq 0 ]
  [[ "$output" == *"clean (staged)"* ]]
}

@test "reports clean tracked content in tree mode" {
  echo "harmless content" > notes.txt
  commit_all

  run "$SCAN" tree

  [ "$status" -eq 0 ]
  [[ "$output" == *"clean (tree)"* ]]
}

@test "rejects an unknown mode with a usage error" {
  run "$SCAN" bogus

  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: $SCAN [staged|tree]"* ]]
}

@test "blocks a staged token and never echoes the matched line" {
  printf 'token = %s\n' "$(github_token)" > config.txt
  git add config.txt

  run "$SCAN" staged

  [ "$status" -eq 1 ]
  [[ "$output" == *"possible secret(s) matched in staged content"* ]]
  [[ "$output" == *"commit blocked"* ]]
  [[ "$output" != *"$(github_token)"* ]]
}

@test "blocks a staged credential assignment" {
  printf '%s\n' "$(api_key_line)" > config.txt
  git add config.txt

  run "$SCAN" staged

  [ "$status" -eq 1 ]
  [[ "$output" == *"commit blocked"* ]]
}

@test "blocks a token in tracked content during a tree scan" {
  printf 'token = %s\n' "$(github_token)" > config.txt
  commit_all

  run "$SCAN" tree

  [ "$status" -eq 1 ]
  [[ "$output" == *"possible secret(s) matched in tree content"* ]]
  [[ "$output" != *"$(github_token)"* ]]
}

@test "reports clean when a commit adds no lines" {
  echo "harmless content" > notes.txt
  commit_all
  git rm -q notes.txt

  run "$SCAN" staged

  [ "$status" -eq 0 ]
  [[ "$output" == *"clean (staged)"* ]]
}

@test "skips a missing tracked file silently and scans the rest" {
  # A file deleted but not staged is normal during interactive work, so the
  # scan must not complain about it. Without the `[ -f ]` guard, `cat` reports
  # the missing path on stderr while the scan itself still succeeds.
  printf 'token = %s\n' "$(github_token)" > a-missing.txt
  printf 'token = %s\n' "$(github_token)" > z-secret.txt
  commit_all
  rm a-missing.txt

  run "$SCAN" tree

  [ "$status" -eq 1 ]
  [[ "$output" == *"possible secret(s) matched in tree content"* ]]
  [[ "$output" != *"a-missing.txt"* ]]
}

@test "ignores the diff header when a file name looks like a token" {
  # The scanner selects added lines by their ">" marker, so the "+++ b/<name>"
  # header line never reaches the pattern.
  printf 'harmless content\n' > "$(github_token)"
  git add .

  run "$SCAN" staged

  [ "$status" -eq 0 ]
  [[ "$output" == *"clean (staged)"* ]]
}

@test "blocks a staged line whose content starts with a double plus" {
  # The old extractor stripped the leading "+" and then deleted every line that
  # began with "++". Added content that starts with "++" therefore read as a
  # file header and was skipped.
  printf '++%s\n' "$(api_key_line)" > config.txt
  git add config.txt

  run "$SCAN" staged

  [ "$status" -eq 1 ]
  [[ "$output" == *"commit blocked"* ]]
}

@test "blocks a token added inside a binary file" {
  # Without --text, git reports a binary addition as "Binary files ... differ"
  # and emits no hunk, so the added bytes never reach the scanner.
  printf 'prefix\0%s\0suffix' "$(github_token)" > blob.bin
  git add blob.bin

  run "$SCAN" staged

  [ "$status" -eq 1 ]
  [[ "$output" == *"commit blocked"* ]]
  [[ "$output" != *"$(github_token)"* ]]
}

@test "blocks a token added in the same commit as a rename" {
  # A rename entry carries status R. A `--diff-filter=ACM` argument dropped that
  # entry, so the lines the commit adds were never read.
  git -C "$REPO" config diff.renames true
  printf 'line one\nline two\nline three\nline four\nline five\n' > notes.txt
  commit_all
  git mv notes.txt renamed.txt
  printf '%s\n' "$(api_key_line)" >> renamed.txt
  git add -A

  run "$SCAN" staged

  [ "$status" -eq 1 ]
  [[ "$output" == *"commit blocked"* ]]
}

@test "blocks a token stored as the target of a dangling symlink" {
  # Git stores a symlink as a blob that holds its target string. The old `-f`
  # test followed the link and was false for a dangling one, so a tree scan
  # never read the target.
  ln -s "$(api_key_line)" dangling-link
  commit_all

  run "$SCAN" tree

  [ "$status" -eq 1 ]
  [[ "$output" == *"possible secret(s) matched in tree content"* ]]
  [[ "$output" != *"$(api_key_line)"* ]]
}
