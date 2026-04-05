import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolLabels', () {
    test('uses default values when fields are null', () {
      const labels = ToolLabels();
      expect(labels.executingLabel, 'Loading...');
      expect(labels.resultLabel, 'Done');
      expect(labels.errorLabel, 'Failed');
    });

    test('uses custom values when provided', () {
      const labels = ToolLabels(
        executing: 'Checking weather...',
        result: 'Weather retrieved',
        error: 'Weather lookup failed',
      );
      expect(labels.executingLabel, 'Checking weather...');
      expect(labels.resultLabel, 'Weather retrieved');
      expect(labels.errorLabel, 'Weather lookup failed');
    });

    test('supports partial custom values', () {
      const labels = ToolLabels(executing: 'Working...');
      expect(labels.executingLabel, 'Working...');
      expect(labels.resultLabel, 'Done');
      expect(labels.errorLabel, 'Failed');
    });

    test('equality', () {
      const a = ToolLabels(executing: 'A');
      const b = ToolLabels(executing: 'A');
      const c = ToolLabels(executing: 'C');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
