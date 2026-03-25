import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

class FakeTool implements Tool {
  FakeTool({
    required this.name,
    this.description = '',
    Map<String, dynamic>? parameters,
  }) : parameters = parameters ?? {};

  @override
  final String name;

  @override
  final String description;

  @override
  final Map<String, dynamic> parameters;

  @override
  Future<String> execute(Map<String, dynamic> arguments) async => 'result';
}

void main() {
  late ToolRegistry registry;

  setUp(() {
    registry = ToolRegistry();
  });

  group('ToolRegistry', () {
    test('register and retrieve a tool', () {
      final tool = FakeTool(name: 'test_tool');
      registry.register(tool);

      expect(registry.getTool('test_tool'), same(tool));
      expect(registry.enabledTools, hasLength(1));
    });

    test('unregister a tool', () {
      registry.register(FakeTool(name: 'test_tool'));
      registry.unregister('test_tool');

      expect(registry.getTool('test_tool'), isNull);
      expect(registry.enabledTools, isEmpty);
    });

    test('getTool returns null for unknown name', () {
      expect(registry.getTool('nonexistent'), isNull);
    });

    test('duplicate registration overwrites', () {
      final toolA = FakeTool(name: 'dup', description: 'first');
      final toolB = FakeTool(name: 'dup', description: 'second');
      registry.register(toolA);
      registry.register(toolB);

      expect(registry.getTool('dup')!.description, 'second');
      expect(registry.enabledTools, hasLength(1));
    });

    test('toToolDefinitions produces correct format', () {
      registry.register(
        FakeTool(
          name: 'weather',
          description: 'Get weather info',
          parameters: {
            'type': 'object',
            'properties': {
              'city': {'type': 'string'},
            },
            'required': ['city'],
          },
        ),
      );

      final definitions = registry.toToolDefinitions();
      expect(definitions, hasLength(1));
      expect(definitions[0], {
        'type': 'function',
        'function': {
          'name': 'weather',
          'description': 'Get weather info',
          'parameters': {
            'type': 'object',
            'properties': {
              'city': {'type': 'string'},
            },
            'required': ['city'],
          },
        },
      });
    });

    test('toToolDefinitions with multiple tools', () {
      registry.register(FakeTool(name: 'tool_a'));
      registry.register(FakeTool(name: 'tool_b'));

      final definitions = registry.toToolDefinitions();
      expect(definitions, hasLength(2));
      expect(definitions[0]['function']['name'], 'tool_a');
      expect(definitions[1]['function']['name'], 'tool_b');
    });

    test('enabledTools is unmodifiable', () {
      registry.register(FakeTool(name: 'tool'));
      final tools = registry.enabledTools;
      expect(
        () => (tools as List).add(FakeTool(name: 'hack')),
        throwsA(anything),
      );
    });
  });
}
