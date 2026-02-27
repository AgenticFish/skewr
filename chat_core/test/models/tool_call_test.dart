import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolCallFunction', () {
    test('fromJson/toJson roundtrip', () {
      final json = {'name': 'create_file', 'arguments': '{"path": "a.txt"}'};
      final function = ToolCallFunction.fromJson(json);
      expect(function.name, 'create_file');
      expect(function.arguments, '{"path": "a.txt"}');
      expect(function.toJson(), json);
    });

    test('equality', () {
      const a = ToolCallFunction(name: 'f', arguments: '{}');
      const b = ToolCallFunction(name: 'f', arguments: '{}');
      expect(a, equals(b));
    });
  });

  group('ToolCall', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'call_1',
        'type': 'function',
        'function': {'name': 'create_file', 'arguments': '{}'},
      };
      final toolCall = ToolCall.fromJson(json);
      expect(toolCall.id, 'call_1');
      expect(toolCall.type, 'function');
      expect(toolCall.function.name, 'create_file');
      expect(toolCall.toJson(), json);
    });

    test('equality', () {
      const a = ToolCall(
        id: 'call_1',
        type: 'function',
        function: ToolCallFunction(name: 'f', arguments: '{}'),
      );
      const b = ToolCall(
        id: 'call_1',
        type: 'function',
        function: ToolCallFunction(name: 'f', arguments: '{}'),
      );
      expect(a, equals(b));
    });
  });
}
