import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatEvent', () {
    test('TextDelta', () {
      const event = TextDelta('hello');
      expect(event.text, 'hello');
    });

    test('ToolCallRequest', () {
      const toolCall = ToolCall(
        id: 'call_1',
        type: 'function',
        function: ToolCallFunction(name: 'create_file', arguments: '{}'),
      );
      const event = ToolCallRequest(toolCall);
      expect(event.toolCall.id, 'call_1');
    });

    test('Done with usage', () {
      const usage = Usage(
        promptTokens: 10,
        completionTokens: 20,
        totalTokens: 30,
      );
      const event = Done(usage: usage);
      expect(event.usage, isNotNull);
      expect(event.usage!.totalTokens, 30);
    });

    test('Done without usage', () {
      const event = Done();
      expect(event.usage, isNull);
    });

    test('ChatError', () {
      const event = ChatError('something went wrong');
      expect(event.message, 'something went wrong');
    });

    test('equality', () {
      const a = TextDelta('hello');
      const b = TextDelta('hello');
      expect(a, equals(b));
    });

    test('exhaustive pattern matching', () {
      const ChatEvent event = TextDelta('hi');
      final result = switch (event) {
        TextDelta(:final text) => 'text: $text',
        ToolCallRequest(:final toolCall) => 'tool: ${toolCall.id}',
        Done() => 'done',
        ChatError(:final message) => 'error: $message',
      };
      expect(result, 'text: hi');
    });
  });
}
