# Title
Background service worker: LLM requests and API key storage

# Description
Implement the background service worker that securely stores the API key, performs debounced LLM calls, and returns AI suggestions to the content script.

# Implementation Plan
1. Add storage helpers for saving and retrieving the API key.
2. Implement LLM request logic with rate limiting and debouncing.
3. Define request/response handling with structured errors.
4. Add a simple cache to avoid repeat calls on identical text.

# Priority
High

# Status
Done

# Details
- Added API key storage lookup, debounced queueing, rate limiting, and caching for AI suggestion requests.
- Implemented OpenAI chat-completions call with concise prompt construction and structured error responses.

# depends_on
- docs/board/tasks/01-project-scaffold-and-manifest.md
- docs/board/tasks/02-message-contracts.md
