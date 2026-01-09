# Shell-only CLI — advanced notes + community hot takes (bilu)

This note synthesizes:
- The project’s own specs under `src/docs/` (shell-only constraint, no required deps, POSIX sh for non-interactive, bash allowed for TUI).
- Community best practices around maintainable shell CLIs (ShellCheck, shfmt, Bats, NO_COLOR) and real-world “large bash” TUIs (e.g. `fff`).

The point is not “shell is best”. It’s: **if you intentionally choose shell**, what are the techniques and guardrails that keep it fast, correct, portable, and testable.

---

## 0) The project constraints (from our docs)

Non-negotiables you already documented:
- **No required third-party deps** (explicitly: no `jq`, no `fzf`, no `gum`, no `dialog`). Coreutils/`awk`/`sed` are assumed.
- **POSIX `sh` for non-interactive** commands; **`bash` allowed for `--tui`** because key handling is much easier.
- **`tasks/*.md` is the recommended source of truth**; `default.json` can be derived via `--rebuild-index`.
- **Rendering performance:** avoid per-cell `tput`; build one buffer and print once.
- **Persistence:** temp file + atomic `mv`; add a lock (mkdir-based) for concurrent edits.
- Exit codes: `0` ok, `1` data/config failure, `2` usage error.

---

## 1) Hot take: “Shell-only” succeeds when you treat shell as an orchestrator

Community reality check (often stated bluntly):
- Shell is great at *wiring tools together*; it becomes fragile when used as a general-purpose language.

If you’re committed anyway:
- Keep core logic in **one of two forms**:
  1) POSIX sh glue + **awk as the compute engine** (fast, portable, great at TSV transforms).
  2) bash (TUI only) for stateful interaction and input decoding.

Practical rule:
- If a function starts looking like a parser or a state machine, it probably belongs in **awk** (for non-interactive) or **bash** (for the TUI).

---

## 2) JSON without `jq`: pick one of these strategies (and document it)

Your docs explicitly call out that you need a decision here.

### Strategy A (recommended): “compile” JSON at install/build time

Hot take: runtime JSON parsing in shell is a trap.

Instead:
- During `bilu init` (or `--rebuild-index`), convert JSON/MD into a **strict internal format** (TSV) that your renderer consumes.
- Treat `default.json` as derived (also aligns with your Phase 1 recommendation).

This keeps runtime simple:
- renderers read one TSV file + optional MD paths.

### Strategy B: schema-specific extraction (awk/sed) — acceptable, but brittle

This can work if:
- Your JSON schema is stable and simple.
- You only extract a few keys.

But it’s easy to break on:
- escaped quotes
- newlines
- reordered keys
- whitespace changes

If you do this, scope it:
- parse only the exact shapes you emit.

### Strategy C: allow an optional helper (`python3 -c`) if present

This is a pragmatic compromise a lot of “shell-first” projects adopt:
- If `python3` exists, use it to parse JSON safely.
- If not, fall back to “md source of truth” and/or prebuilt TSV.

This still respects “mostly shell” while avoiding writing a JSON parser.

---

## 3) TSV (internal record) is the right call — but you must define escaping rules

You already spec’d TSV as recommended.

The advanced part is not TSV itself — it’s making it **unambiguous**:
- Declare that **fields must not contain tab or newline**.
- Normalize/escape early:
  - Replace tabs/newlines in free-text fields (title/description) with spaces.
  - Keep description preview separate from full description.

Why this matters:
- Every renderer and filter becomes a fast pipeline:
  - `awk -F '\t'` + `sort` + `grep` (carefully) or awk-only.

---

## 4) CLI parsing: manual loop beats `getopts` for long options

POSIX `getopts` doesn’t natively handle long options.

Given your required behavior:
- support `--flag value` and `--flag=value`
- accept `-fv` as a single token (not `-f -v`)
- enforce paired options (`--filter` + `--filter-value`)
- support `--` end-of-options

The robust pattern (in both sh and bash):
- `while [ $# -gt 0 ]; do case "$1" in ... esac; shift; done`
- explicitly pattern-match:
  - `--filter=*)`
  - `--filter)` then consume `$2`
  - `-fv)` then consume `$2`

Hot take:
- Avoid clever parsing tricks; be boring and explicit. You want predictable exit code `2` on usage errors.

---

