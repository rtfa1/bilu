#!/bin/bash
set -euo pipefail

if [ -z "${1-}" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# declare PROMPT variable



PROMPT="ONLY WORK ON ONE TASK AT A TIME. 
1. Find the first task in the board .bilu/board/default.json with status TODO to work on and focus solely on that task until completion.
2. Check if the tests are passing.
3. Update the task status in the board to INPROGRESS when starting work.
4. Update the task file with the work that was done.
5. Append you progress to the storage/progress.txt file. Use this to leave notes for yourself and others working in the codebase.
6. Make a git commit with a meaningful message about the work that was done.
7. Update the task status to DONE once completed.
DONT FORGET TO COMMIT YOUR CHANGES.
ONLY WORK ON ONE TASK AT A TIME.
If, while working on a task, and you need more information, look for relevant information in storage/progress.txt, other task files, board files and research files.
If, while implementing a task, you find that there is a blocking issue (e.g., a dependency that needs to be resolved, or a question that needs answering), make a note of it in progress.txt and move on to the next priority task.
If, while working on a board, you notice the status is done for all tasks, output <board>DONE</board> and exit."

for ((i=1; i<=$1; i++)); do
  result=$(docker run --rm \
    -e CODEX_ENV_PYTHON_VERSION=3.12 \
    -e CODEX_ENV_NODE_VERSION=22 \
    -e CODEX_ENV_RUST_VERSION=1.87.0 \
    -e CODEX_ENV_GO_VERSION=1.23.8 \
    -e CODEX_ENV_SWIFT_VERSION=6.2 \
    -e CODEX_ENV_RUBY_VERSION=3.4.4 \
    -e CODEX_ENV_PHP_VERSION=8.4 \
    -e PROMPT="$PROMPT" \
    -v "$(pwd):/workspace/$(basename "$PWD")" -w "/workspace/$(basename "$PWD")" \
    -v "$HOME/.gitconfig-bilu:/root/.gitconfig:ro" \
    -v "$HOME/.ssh-bilu:/root/.ssh:ro" \
    -v "$HOME/.local/share/opencode/auth.json:/.local/share/opencode/auth.json:ro" \
    -v "$(pwd)/.bilu/skills:/root/.opencode/skill:ro" \
    --network=bridge \
    ghcr.io/openai/codex-universal:latest \
    -c 'npm install -g opencode-ai && opencode run "$PROMPT" --model opencode/grok-code')

  echo "$result"

  if [[ "$result" == *"<board>DONE</board>"* ]]; then
    echo "Done, exiting."
    exit 0
  fi
done


npm install -g @github/copilot