import 'dart:io';

import 'package:skewr_cli/skewr_cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('skewr_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  String createPropertiesFile(String content) {
    final file = File('${tempDir.path}/local.properties');
    file.writeAsStringSync(content);
    return file.path;
  }

  group('ConfigLoader', () {
    test('loads from CLI args', () {
      final config = ConfigLoader.load(
        args: ['--api-key', 'cli-key', '--model', 'cli-model'],
        propertiesPath: 'nonexistent',
        environment: {},
      );
      expect(config.apiKey, 'cli-key');
      expect(config.model, 'cli-model');
    });

    test('loads from local.properties', () {
      final path = createPropertiesFile(
        'portkey-api-key=file-key\nportkey-model=file-model\n',
      );
      final config = ConfigLoader.load(
        args: [],
        propertiesPath: path,
        environment: {},
      );
      expect(config.apiKey, 'file-key');
      expect(config.model, 'file-model');
    });

    test('loads from environment variables', () {
      final config = ConfigLoader.load(
        args: [],
        propertiesPath: 'nonexistent',
        environment: {
          'PORTKEY_API_KEY': 'env-key',
          'PORTKEY_MODEL': 'env-model',
        },
      );
      expect(config.apiKey, 'env-key');
      expect(config.model, 'env-model');
    });

    test('CLI args override local.properties', () {
      final path = createPropertiesFile(
        'portkey-api-key=file-key\nportkey-model=file-model\n',
      );
      final config = ConfigLoader.load(
        args: ['--model', 'cli-model'],
        propertiesPath: path,
        environment: {},
      );
      expect(config.apiKey, 'file-key');
      expect(config.model, 'cli-model');
    });

    test('local.properties overrides environment variables', () {
      final path = createPropertiesFile(
        'portkey-api-key=file-key\nportkey-model=file-model\n',
      );
      final config = ConfigLoader.load(
        args: [],
        propertiesPath: path,
        environment: {
          'PORTKEY_API_KEY': 'env-key',
          'PORTKEY_MODEL': 'env-model',
        },
      );
      expect(config.apiKey, 'file-key');
      expect(config.model, 'file-model');
    });

    test('uses default values for optional fields', () {
      final config = ConfigLoader.load(
        args: ['--api-key', 'key', '--model', 'model'],
        propertiesPath: 'nonexistent',
        environment: {},
      );
      expect(config.baseUrl, 'https://api.portkey.ai');
      expect(config.maxTokens, 1024);
    });

    test('throws ConfigException when api-key is missing', () {
      expect(
        () => ConfigLoader.load(
          args: ['--model', 'model'],
          propertiesPath: 'nonexistent',
          environment: {},
        ),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('portkey-api-key'),
          ),
        ),
      );
    });

    test('throws ConfigException when model is missing', () {
      expect(
        () => ConfigLoader.load(
          args: ['--api-key', 'key'],
          propertiesPath: 'nonexistent',
          environment: {},
        ),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains('portkey-model'),
          ),
        ),
      );
    });

    test('skips comments and blank lines in properties file', () {
      final path = createPropertiesFile(
        '# comment\n\nportkey-api-key=key\n# another\nportkey-model=model\n',
      );
      final config = ConfigLoader.load(
        args: [],
        propertiesPath: path,
        environment: {},
      );
      expect(config.apiKey, 'key');
      expect(config.model, 'model');
    });

    test('loads all optional fields from properties file', () {
      final path = createPropertiesFile(
        'portkey-api-key=key\n'
        'portkey-model=model\n'
        'portkey-base-url=https://custom.api.com\n'
        'portkey-max-tokens=2048\n',
      );
      final config = ConfigLoader.load(
        args: [],
        propertiesPath: path,
        environment: {},
      );
      expect(config.baseUrl, 'https://custom.api.com');
      expect(config.maxTokens, 2048);
    });
  });
}
