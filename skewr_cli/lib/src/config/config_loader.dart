import 'dart:io';

import 'package:args/args.dart';
import 'package:chat_core/chat_core.dart';

class ConfigLoader {
  /// Load [ChatConfig] from three sources (highest priority first):
  /// CLI args > local.properties > environment variables.
  ///
  /// [propertiesPath] overrides the default local.properties location.
  /// [environment] overrides Platform.environment (for testing).
  static ChatConfig load({
    required List<String> args,
    String? propertiesPath,
    Map<String, String>? environment,
  }) {
    final cliValues = _parseArgs(args);
    final fileValues = _readProperties(propertiesPath);
    final envValues = _readEnvironment(environment ?? Platform.environment);

    final apiKey =
        cliValues['apiKey'] ?? fileValues['apiKey'] ?? envValues['apiKey'];
    final model =
        cliValues['model'] ?? fileValues['model'] ?? envValues['model'];
    final baseUrl =
        cliValues['baseUrl'] ?? fileValues['baseUrl'] ?? envValues['baseUrl'];
    final maxTokensStr =
        cliValues['maxTokens'] ??
        fileValues['maxTokens'] ??
        envValues['maxTokens'];

    if (apiKey == null || apiKey.isEmpty) {
      throw ConfigException('Missing required config: portkey-api-key');
    }
    if (model == null || model.isEmpty) {
      throw ConfigException('Missing required config: portkey-model');
    }

    return ChatConfig(
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl ?? 'https://api.portkey.ai',
      maxTokens: int.tryParse(maxTokensStr ?? '') ?? 1024,
    );
  }

  static Map<String, String?> _parseArgs(List<String> args) {
    final parser = ArgParser()
      ..addOption('api-key')
      ..addOption('model')
      ..addOption('base-url')
      ..addOption('max-tokens');

    final results = parser.parse(args);
    return {
      'apiKey': results.option('api-key'),
      'model': results.option('model'),
      'baseUrl': results.option('base-url'),
      'maxTokens': results.option('max-tokens'),
    };
  }

  static Map<String, String?> _readProperties(String? path) {
    final filePath = path ?? _findPropertiesFile();
    if (filePath == null) return {};

    final file = File(filePath);
    if (!file.existsSync()) return {};

    final props = <String, String>{};
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final index = trimmed.indexOf('=');
      if (index < 0) continue;
      props[trimmed.substring(0, index)] = trimmed.substring(index + 1);
    }

    return {
      'apiKey': props['portkey-api-key'],
      'model': props['portkey-model'],
      'baseUrl': props['portkey-base-url'],
      'maxTokens': props['portkey-max-tokens'],
    };
  }

  static String? _findPropertiesFile() {
    var dir = Directory.current;
    while (true) {
      final file = File('${dir.path}/local.properties');
      if (file.existsSync()) return file.path;
      final parent = dir.parent;
      if (parent.path == dir.path) return null;
      dir = parent;
    }
  }

  static Map<String, String?> _readEnvironment(Map<String, String> env) {
    return {
      'apiKey': env['PORTKEY_API_KEY'],
      'model': env['PORTKEY_MODEL'],
      'baseUrl': env['PORTKEY_BASE_URL'],
      'maxTokens': env['PORTKEY_MAX_TOKENS'],
    };
  }
}

class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}
