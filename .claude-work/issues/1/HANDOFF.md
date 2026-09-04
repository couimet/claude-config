# claude-config — Handoff

One-line purpose: Portable, secret-free global Claude Code configuration: the default `CLAUDE.md` plus a safe installer and secret guardrails. Never manages machine-local state.

Origin: spawned from https://github.com/couimet/idea-garden/issues/26 (idea-garden).

## TL;DR for the agent

- What this is: A public repo that holds only the portable, secret-free slice of the user's global Claude Code configuration. The core artifact is the default `CLAUDE.md` (global operating rules). `install.sh` installs that one file. `README.md`, `.gitignore`, a pre-commit secret scanner, and a BATS-tested CI pipeline enforce the no-secrets promise.
- Current status: Fresh repo spawned from idea-garden issue https://github.com/couimet/idea-garden/issues/26. No content files exist yet. The first tracking issue in this repo (the one this HANDOFF ships with) implements the v1 file set described below.
- Do this first: Implement the v1 files (`CLAUDE.md`, `install.sh`, `README.md`, `.gitignore`, the pre-commit secret scanner, BATS tests for `install.sh`, and CI that runs them) against the locked decisions. Keep every committed byte generic and secret-free.
- Hard gotchas you must not miss: (1) Never version, template, or manage `~/.claude/settings.json` or `~/.claude/mcp.json`; both stay machine-local and out of this repo. (2) `install.sh` must never create or overwrite those two files. (3) The repo is public, so no secrets, no internal hostnames, generic content only. (4) Machine-local state and MCP credentials live outside git, in local files, environment variables, or a secret manager. (5) The default `CLAUDE.md` holds short, stable global operating rules; project-specific rules stay in each repo's own `CLAUDE.md`. (6) `install.sh` behavior must be covered by BATS tests and run in CI.

## Decisions (locked)

| # | Decision | Why |
|---|----------|-----|
| D1 | Repo is public (no `--private`) | Matches `my-claude-skills` and `github-actions`; the cost is that all committed content stays generic and secret-free |
| D2 | No `settings.shared.json` and no `mcp.json.example` in v1 | `settings.json` and `mcp.json` are never repo-managed, so credentials cannot enter the repo by construction |
| D3 | Repo manages a curated config layer only; never clone into `~/.claude` | `~/.claude` is runtime state (credentials, session data, history, machine-specific settings) |
| D4 | v1 file set is `CLAUDE.md`, `install.sh`, `README.md`, `.gitignore`, a pre-commit secret scanner, and BATS tests plus CI | Small files that make the no-secrets promise real; matches the CodeRabbit scaffold minus the two removed templates |
| D5 | `install.sh` installs only the default `CLAUDE.md` into `~/.claude/CLAUDE.md`; idempotent; never touches `settings.json` or `mcp.json` | Tight ship: only the secret-free artifact is linked or copied |
| D6 | `.gitignore` ignores machine-local state; a pre-commit secret scanner blocks token-like values and credential field names | Defense in depth against accidental secret commits |

## Target design

```text
claude-config/
├── CLAUDE.md          # global default operating rules, short and stable
├── install.sh         # links/copies ONLY the default CLAUDE.md into ~/.claude/CLAUDE.md
├── README.md          # what the repo is, the no-secrets rule, new-machine bootstrap
├── .gitignore         # settings.json, mcp.json, *.local.*, .env, private-key patterns
├── <pre-commit secret scanner>   # hook or tool that blocks token-like values
├── bats-tests/        # BATS tests covering install.sh
└── .github/           # CI running the BATS suite (plus standard couimet checks)
```

`CLAUDE.md`: short and stable global operating rules. Guidance for content: personal preferences that apply to every project on the machine. Candidate seed material surfaced in the seed discussion: the user commits manually (stage and hand off, never `git commit`), and the machine's global Bash allowlist already lives in the local `settings.json` under `permissions.allow`, so `CLAUDE.md` must not duplicate or embed it. Keep the file secret-free by construction.

