import 'dart:io';

import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

/// Reads local.properties from the monorepo root.
ChatConfig? loadConfig() {
  final file = File('${Directory.current.path}/../local.properties');
  if (!file.existsSync()) return null;

  final props = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final index = trimmed.indexOf('=');
    if (index < 0) continue;
    props[trimmed.substring(0, index)] = trimmed.substring(index + 1);
  }

  final apiKey = props['portkey-api-key'];
  final model = props['portkey-model'];
  if (apiKey == null || model == null) return null;

  return ChatConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: props['portkey-base-url'] ?? 'https://api.portkey.ai',
    maxTokens: int.tryParse(props['portkey-max-tokens'] ?? '') ?? 1024,
  );
}

void main() {
  final config = loadConfig();

  group(
    'Portkey integration',
    skip: config == null ? 'no local.properties' : null,
    () {
      late PortkeyClient client;

      setUp(() {
        client = PortkeyClient(config: config!);
      });

      tearDown(() {
        client.close();
      });

      test('sendMessage returns assistant response', () async {
        final response = await client.sendMessage([
          Message.user('Say "hello" and nothing else.'),
        ]);

        print('Response: ${response.content}');
        expect(response.role, Role.assistant);
        expect(response.content, isNotNull);
        expect(response.content!.toLowerCase(), contains('hello'));
      });

      test('sendMessageStream returns text deltas', () async {
        final events = await client.sendMessageStream([
          Message.user('Say "hello" and nothing else.'),
        ]).toList();

        final textDeltas = events.whereType<TextDelta>().toList();
        final fullText = textDeltas.map((e) => e.text).join();
        print('Streamed: $fullText');

        expect(textDeltas, isNotEmpty);
        expect(fullText.toLowerCase(), contains('hello'));
        expect(events.last, isA<Done>());
      });
    },
  );

  group(
    'ChatService integration',
    skip: config == null ? 'no local.properties' : null,
    () {
      late ChatService service;

      setUp(() {
        service = PortkeyChatService(PortkeyClient(config: config!));
      });

      tearDown(() {
        service.close();
      });

      test('chat() returns streaming events', () async {
        final events = await service.chat([
          Message.user('Say "hello" and nothing else.'),
        ]).toList();

        final textDeltas = events.whereType<TextDelta>().toList();
        final fullText = textDeltas.map((e) => e.text).join();
        print('ChatService: $fullText');

        expect(textDeltas, isNotEmpty);
        expect(fullText.toLowerCase(), contains('hello'));
        expect(events.last, isA<Done>());
      });
    },
  );

  group(
    'AgentService integration',
    skip: config == null ? 'no local.properties' : null,
    () {
      late AgentService agent;

      setUp(() {
        final registry = ToolRegistry();
        registry.register(_AddTool());
        agent = AgentService(
          baseChatService: PortkeyChatService(PortkeyClient(config: config!)),
          toolRegistry: registry,
        );
      });

      tearDown(() {
        agent.close();
      });

      test('tool calling loop: LLM calls tool and uses result', () async {
        final events = await agent.chat([
          Message.user(
            'Use the add tool to calculate 3 + 7. '
            'Reply with only the number.',
          ),
        ]).toList();

        final textDeltas = events.whereType<TextDelta>().toList();
        final fullText = textDeltas.map((e) => e.text).join();
        print('AgentService: $fullText');

        expect(events.whereType<ToolCallRequest>(), isNotEmpty);
        expect(fullText, contains('10'));
      });
    },
  );
}

class _AddTool implements Tool {
  @override
  String get name => 'add';

  @override
  String get description => 'Add two numbers together';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'a': {'type': 'number', 'description': 'First number'},
      'b': {'type': 'number', 'description': 'Second number'},
    },
    'required': ['a', 'b'],
  };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final a = (arguments['a'] as num).toDouble();
    final b = (arguments['b'] as num).toDouble();
    return (a + b).toString();
  }
}
