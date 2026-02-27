import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatConfig', () {
    test('required fields', () {
      const config = ChatConfig(apiKey: 'pk-xxx', model: '@openai/gpt-4o');
      expect(config.apiKey, 'pk-xxx');
      expect(config.model, '@openai/gpt-4o');
    });

    test('default values', () {
      const config = ChatConfig(apiKey: 'pk-xxx', model: '@openai/gpt-4o');
      expect(config.baseUrl, 'https://api.portkey.ai/v1');
      expect(config.maxTokens, 1024);
    });

    test('custom values override defaults', () {
      const config = ChatConfig(
        apiKey: 'pk-xxx',
        model: '@openai/gpt-4o',
        baseUrl: 'https://custom.api.com/v1',
        maxTokens: 2048,
      );
      expect(config.baseUrl, 'https://custom.api.com/v1');
      expect(config.maxTokens, 2048);
    });

    test('equality', () {
      const a = ChatConfig(apiKey: 'pk-xxx', model: '@openai/gpt-4o');
      const b = ChatConfig(apiKey: 'pk-xxx', model: '@openai/gpt-4o');
      expect(a, equals(b));
    });
  });
}
