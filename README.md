# skewr

An AI Agent project built with Dart. Interact with LLMs through a CLI or Flutter app.

## Demo

![skewr CLI demo](demo/demo-1.gif)

## Project Structure

```
skewr/
├── chat_core/       # Core library - conversation, tool calling, event stream
├── chat_adapter/    # BLoC state management, adapter between Core and UI
├── skewr_cli/       # Command-line interface
└── skewr_app/       # Flutter app (future)
```

Dependency direction: `skewr_cli / skewr_app → chat_adapter → chat_core`

## Getting Started

### Prerequisites

- Dart SDK `^3.8.0`
- A [Portkey](https://portkey.ai/) API key

### Configuration

Create a `local.properties` file in the project root:

```properties
portkey-api-key=your-api-key
portkey-model=@provider-slug/model-name
```

Optional:

```properties
portkey-base-url=https://api.portkey.ai
portkey-max-tokens=1024
```

Configuration can also be set via environment variables (`PORTKEY_API_KEY`, `PORTKEY_MODEL`, `PORTKEY_BASE_URL`, `PORTKEY_MAX_TOKENS`) or CLI arguments (`--api-key`, `--model`, `--base-url`, `--max-tokens`).

Priority: CLI arguments > `local.properties` > environment variables.

### Run the CLI

```bash
cd skewr_cli
dart pub get
dart run bin/skewr_cli.dart
```

Or with CLI arguments:

```bash
dart run bin/skewr_cli.dart --api-key your-key --model @openai/gpt-4o
```

## Development

```bash
# chat_core
cd chat_core
dart pub get
dart run build_runner build
dart test

# chat_adapter
cd chat_adapter
dart pub get
dart test

# skewr_cli
cd skewr_cli
dart pub get
dart test
```

## License

MIT