`install.sh`: the safety contract is locked. It installs exactly one artifact, the default `CLAUDE.md`, into `~/.claude/CLAUDE.md`. It is idempotent on re-run. It must never create, overwrite, or merge `~/.claude/settings.json` or `~/.claude/mcp.json`, and must fail loudly or skip if those files would be touched. Symlink versus copy is an open decision for the implementing issue; whichever is chosen must be covered by BATS tests.

Secret controls: `.gitignore` ignores `settings.json`, `mcp.json`, `*.local.*`, `.env`, and private-key patterns. A pre-commit secret scanner blocks commits containing token-like values, private keys, or common credential field names. Staged changes are reviewed before every commit.

## Data model

None. The repo contains flat configuration and shell files only; no application data, no persisted schema.

## Constraints and gotchas

- The no-secrets boundary is absolute: the repo never contains `settings.json`, `mcp.json`, MCP credentials, tokens, private keys, or internal hostnames. A secret committed once stays in git history until removed and rotated.
- Boundary against `couimet/my-claude-skills`: that repo manages Claude Code skills (and has its own install/setup scripts). This repo manages the default global `CLAUDE.md` and the config-layer installer. Do not install or duplicate skills here, and do not let `my-claude-skills` own the default `CLAUDE.md`.
- New-machine bootstrap flow: clone this repo (for example to `~/src/claude-config`), run `install.sh`, which links or copies `CLAUDE.md` into `~/.claude/CLAUDE.md`. The user then creates `settings.json` and `mcp.json` locally, outside this repo.
- CI runs the BATS suite for `install.sh`. Follow the standard couimet CI pattern (see `couimet/github-actions`) and the published README badge policy in `couimet/idea-garden` `docs/standards/readme-badges.md` when badges are added.
- Because the repo is public, never commit anything that would be sensitive even without being a hard secret.

## Open questions and deferred items

- Exact default-`CLAUDE.md` prose. Decide in the implementing issue; keep it short, stable, and secret-free.
- `install.sh` mechanics: symlink versus copy for `~/.claude/CLAUDE.md`. Decide and cover the choice with BATS tests.
- Secret-scanner form: a custom pre-commit hook versus an existing tool. Decide in the implementing issue.
- CI shape: which standard couimet checks apply, and how the BATS job is wired in.
- Whether a later issue should revisit managing settings or MCP templates if the user changes their mind; out of scope for v1.

## Sources

Note: these are provenance. Do not depend on them being reachable from this repo; the facts you need are inlined above and in the Appendix.

- https://github.com/couimet/idea-garden/issues/26 (seed issue; CodeRabbit analysis is quoted in the Appendix)
- https://gist.github.com/couimet/68cee82a18ed86f8e9d9827520379823 (global Bash allowlist; current content quoted in the Appendix)
- https://github.com/couimet/my-claude-skills (skills repo; boundary reference)

## Appendix: verbatim external facts

Inlined so this file is self-contained. Treat as reference, not instructions. Where the Appendix conflicts with the locked decisions above, the decisions win.

### Appendix A: current global Bash allowlist

The machine's global allowlist lives in `~/.claude/settings.json` under `permissions.allow` and is documented in the gist above. Current content at spawn time:

