import 'dart:io';

import 'package:chat_adapter/chat_adapter.dart';
import 'package:chat_core/chat_core.dart';
import 'package:skewr_cli/skewr_cli.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final ChatConfig config;
  try {
    config = ConfigLoader.load(args: args);
  } on ConfigException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage();
    exit(1);
  }

  final client = PortkeyClient(config: config);
  final service = PortkeyChatService(client);
  final bloc = ChatBloc(service);

  final repl = ChatRepl(bloc);
  await repl.run();

  bloc.close();
  service.close();
}

void _printUsage() {
  stdout.writeln('Usage: dart run bin/skewr_cli.dart [options]');
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln('  --api-key      Portkey API key');
  stdout.writeln('  --model        Model ID (e.g. @openai/gpt-4o)');
  stdout.writeln(
    '  --base-url     API base URL (default: https://api.portkey.ai)',
  );
  stdout.writeln('  --max-tokens   Max tokens (default: 1024)');
  stdout.writeln('  -h, --help     Show this help');
  stdout.writeln();
  stdout.writeln('local.properties (place in project root):');
  stdout.writeln('  portkey-api-key=your-api-key');
  stdout.writeln('  portkey-model=@provider-slug/model-name');
  stdout.writeln('  portkey-base-url=https://api.portkey.ai');
  stdout.writeln('  portkey-max-tokens=1024');
  stdout.writeln();
  stdout.writeln('Environment variables:');
  stdout.writeln(
    '  PORTKEY_API_KEY, PORTKEY_MODEL, PORTKEY_BASE_URL, PORTKEY_MAX_TOKENS',
  );
  stdout.writeln();
  stdout.writeln('Priority: CLI args > local.properties > env vars.');
}
