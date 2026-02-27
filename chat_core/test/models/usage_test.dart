import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('Usage', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'prompt_tokens': 10,
        'completion_tokens': 20,
        'total_tokens': 30,
      };
      final usage = Usage.fromJson(json);
      expect(usage.promptTokens, 10);
      expect(usage.completionTokens, 20);
      expect(usage.totalTokens, 30);
      expect(usage.toJson(), json);
    });

    test('equality', () {
      const a = Usage(promptTokens: 10, completionTokens: 20, totalTokens: 30);
      const b = Usage(promptTokens: 10, completionTokens: 20, totalTokens: 30);
      expect(a, equals(b));
    });
  });
}
