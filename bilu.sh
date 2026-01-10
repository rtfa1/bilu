#!/bin/bash
set -euo pipefail

# Default values
iterations=1
coder="opencode"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --max-iterations|-i)
      iterations="$2"
      shift 2
      ;;
    --coder|-c)
      coder="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--max-iterations|-i <number>] [--coder|-c <opencode|codex|claude>]"
      echo "  --max-iterations, -i: Number of iterations (default: 1)"
      echo "  --coder, -c: Coder to use (default: opencode)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage"
      exit 1
      ;;
  esac
done

# Validate iterations
if ! [[ "$iterations" =~ ^[0-9]+$ ]]; then
  echo "Error: --max-iterations must be a positive integer"
  exit 1
fi

# Validate coder
if [[ "$coder" != "opencode" && "$coder" != "codex" && "$coder" != "claude" ]]; then
  echo "Error: --coder must be one of: opencode, codex, claude"
  exit 1
fi

for ((i=1; i<=$iterations; i++)); do
  read -r -d '' PROMPT <<'EOF' || true
1. Find the first task with status TODO to work located in .bilu/board/default.js and focus solely on that task until completion.
2. Check if the tests are passing. 
3. Update the board/default.json file to reflect the current status of tasks.
4. Update the task file with the work that was done.
5. Append you progress to the storage/progress.txt file. Use this to leave notes for yourself and others working in the codebase.
6. Make a git commit with a meaningful message about the work that was done.
ONLY WORK ON ONE TASK AT A TIME.
If, while implementing a task, you find that there is a blocking issue (e.g., a dependency that needs to be resolved, or a question that needs answering), make a note of it in progress.txt and move on to the next highest priority task.
If, while working on a board, you notice the status is done for all tasks, output <board>DONE</board> and exit.
EOF

  # Start the opencode server in background
  SERVER_CMD=$(.bilu/runners/docker.sh .bilu/runners/server.json)
  echo "Starting server: $SERVER_CMD"
  eval "$SERVER_CMD" &
  SERVER_PID=$!

  # Wait for server to start
  sleep 5

  # Run the client
  CLIENT_CMD=$(.bilu/runners/docker.sh .bilu/runners/client.json)
  echo "Running client: $CLIENT_CMD"
  result=$(eval "$CLIENT_CMD")

  # Clean up server
  kill $SERVER_PID 2>/dev/null || true

  echo "$result"

  if [[ "$result" == *"<board>DONE</board>"* ]]; then
    echo "Done, exiting."
    exit 0
  fi
done


npm install -g @github/copilot