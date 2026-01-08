# Title
Harper WASM integration in a Web Worker

# Description
Integrate Harper as a WebAssembly module running in a worker for fast, local grammar checks with low latency. Expose a clean interface to the content script.

# Implementation Plan
1. Add Harper WASM artifact to the project and load it in a dedicated worker.
2. Implement initialization and readiness messaging.
3. Accept text input requests and return structured suggestions.
4. Add caching for repeated inputs to reduce redundant work.

# Priority
High

# Status
Done

# Details
- Added a Harper worker module with init/ready messaging, caching, and robust normalization of match data.
- Hooked the content script to spin up the worker and log readiness/results for future UI wiring.
- Provided a mock analyzer fallback when Harper WASM artifacts are not yet present.

# depends_on
- docs/board/tasks/01-project-scaffold-and-manifest.md
- docs/board/tasks/02-message-contracts.md
