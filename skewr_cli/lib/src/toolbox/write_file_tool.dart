import 'dart:io';

import 'package:chat_core/chat_core.dart';

class WriteFileTool implements Tool {
  @override
  String get name => 'write_file';

  @override
  String get description =>
      'Write content to a file. Creates parent directories if needed. '
      'Use this to save conversation summaries, notes, or any text content. '
      'You decide the file name and content. Always use .md format.';

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
