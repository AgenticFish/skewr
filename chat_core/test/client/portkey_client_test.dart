import 'dart:convert';

import 'package:chat_core/chat_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _config = ChatConfig(
  apiKey: 'test-api-key',
  model: '@openai/gpt-4o',
  baseUrl: 'https://api.portkey.ai/v1',
  maxTokens: 512,
);

void main() {
  group('PortkeyClient', () {
    test('sendMessage sends correct request and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.portkey.ai/v1/chat/completions',
        );
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.headers['x-portkey-api-key'], 'test-api-key');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], '@openai/gpt-4o');
        expect(body['max_tokens'], 512);
        final messages = body['messages'] as List<dynamic>;
        expect(messages, hasLength(1));
        expect(messages[0]['role'], 'user');
        expect(messages[0]['content'], 'Hello');

        return http.Response(
          jsonEncode({
            'id': 'chatcmpl-123',
            'object': 'chat.completion',
            'choices': [
              {
                'index': 0,
                'message': {'role': 'assistant', 'content': 'Hi there!'},
                'finish_reason': 'stop',
              },
            ],
            'usage': {
              'prompt_tokens': 10,
              'completion_tokens': 5,
              'total_tokens': 15,
            },
          }),
          200,
        );
      });

      final client = PortkeyClient(config: _config, httpClient: mockClient);
      final response = await client.sendMessage([Message.user('Hello')]);

      expect(response.role, Role.assistant);
      expect(response.content, 'Hi there!');

      client.close();
    });

    test('sendMessage with tool calls in response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'chatcmpl-456',
            'object': 'chat.completion',
            'choices': [
              {
                'index': 0,
                'message': {
                  'role': 'assistant',
                  'tool_calls': [
                    {
                      'id': 'call_1',
                      'type': 'function',
                      'function': {
                        'name': 'create_file',
                        'arguments': '{"path": "test.txt"}',
                      },
                    },
                  ],
                },
                'finish_reason': 'tool_calls',
              },
            ],
          }),
          200,
        );
      });

      final client = PortkeyClient(config: _config, httpClient: mockClient);
      final response = await client.sendMessage([
        Message.user('Create a file'),
      ]);

      expect(response.role, Role.assistant);
      expect(response.content, isNull);
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls!.first.function.name, 'create_file');

      client.close();
    });

    test('sendMessage throws PortkeyApiException on non-200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });

      final client = PortkeyClient(config: _config, httpClient: mockClient);

      expect(
        () => client.sendMessage([Message.user('Hello')]),
        throwsA(
          isA<PortkeyApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('Unauthorized')),
        ),
      );

      client.close();
    });
  });
}
