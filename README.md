# claude-config

Portable, secret-free global Claude Code configuration. This repository holds one machine-wide default, `templates/claude/CLAUDE.md`. Its root `CLAUDE.md` holds the project instructions for working on this repository and is never installed.

## What lives here

The repository manages a single curated layer of your Claude Code setup: the default global `CLAUDE.md` that Claude Code reads in every project. The managed file lives in `templates/claude/`. The repository deliberately does not manage the whole `~/.claude` directory.

- `CLAUDE.md` — project instructions for working in this repository (never installed).
- `templates/claude/CLAUDE.md` — the machine-wide default operating rules, installed to `~/.claude/CLAUDE.md` (short, stable, secret-free).
- `install.sh` — links the managed file into `~/.claude/CLAUDE.md`.
- `scripts/secret-scan.sh` — blocks a commit whose staged changes look like they carry a secret.
- `bats-tests/` — the BATS tests for `install.sh` and `scripts/secret-scan.sh`.

## The no-secrets rule

Everything committed here is public and stays generic. Credentials, tokens, keys, and machine-specific settings never belong in this repository.

- `~/.claude/settings.json` and `~/.claude.json` are machine-local and are never tracked, templated, or created by this repo.
- Treat `~/.claude` as runtime state: credentials, session data, and machine-specific settings live there, never in git.
- `scripts/secret-scan.sh` guards this repository. Run `make scan` to check the tracked files, or enable the pre-commit hook to check every commit.

## Install on a new machine

Clone the repository to the directory you choose, then run the installer from inside it:

```sh
git clone https://github.com/couimet/claude-config.git path/to/claude-config
cd path/to/claude-config
./install.sh
```

Replace `path/to/claude-config` with the destination you want.

The installer creates `~/.claude/CLAUDE.md` as a symlink to `templates/claude/CLAUDE.md`. The target is a symlink, so pulling new commits in `claude-config` updates the live file with no reinstall. The installer prints one of three results: `installed`, `updated`, or `unchanged`.

The installer leaves an existing regular file or directory at the target alone. It prints a warning and installs nothing. Remove that file yourself if you want the installer to manage it.

Claude Code writes `~/.claude/settings.json` and `~/.claude.json` on the machine when you change an option or add an MCP server. This repository ships no templates for them, and the installer never creates or edits them.

## Local development

Install the tools with `mise`:

```sh
make install-prereqs
```

That target runs `mise install`, then checks that `node`, `bats`, and `shellcheck` resolve on your `PATH`. Activate `mise` in your shell first, or other installations of those tools win.

Run every gate with one command:

```sh
make check
```

`make check` runs the four gates that CI runs:

- `make lint` — markdownlint and shellcheck
- `make test` — the BATS suite in `bats-tests/`
- `make scan` — `scripts/secret-scan.sh tree`

Enable the pre-commit hook in your clone:

```sh
git config core.hooksPath .githooks
```

The hook runs `scripts/secret-scan.sh staged`. It blocks a commit whose staged changes look like they carry a secret.

The hook is a plain script in `.githooks/`, so git runs it directly. It needs no extra tool. This repository does not use the `pre-commit` framework.

## Boundaries

This repository and [couimet/my-claude-skills](https://github.com/couimet/my-claude-skills) both provide content for `~/.claude`. Both are opt-in: you choose what to install. Because their content can overlap, each repository needs a clear job. This repository owns one file: the default global `CLAUDE.md` that Claude Code reads in every project. It does not own the skills.

`my-claude-skills` owns the skill files and ships its own installer.

- `couimet/my-claude-skills` installs the skills.
- `claude-config` (this repository) installs the default global `CLAUDE.md` from `templates/claude/`.

Use this repository for the operating rules that apply to every project. Use `my-claude-skills` for the skills. Neither repository writes the files of the other, and neither one manages `~/.claude/settings.json` or `~/.claude.json`.
