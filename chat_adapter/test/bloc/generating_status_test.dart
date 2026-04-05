import 'package:chat_adapter/chat_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('GeneratingStatus', () {
    test('idle', () {
      const status = GeneratingStatus.idle();
      expect(status.isGenerating, false);
      expect(status.label, isNull);
    });

    test('thinking', () {
      const status = GeneratingStatus.thinking();
      expect(status.isGenerating, true);
      expect(status.label, 'Thinking...');
    });

    test('toolExecuting', () {
      const status = GeneratingStatus.toolExecuting('Checking weather...');
      expect(status.isGenerating, true);
      expect(status.label, 'Checking weather...');
    });

    test('equality', () {
      const a = GeneratingStatus.thinking();
      const b = GeneratingStatus.thinking();
      const c = GeneratingStatus.idle();
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
