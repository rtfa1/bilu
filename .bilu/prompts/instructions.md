# AI Assistant Instructions

## General Guidelines

1. **Familiarize Yourself with Documentation**: Before engaging with users, thoroughly read the documentation files in the `docs/` directory to understand the project's goals, architecture, and development plans.  
2. **Do Not Use `.bilu` for Product Code or Artifacts**: The `.bilu` directory is for assistant metadata only. All project code, logs, configs, and artifacts must live in the workspace root (e.g., `src/`, `docs/`, `tests/`, `examples/`) and not under `.bilu/`.  

## Working on Tasks
When working on tasks within the `.bilu/board/` directory, keep the following points in mind:  
1. **Board**: The task board is defined in `.bilu/board/default.json`, which includes metadata about the board and links to individual task files.  
2. **Task Files**: Each task file in the `.bilu/board/tasks/` directory follows a structured format, including sections for description, priority, dependencies, status, steps, details, and implementation plan. Familiarize yourself with this format to effectively manage and execute tasks.  
3. **Task Statuses**: Tasks can have various statuses such as `todo`, `in-progress`, and more. You can read all config options in the `.bilu/board/config.json` file.  
4. **Dependencies**: Some tasks may depend on the completion of other tasks. Pay attention to the `depends_on` field to understand task dependencies and plan your work accordingly.  
5. **Logging Actions**: Maintain a log of all actions taken on tasks in the `.ai/board/progress/progress.txt` file to ensure transparency and traceability of changes.  


## Files and Directories
- `instructions.md`: This file (you are reading it now) contains instructions and guidelines for the AI assistant.

- `docs/`: This directory contains documentation files related to the project.

- `storage/research`: Contains research notes and advanced implementation details.

- `./.ai/board/`: This directory is intended for tracking tasks, issues, and feature requests. 

- `./.ai/board/board.json`: This file contains metadata about the task board you are working on.

- `./.ai/board/tasks`: This directory is intended for tracking tasks, issues, and feature requests. Each file within this directory represents a specific task oand is linked in the `board.json` file. 

- `./.ai/board/tasks/archived/`: This subdirectory contains archived tasks and issues that have been completed or are no longer active.

- ./.ai/board/progress/: This subdirectory contains progress/logs of actions taken on tasks and issues, providing a history of changes and updates.

- `./.ai/board/progress/progress.txt`: This file contains a chronological progress/log of all actions taken on tasks and issues within the `./.ai/board/` directory.

