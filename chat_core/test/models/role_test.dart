import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('Role', () {
    test('has correct values', () {
      expect(Role.system.value, 'system');
      expect(Role.user.value, 'user');
      expect(Role.assistant.value, 'assistant');
      expect(Role.tool.value, 'tool');
    });
  });
}
