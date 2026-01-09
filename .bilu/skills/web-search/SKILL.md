---
name: web-search
description: Lightweight web search + fetch using only shell tools (curl + grep/sed/awk), for when codex exec has no built-in --search.
metadata:
  short-description: Shell-only web search helpers
---

# Web Search (shell-only)

## Goal

Enable the agent to quickly find and cite external references from the terminal when `codex exec` does not support a built-in `--search` flag.

## When to use

Use this skill when:
- the user asks you to “search the web”, “find references”, “look for cool implementations”, or “check docs online”
- the agent needs a small number of authoritative links to proceed (standards, manpages, repos, issues, docs)

Do not use it when local repo search (`rg`) is sufficient.

## Constraints

- Uses only shell tools (`sh`, `curl`, `awk`, `sed`, `grep`).
- Requires network access from the environment; if blocked, fail gracefully and say so.
- Keep result sets small (default 5–10).

## Workflow

1) Search for candidate links:
- `sh .bilu/skills/web-search/scripts/web-search.sh "<query>"`

2) Fetch a small excerpt for context (optional):
- `sh .bilu/skills/web-search/scripts/web-fetch.sh "<url>"`

3) Prefer high-signal sources:
- official docs / specs
- upstream repos (README, docs, issues)
- no-color.org, ShellCheck wiki, shfmt docs, etc. (for shell guidance)

## Scripts

- `scripts/web-search.sh`: queries DuckDuckGo Lite and prints a list of URLs (and optionally titles).
- `scripts/web-fetch.sh`: downloads a URL and prints a trimmed, text-only excerpt (best-effort).

## Examples

- `sh .bilu/skills/web-search/scripts/web-search.sh "bash tui fff stty read -rsn1 arrow keys"`
- `sh .bilu/skills/web-search/scripts/web-search.sh "NO_COLOR standard" --n 5`
- `sh .bilu/skills/web-search/scripts/web-fetch.sh "https://no-color.org/"`
