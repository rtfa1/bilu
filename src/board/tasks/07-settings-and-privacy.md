# Title
Settings UI and privacy messaging

# Description
Add a simple settings view for entering the API key and explain privacy practices clearly to users. This should include opt-in language for AI calls.

# Implementation Plan
1. Create a settings page or popup for key entry and basic toggles.
2. Store the key in `chrome.storage.local` and confirm success to the user.
3. Add plain-language privacy copy and usage warnings.
4. Add a “clear key” action and reset flow.

# Priority
Medium

# Status
Done

# Details
- Replaced the popup with API key entry, save/clear actions, and status messaging.
- Added privacy copy explaining local key storage and opt-in AI requests.

# depends_on
- docs/board/tasks/01-project-scaffold-and-manifest.md
- docs/board/tasks/05-background-llm-service.md
