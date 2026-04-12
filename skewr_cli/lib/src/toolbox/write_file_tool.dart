import 'dart:io';

import 'package:chat_core/chat_core.dart';

class WriteFileTool extends Tool {
  @override
  ToolLabels get labels => const ToolLabels(
    executing: 'Writing file...',
    result: 'File written',
    error: 'File write failed',
  );

  @override
  String get name => 'write_file';

  @override
  String get description =>
      'Write content to a file at a given path. Creates parent directories if needed. '
      'Use this ONLY when the user explicitly asks to save, write, or export content to a file. '
      'Always use .md format. You decide the file name and content based on the request.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'File path (relative or absolute)',
      },
      'content': {
        'type': 'string',
        'description': 'Content to write to the file',
      },
    },
    'required': ['path', 'content'],
  };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final path = arguments['path'] as String;
    final content = arguments['content'] as String;

    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return 'File saved: $path';
    } on FileSystemException catch (e) {
      return 'Failed to write file "$path": ${e.message}';
    }
  }
}
