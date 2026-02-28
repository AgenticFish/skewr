import 'dart:convert';

import 'package:chat_core/chat_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

String _sseChunk(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';
const _sseDone = 'data: [DONE]\n\n';

http.StreamedResponse _streamedResponse(String body, {int statusCode = 200}) {
  return http.StreamedResponse(Stream.value(utf8.encode(body)), statusCode);
}

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

  group('PortkeyClient.sendMessageStream', () {
    test('streams text deltas and done', () async {
      final sseBody =
          _sseChunk({
            'choices': [
              {
                'delta': {'content': 'Hello'},
                'finish_reason': null,
              },
            ],
          }) +
          _sseChunk({
            'choices': [
              {
                'delta': {'content': ' world'},
                'finish_reason': null,
              },
            ],
          }) +
          _sseChunk({
            'choices': [
              {'delta': {}, 'finish_reason': 'stop'},
            ],
          }) +
          _sseDone;

      final mockClient = MockClient.streaming((request, _) async {
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(body['stream'], true);
        return _streamedResponse(sseBody);
      });

      final client = PortkeyClient(config: _config, httpClient: mockClient);
      final events = await client.sendMessageStream([
        Message.user('Hi'),
      ]).toList();

      expect(events, hasLength(3));
      expect(events[0], isA<TextDelta>());
      expect((events[0] as TextDelta).text, 'Hello');
      expect(events[1], isA<TextDelta>());
      expect((events[1] as TextDelta).text, ' world');
      expect(events[2], isA<Done>());

      client.close();
    });

    test('streams error on non-200', () async {
      final mockClient = MockClient.streaming((request, _) async {
        return _streamedResponse('{"error": "Bad Request"}', statusCode: 400);
      });

      final client = PortkeyClient(config: _config, httpClient: mockClient);
      final events = await client.sendMessageStream([
        Message.user('Hi'),
      ]).toList();

      expect(events, hasLength(1));
      expect(events[0], isA<ChatError>());
      expect((events[0] as ChatError).message, contains('400'));

      client.close();
    });

    test('accumulates tool calls and emits on done', () async {
      final sseBody =
          _sseChunk({
            'choices': [
              {
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'id': 'call_1',
                      'type': 'function',
                      'function': {'name': 'create_file', 'arguments': ''},
                    },
                  ],
                },
                'finish_reason': null,
              },
            ],
          }) +
          _sseChunk({
            'choices': [
              {
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'function': {'arguments': '{"path":'},
                    },
                  ],
                },
                'finish_reason': null,
              },
            ],
          }) +
          _sseChunk({
            'choices': [
              {
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'function': {'arguments': ' "a.txt"}'},
                    },
                  ],
                },
                'finish_reason': null,
              },
            ],
          }) +
          _sseChunk({
            'choices': [
              {'delta': {}, 'finish_reason': 'tool_calls'},
            ],
          }) +
          _sseDone;

      final mockClient = MockClient.streaming((request, _) async {
        return _streamedResponse(sseBody);
      });

      final client = PortkeyClient(config: _config, httpClient: mockClient);
      final events = await client.sendMessageStream([
        Message.user('Make a file'),
      ]).toList();

      expect(events, hasLength(2));
      expect(events[0], isA<ToolCallRequest>());
      final toolCall = (events[0] as ToolCallRequest).toolCall;
      expect(toolCall.id, 'call_1');
      expect(toolCall.function.name, 'create_file');
      expect(toolCall.function.arguments, '{"path": "a.txt"}');
      expect(events[1], isA<Done>());

      client.close();
    });
  });
}
