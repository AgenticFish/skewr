import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('Message', () {
    test('system factory', () {
      final msg = Message.system('You are helpful.');
      expect(msg.role, Role.system);
      expect(msg.content, 'You are helpful.');
      expect(msg.toolCalls, isNull);
      expect(msg.toolCallId, isNull);
    });

    test('user factory', () {
      final msg = Message.user('Hello');
      expect(msg.role, Role.user);
      expect(msg.content, 'Hello');
    });

    test('assistant factory with content', () {
      final msg = Message.assistant(content: 'Hi there!');
      expect(msg.role, Role.assistant);
      expect(msg.content, 'Hi there!');
      expect(msg.toolCalls, isNull);
    });

    test('assistant factory with tool calls', () {
      const toolCall = ToolCall(
        id: 'call_1',
        type: 'function',
        function: ToolCallFunction(name: 'create_file', arguments: '{}'),
      );
      final msg = Message.assistant(toolCalls: [toolCall]);
      expect(msg.role, Role.assistant);
      expect(msg.content, isNull);
      expect(msg.toolCalls, hasLength(1));
      expect(msg.toolCalls!.first.id, 'call_1');
    });

    test('tool factory', () {
      final msg = Message.tool(toolCallId: 'call_1', content: 'done');
      expect(msg.role, Role.tool);
      expect(msg.content, 'done');
      expect(msg.toolCallId, 'call_1');
    });

    test('fromJson/toJson roundtrip for user message', () {
      final json = {'role': 'user', 'content': 'Hello'};
      final msg = Message.fromJson(json);
      expect(msg.role, Role.user);
      expect(msg.content, 'Hello');
      expect(msg.toJson(), json);
    });

    test('fromJson/toJson roundtrip for assistant message with tool calls', () {
      final inputJson = {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 'call_1',
            'type': 'function',
            'function': {'name': 'create_file', 'arguments': '{}'},
          },
        ],
      };
      final msg = Message.fromJson(inputJson);
      expect(msg.role, Role.assistant);
      expect(msg.content, isNull);
      expect(msg.toolCalls, hasLength(1));
      // toJson omits null fields (includeIfNull: false)
      final expectedJson = {
        'role': 'assistant',
        'tool_calls': [
          {
            'id': 'call_1',
            'type': 'function',
            'function': {'name': 'create_file', 'arguments': '{}'},
          },
        ],
      };
      expect(msg.toJson(), expectedJson);
    });

    test('equality', () {
      final a = Message.user('Hello');
      final b = Message.user('Hello');
      expect(a, equals(b));
    });
  });
}
