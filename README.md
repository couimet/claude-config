# claude-config

Portable, secret-free global Claude Code configuration. This repository holds one machine-wide default, `templates/claude/CLAUDE.md`. Its root `CLAUDE.md` holds the project instructions for working on this repository and is never installed.

## What lives here

The repository manages a single curated layer of your Claude Code setup: the default global `CLAUDE.md` that Claude Code reads in every project. The managed file lives in `templates/claude/`. The repository deliberately does not manage the whole `~/.claude` directory.

- `CLAUDE.md` — project instructions for working in this repository (never installed).
- `templates/claude/CLAUDE.md` — the machine-wide default operating rules, installed to `~/.claude/CLAUDE.md` (short, stable, secret-free).

## The no-secrets rule

Everything committed here is public and stays generic. Credentials, tokens, keys, and machine-specific settings never belong in this repository.

- `~/.claude/settings.json` and `~/.claude.json` are machine-local and are never tracked, templated, or created by this repo.
- Treat `~/.claude` as runtime state: credentials, session data, and machine-specific settings live there, never in git.

## Install on a new machine

Clone the repository, then link the managed file into place:

```sh
git clone https://github.com/couimet/claude-config.git ~/src/claude-config
mkdir -p ~/.claude
ln -sfn ~/src/claude-config/templates/claude/CLAUDE.md ~/.claude/CLAUDE.md
```

The link maps `templates/claude/CLAUDE.md` to `~/.claude/CLAUDE.md`. The target is a symlink, so pulling new commits in `claude-config` updates the live file with no reinstall. The `ln -sfn` command replaces an existing symlink. If a regular file already sits at `~/.claude/CLAUDE.md`, move it aside first.

Claude Code writes `~/.claude/settings.json` and `~/.claude.json` on the machine when you change an option or add an MCP server. This repository ships no templates for them.

## Boundaries

This repository and [couimet/my-claude-skills](https://github.com/couimet/my-claude-skills) both provide content for `~/.claude`. Both are opt-in: you choose what to install. Because their content can overlap, each repository needs a clear job. This repository owns one file: the default global `CLAUDE.md` that Claude Code reads in every project. It does not own the skills.

`my-claude-skills` owns the skill files and ships its own installer.

- `couimet/my-claude-skills` installs the skills.
- `claude-config` (this repository) installs the default global `CLAUDE.md` from `templates/claude/`.

Use this repository for the operating rules that apply to every project. Use `my-claude-skills` for the skills. Neither repository writes the files of the other, and neither one manages `~/.claude/settings.json` or `~/.claude.json`.
