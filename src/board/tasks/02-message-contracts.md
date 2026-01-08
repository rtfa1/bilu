# Title
Define messaging contracts between content scripts, workers, and background

# Description
Specify the message types, payload schemas, and routing between the content script, Harper WASM worker, and background service worker. This keeps the extension modular and testable.

# Implementation Plan
1. List all message flows (text input updates, Harper suggestions, AI request/response, UI actions).
2. Define message schemas and versioning in a shared module.
3. Document error and timeout behavior for each message type.
4. Add basic mock handlers to validate round-trip messaging.

# Priority
High

# Status
Done

# Details
- Added shared message contracts with versioning, schemas, and behavior metadata in `src/shared/message-contracts.js`.
- Updated content script, service worker, and popup to use the shared contracts and respond with typed ack/pong messages.
- Added mock responses for AI suggestion and debug echo messaging in the background service worker.

# depends_on
- docs/board/tasks/01-project-scaffold-and-manifest.md
