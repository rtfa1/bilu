# Title
Content script: detect editable fields and capture text changes

# Description
Implement the content script responsible for identifying inputs/textarea/contenteditable fields, tracking user typing, and sending incremental updates into the analysis pipeline.

# Implementation Plan
1. Detect active editable elements and attach input/selection listeners.
2. Extract the current sentence or minimal context for analysis.
3. Debounce and batch updates to avoid over-sending.
4. Emit structured messages to the Harper worker and background service worker.

# Priority
High

# Status
Done

# Details
- Added focus/input/selection/composition listeners to track editable targets and typing updates.
- Added sentence-level context extraction with selection offsets for incremental analysis.
- Debounced content updates and wired messages for background plus a future Harper worker.

# depends_on
- docs/board/tasks/01-project-scaffold-and-manifest.md
- docs/board/tasks/02-message-contracts.md