## 5) Error handling: the “strict mode” debate and what usually works in production

Community hot takes:
- `set -e` is frequently called a foot-gun in non-trivial scripts.
- `pipefail` is not POSIX; it’s bash/ksh/zsh.

A balanced approach for bilu:
- In POSIX sh modules, prefer:
  - explicit checks: `cmd || return 1`
  - consistent helpers: `die`, `warn`
  - avoid relying on `set -e` semantics.
- In the bash TUI, you can still avoid `set -e` and instead:
  - keep a single loop, handle failures in-line, and always `trap cleanup`.

This aligns with your acceptance criteria (usage errors are `2`, data errors are `1`).

---

## 6) Terminal UI (bash): do what the best bash TUIs do

Your docs cite patterns used by projects like `fff`:
- alternate screen buffer
- hide cursor
- disable wrap
- disable echo
- always restore via `trap` and handle `WINCH`

Advanced notes:
- Use **raw-ish input** so `read` doesn’t wait for newline. A common setup:
  - `stty -echo -icanon time 0 min 0` (exact flags vary by platform)
- Decode escape sequences like `\e[A` for arrows.
  - `fff` uses a simple approach: read 1 byte, if it’s `\e`, read 2 more.
- Framebuffer rule (your spec):
  - Build a full string with cursor positioning and redraw once per frame.

Hot take:
- Avoid `tput` in hot loops. It’s slow and spawns subshells on some systems.

---

## 7) Color: follow NO_COLOR, and add `--no-color` + auto-detection

The NO_COLOR informal standard (still actively maintained) is widely adopted:
- If `NO_COLOR` is set and non-empty, disable ANSI colors by default.

Recommended behavior for bilu:
- `--no-color` always disables.
- `--color` (if you add it later) can override NO_COLOR.
- Auto disable colors if stdout is not a TTY (`[ -t 1 ]` check).

Also keep renderer tests stable:
- tests should run with `NO_COLOR=1` or `--no-color` and verify no escape codes.

---

## 8) Portability traps (macOS vs GNU)

If you’re serious about POSIX sh portability:
- Don’t rely on GNU-isms:
  - `sed -r`, `grep -P`, `xargs -d`, etc.
- Prefer POSIX forms:
  - `sed -E` (macOS) is not POSIX; if you can avoid ERE, do.
  - Use `awk` for structured extraction.

Also:
- macOS ships an older bash by default on many systems; requiring bash 5 features (assoc arrays) can surprise users.
- Your plan to keep bash only for `--tui` helps: non-interactive should not require bash 4+.

---

## 9) Testing: no-deps is fine, but steal good ideas from Bats

Even if you don’t adopt Bats as a dependency:
- Keep tests “command-oriented” like Bats encourages:
  - run a command
  - assert exit code
  - assert stdout/stderr patterns

Your docs already recommend:
- focus tests on non-interactive behavior
- keep TUI tests manual

Advanced tip:
- For rendering tests, force a deterministic terminal width:
  - many tools honor `COLUMNS`, and you can also isolate width calculations.

---

## 10) Actionable recommendations for bilu (concrete)

If you want this project to feel “advanced shell” rather than “fragile bash”:

1) **Commit to “md is source-of-truth”** and make `--rebuild-index` the supported path.
2) Make **TSV the single internal interchange format**, with explicit escaping rules.
3) For JSON/config, prefer **build-time compilation** into shell-friendly data (or allow optional `python3`).
4) Keep non-interactive code **POSIX sh + awk**, avoid bashisms there.
5) Make the bash TUI a self-contained module with:
   - strict cleanup traps
   - raw input setup
   - `WINCH` handler
   - framebuffer rendering
6) Add a repo policy:
   - run ShellCheck + shfmt locally/CI (these are dev tools, not runtime deps).

---

## Appendix: references (high-signal)

- ShellCheck: https://www.shellcheck.net/
- ShellCheck wiki: https://github.com/koalaman/shellcheck/wiki
- shfmt (mvdan/sh): https://github.com/mvdan/sh
- NO_COLOR standard: https://no-color.org/
- Bats (testing): https://github.com/bats-core/bats-core
- `fff` (bash TUI patterns): https://github.com/dylanaraps/fff
- Google Shell Style Guide (opinions + gotchas): https://google.github.io/styleguide/shellguide.html
