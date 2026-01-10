#!/bin/bash
set -euo pipefail

docker run --rm -it \
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
  --network=bridge \
  -p 4096:4096 \
  --name opencode-server \
  ghcr.io/openai/codex-universal:latest \
  -lc 'npm install -g opencode-ai && opencode serve --hostname 0.0.0.0 --port 4096 --log-level DEBUG'