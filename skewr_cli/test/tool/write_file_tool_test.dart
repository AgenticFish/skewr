import 'dart:io';

import 'package:skewr_cli/skewr_cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('skewr_write_tool_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('WriteFileTool', () {
    final tool = WriteFileTool();

    test('has correct tool definition', () {
      expect(tool.name, 'write_file');
      expect(tool.description, contains('.md'));
      expect(tool.parameters['required'], contains('path'));
      expect(tool.parameters['required'], contains('content'));
    });

    test('has labels', () {
      expect(tool.labels.executingLabel, 'Writing file...');
      expect(tool.labels.resultLabel, 'File written');
      expect(tool.labels.errorLabel, 'File write failed');
    });

    test('writes content to a file', () async {
      final path = '${tempDir.path}/test.md';
      final result = await tool.execute({
        'path': path,
        'content': 'Hello, world!',
      });

      expect(result, contains('File saved'));
      expect(result, contains('test.md'));
      expect(File(path).readAsStringSync(), 'Hello, world!');
    });

    test('creates parent directories', () async {
      final path = '${tempDir.path}/a/b/c/summary.md';
      final result = await tool.execute({'path': path, 'content': '# Summary'});

      expect(result, contains('File saved'));
      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsStringSync(), '# Summary');
    });

    test('returns file path in success message', () async {
      final path = '${tempDir.path}/output.md';
      final result = await tool.execute({'path': path, 'content': 'test'});

      expect(result, contains('output.md'));
    });

    test('handles write error', () async {
      final result = await tool.execute({
        'path': '/nonexistent_root_dir_xyz/file.md',
        'content': 'test',
      });

      expect(result, contains('Failed to write'));
    });
  });
}
