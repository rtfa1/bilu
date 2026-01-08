# Title
Suggestion UI: underlines, popovers, and accept/dismiss actions

# Description
Build the in-page UI for local and AI suggestions, including underlines, popovers, and user actions. The UI must be lightweight and non-intrusive.

# Implementation Plan
1. Render underlines for Harper suggestions in editable fields.
2. Create a popover for suggestion details and actions.
3. Implement accept/dismiss flows and apply edits to the text.
4. Add a clear entry point for “Improve with AI” requests.

# Priority
High

# Status
Done

# Details
- Added suggestion overlay styling, underlines, and popover UI anchored to active editable fields.
- Implemented accept/dismiss flows with text replacement for inputs, textareas, and contenteditable fields.
- Wired AI rewrite requests into the popover with loading/error handling and apply support.

# depends_on
- docs/board/tasks/03-content-script-text-capture.md
- docs/board/tasks/04-harper-wasm-worker.md
- docs/board/tasks/05-background-llm-service.md
