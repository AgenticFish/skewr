# CLAUDE.md

## Project Overview
skewr is an AI Agent project using a monorepo structure. It provides two frontends (Dart CLI and Flutter App) for interacting with LLMs.

## Monorepo Structure
```
skewr/
├── chat_core/       # Pure Dart package - Agent core (conversation, tool calling, event stream)
├── chat_adapter/    # Pure Dart package - BLoC state management, adapter between Core and UI
├── skewr_cli/       # Dart CLI app - Command-line UI
├── skewr_app/       # Flutter app - Graphical UI (future)
└── misc/            # Local notes/docs (gitignored)
```

Dependency direction: `skewr_cli / skewr_app → chat_adapter → chat_core` (unidirectional)

## Tech Choices
- **LLM API**: Portkey API (OpenAI-compatible format)
- **State Management**: BLoC (package:bloc)
- **Configuration**: `local.properties` (repo root, gitignored) + CLI argument overrides

## Package Conventions
- Dart SDK: `^3.0.0`
- Lints: `package:lints/recommended.yaml` + `prefer_single_quotes: true`
- Version: starts at `0.0.1`
- No unnecessary comments or blank lines
- Each package has its own CI workflow with paths filter

## Git Workflow
- **Branch naming**: MMDDNN format (e.g. `022501`, `022502`)
- **Co-Authored-By**: `Co-Authored-By: Claude Code <noreply@anthropic.com>`
- **New branch flow**: checkout main → pull → create new branch
- **PR body**: include Summary and Test plan sections

## Dev Approach
- Vertical slices, small iterations, fine-grained tasks
- Current focus: CLI. Flutter App comes later.
