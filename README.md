# skewr

An AI Agent project built with Dart. Interact with LLMs through a CLI or Flutter app.

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
portkey-base-url=https://api.portkey.ai/v1
portkey-max-tokens=1024
```

Configuration can also be set via environment variables (`PORTKEY_API_KEY`, `PORTKEY_MODEL`, `PORTKEY_BASE_URL`, `PORTKEY_MAX_TOKENS`) or CLI arguments.

Priority: CLI arguments > `local.properties` > environment variables.

## Development

```bash
cd chat_core
dart pub get
dart run build_runner build
dart test
```

## License

MIT
