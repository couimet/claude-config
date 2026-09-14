# CLAUDE.md

Global operating rules for Claude Code on this machine. These apply in every repository unless a project's own CLAUDE.md overrides them. Keep this file short and generic: it becomes the machine-wide default, so nothing here may be machine-specific or sensitive.

## Language

Write all output in ASD-STE100 (Simplified Technical English). This rule covers every communication and every artifact:

- Chat replies, summaries, and explanations
- Code comments and docstrings
- Test names
- Commit messages, PR titles, PR descriptions, and PR replies
- Documents, tickets, and Slack messages

Rules:

- Use one meaning for each word. Do not use a word as both a noun and a verb.
- Use the active voice. Name the agent of each action.
- Use simple tenses: present, past, or future. Do not use perfect tenses.
- Write one instruction in each sentence. Keep sentences to 20 words or less.
- Start an instruction with the verb.
- Do not use idioms, metaphors, or slang.
- Use articles ("a", "the") before each noun.
- Keep technical names and technical verbs as they are. Accuracy comes first.

If a rule makes a statement wrong, keep the statement correct. Then note the exception.

## Working style

- Read the repository's CLAUDE.md and README before editing anything. Project rules layer on top of this file and win when they conflict.
- Run the project's checks (tests, lint, build) before handing off work, and keep each change small enough to review.
- Ask before acting when a task is ambiguous or the change is hard to undo.

## Commits and history

- Never run `git commit` yourself. Stage your changes, summarize them, and hand off to the human, who reviews the staged diff and commits.
- Never force-push or rewrite published history.

## Secrets and privacy

- Never write credentials, tokens, API keys, or private keys into files, prompts, or repositories.
- Never copy or summarize the contents of `~/.claude/settings.json` or `~/.claude.json`. Those files are machine-local and never belong in a repository.
- Assume a leaked secret is compromised: rotate it rather than deleting the file.
- Keep committed content generic. Machine-local state and credentials live in local files, environment variables, or a secret manager, never in git.
