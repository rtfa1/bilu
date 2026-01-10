# Bilu

**Warning: This code is ~~vibe-coded~~ HAAD (Human Assisted AI Development)!** I'm basically building myself. Proceed with caution, or don't—let the AI handle it! 🤖

Bilu is an AI-powered automation tool for managing and executing software development tasks. It integrates with OpenCode AI to autonomously work on tasks defined in a project board, run tests, update progress, and commit changes—streamlining workflows for coding projects.

## Features

- **Task Management**: Reads tasks from a JSON board (`.bilu/board/default.json`) and focuses on one TODO task at a time.
- **Automated Execution**: Uses OpenCode AI to implement changes, check tests, and update task statuses.
- **Progress Tracking**: Logs progress in `storage/progress.txt` for collaboration and notes.
- **Git Integration**: Automatically commits meaningful changes with proper messages.
- **Docker-Based**: Runs in isolated containers with pre-configured environments (Python, Node.js, Rust, Go, Swift, Ruby, PHP).
- **Extensible**: Supports custom skills via `.bilu/skills/` and environment variables.

## Prerequisites

- Docker
- Git
- Bash (Unix-like shell)
- OpenCode authentication (configured via `~/.local/share/opencode/auth.json`)

## Installation

1. Will be something like this:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rtfa1/bilu/refs/heads/main/scripts/install.sh)"
   ```

## Usage

1. Define tasks in `.bilu/board/default.json` (example structure: tasks with `id`, `title`, `status` like "TODO", "INPROGRESS", "DONE").

2. Run the automation:
   ```bash
   ./bilu.sh <iterations>
   ```
   - `<iterations>`: Number of cycles to run (each cycle processes one task).

3. Monitor progress:
   - Check `storage/progress.txt` for notes.
   - View Git history for commits.

The tool will:
- Find the first TODO task.
- Update status to INPROGRESS.
- Run tests.
- Use AI to implement changes.
- Commit and mark as DONE.
- Repeat until all tasks are done or iterations are exhausted.

## Configuration

- **Board File**: `.bilu/board/default.json` – JSON array of tasks.
- **Skills**: `.bilu/skills/` – Custom AI skills or prompts.
- **Environment Variables**: Set versions in `bilu.sh` (e.g., `CODEX_ENV_PYTHON_VERSION`).
- **Progress Log**: `storage/progress.txt` – Append notes here.

## Testing

Run tests:
```bash
./tests/run.sh
```

Individual tests:
- `tests/board.test.sh`
- `tests/init.test.sh`
- etc.

## Contributing

1. Fork and clone.
2. Create a branch for your changes.
3. Add tests for new features.
4. Submit a pull request.

## License

License my virilha

## Troubleshooting

- **Docker Issues**: Ensure Docker is running and you have permissions.
- **Auth Errors**: Verify `auth.json` and Git configs.
- **Task Blocking**: If a task has issues, note in `progress.txt` and move to the next.
- **Logs**: Enable debug logs in the Docker command for more details.

For more info, check `storage/progress.txt` or the board file.

## Inspiration
Thanks to [@mattpocockuk](https://www.youtube.com/@mattpocockuk) for the Youtube video [https://www.youtube.com/watch?v=_IK18goX4X8](https://www.youtube.com/watch?v=_IK18goX4X8)  
and to [@geoffreyhuntley](https://x.com/geoffreyhuntley) for the article [Ralph Wiggum as a "software engineer"](https://ghuntley.com/ralph/)

