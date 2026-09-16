# CLAUDE.md

Project instructions for working in the claude-config repository. This file describes the repository and is never installed. The machine-wide default operating rules live in `templates/claude/CLAUDE.md`.

## What this repository maintains

- `templates/claude/CLAUDE.md`, the portable machine-wide default that installs to `~/.claude/CLAUDE.md`.

## Working here

- Read `README.md` before editing.
- Keep each change small and reviewable.
- Never run `git commit` yourself. Stage your changes, summarize them, and hand off to the human, who reviews the staged diff and commits.
- This repository is public and stays secret-free. `~/.claude/settings.json` and `~/.claude.json` are machine-local and never copied, templated, or committed here.

## GitHub Actions

<rule id="couimet-actions-main" priority="critical">
  <title>couimet/* GitHub Actions always use @main</title>
  <never>Pin a `couimet/*` GitHub Action to a commit SHA in workflows or composite action definitions</never>
  <do>Always reference `couimet/*` actions with `@main` to get the latest version</do>
  <rationale>The author wants these actions to auto-update across all repos</rationale>
</rule>

`@main` is the intended rolling release channel for first-party actions. We control the repo, so breaking changes are intentional and versioned. SHAs add pin-update churn with no benefit for actions we own.
