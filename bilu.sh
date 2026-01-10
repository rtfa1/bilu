#!/bin/bash
set -euo pipefail

if [ -z "${1-}" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

for ((i=1; i<=$1; i++)); do
  read -r -d '' PROMPT <<'EOF' || true
ONLY WORK ON ONE TASK AT A TIME.
1. Find the first task with status TODO to work on and focus solely on that task until completion. The board is in board/default.json.
2. Check if the tests are passing. 
3. Update the board/default.json file to reflect the current status of tasks.
4. Update the task file with the work that was done.
5. Append you progress to the storage/progress.txt file. Use this to leave notes for yourself and others working in the codebase.
6. Before committing the code in git, ensure that all tests pass and that the code is functioning as expected.
7. Commit your changes to git with a meaningful commit message that reflects the work done.
8. Update the status of the task in board/default.json to DONE.
9. Output <PROMISE>COMPLETED_TASK</PROMISE> and exit.
If, while implementing a task, you find that there is a blocking issue (e.g., a dependency that needs to be resolved, or a question that needs answering), make a note of it in progress.txt and Output <PROMISE>BLOCKED_TASK</PROMISE> and exit.
If, while working on a board, you notice the status is done for all tasks, output <PROMISE>ALL_DONE</PROMISE> and exit.
EOF

  result=$(docker run --rm \
    -e CODEX_ENV_PYTHON_VERSION=3.12 \
    -e CODEX_ENV_NODE_VERSION=22 \
    -e CODEX_ENV_RUST_VERSION=1.87.0 \
    -e CODEX_ENV_GO_VERSION=1.23.8 \
    -e CODEX_ENV_SWIFT_VERSION=6.2 \
    -e CODEX_ENV_RUBY_VERSION=3.4.4 \
    -e CODEX_ENV_PHP_VERSION=8.4 \
    -v "$(pwd):/workspace/$(basename "$PWD")" -w "/workspace/$(basename "$PWD")" \
    -v "$HOME/.gitconfig-bilu:/root/.gitconfig:ro" \
    -v "$HOME/.ssh-bilu:/root/.ssh:ro" \
    -v "$HOME/.local/share/opencode/auth.json:/.local/share/opencode/auth.json:ro" \
    -v "$(pwd)/.bilu/skills:/workspace/$(basename "$PWD")/.opencode/skill:ro" \
    --network=bridge \
    --name opencode-runner \
    --link opencode-server:opencode-server \
    ghcr.io/openai/codex-universal:latest \
    -lc 'npm install -g opencode-ai && opencode run '"$PROMPT"' --attach http://opencode-server:4096  --model opencode/grok-code')

  echo "$result"

  if [[ "$result" == *"<PROMISE>ALL_DONE</PROMISE>"* ]]; then
    echo "Done, exiting."
    exit 0
  fi
done


npm install -g @github/copilot