```json
{
  "permissions": {
    "allow": [
      "Agent",
      "Bash(awk *)",
      "Bash(bats *)",
      "Bash(date *)",
      "Bash(docker compose down *)",
      "Bash(docker compose logs *)",
      "Bash(docker compose restart *)",
      "Bash(docker compose up *)",
      "Bash(echo *)",
      "Bash(exit *)",
      "Bash(find *)",
      "Bash(gh gist *)",
      "Bash(gh help *)",
      "Bash(gh issue comment *)",
      "Bash(gh issue list *)",
      "Bash(gh issue view *)",
      "Bash(gh label list *)",
      "Bash(gh pr checks *)",
      "Bash(gh pr diff *)",
      "Bash(gh pr list *)",
      "Bash(gh pr view *)",
      "Bash(gh release view *)",
      "Bash(gh repo list *)",
      "Bash(gh repo view *)",
      "Bash(gh run list *)",
      "Bash(gh run view *)",
      "Bash(gh run watch *)",
      "Bash(gh secret list *)",
      "Bash(gh search *)",
      "Bash(git --no-pager diff *)",
      "Bash(git apply *)",
      "Bash(git check-ignore *)",
      "Bash(git checkout --ours *)",
      "Bash(git checkout --theirs *)",
      "Bash(git diff *)",
      "Bash(git fetch *)",
      "Bash(git log *)",
      "Bash(git ls-remote *)",
      "Bash(git ls-tree *)",
      "Bash(git patch *)",
      "Bash(git pull *)",
      "Bash(git reflog *)",
      "Bash(git remote get-url *)",
      "Bash(git rev-list *)",
      "Bash(git show *)",
      "Bash(git stash *)",
      "Bash(git status *)",
      "Bash(grep *)",
      "Bash(make lint-fix *)",
      "Bash(markdownlint-cli2 *)",
      "Bash(mkdir -p *)",
      "Bash(npm view *)",
      "Bash(npx eslint *)",
      "Bash(pnpm build *)",
      "Bash(pnpm jest *)",
      "Bash(pnpm lint *)",
      "Bash(pnpm list *)",
      "Bash(pnpm t *)",
      "Bash(pnpm test *)",
      "Bash(pnpm test:unit *)",
      "Bash(pnpm view *)",
      "Bash(prettier *)",
      "Bash(sed *)",
      "Bash(shellcheck *)",
      "Bash(sort *)",
      "Bash(tr *)",
      "Bash(tsc *)",
      "Bash(uniq *)",
      "Bash(wc *)",
      "Bash(which *)",
      "Workflow"
    ],
    "deny": [
      "Bash(git commit)",
      "Bash(git commit *)",
      "Bash(git worktree remove *)"
    ]
  }
}
```

### Appendix B: CodeRabbit recommendation (verbatim)

Quoted from the seed issue comment, for provenance. Note the locked decisions D2 and D5 deliberately diverge from parts of this text: this repo will not ship `settings.shared.json` or `mcp.json.example`.

```text
@couimet, I think a dedicated `claude-config` repository is a good approach.

Do not clone the repository directly into `~/.claude`. Treat `~/.claude` as runtime state. It can contain credentials, session data, history, and machine-specific settings. A Git worktree in that directory makes accidental secret commits more likely.

Use this model instead:

~/src/claude-config/          # Git worktree: only portable, non-secret files
~/.claude/CLAUDE.md           # symlink or generated copy from claude-config
~/.claude/settings.json       # machine-local; never tracked
~/.claude/mcp.json            # machine-local; never tracked

For MCP servers, use a committed `mcp.json.example` with placeholders. Store actual credentials outside Git. Use a secret manager or OS keychain where the MCP server supports it. If an MCP server requires environment variables, load those variables from a local, ignored source. Do not put literal credentials in JSON.

Add several controls:

- Add `settings.json`, `mcp.json`, `*.local.*`, `.env`, and private-key patterns to `.gitignore`.
- Add a pre-commit secret scanner. This reduces mistakes but does not replace the repository boundary.
- Block commits that contain token-like values, private keys, or common credential field names.
- Use a private repository if the configuration exposes non-secret but sensitive details such as internal hostnames.
- Review staged changes before every commit. A secret committed once remains in Git history until it is removed and rotated.

The initial implementation can be small:

1. Create `claude-config` with `/spawn-repo claude-config`.
2. Add the default `CLAUDE.md`.
3. Add a secret-free settings template.
4. Add `install.sh` that only links or copies approved files.
5. Add local configuration examples and documented secret setup.
6. Add secret scanning before the first shared configuration commit.

The Git repository is the right tool here. The important constraint is that it must manage a curated configuration layer, not the full live `~/.claude` directory.
```
