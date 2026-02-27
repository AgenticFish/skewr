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
    baseUrl: props['portkey-base-url'] ?? 'https://api.portkey.ai/v1',
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
    },
  );
}
