import 'package:chat_core/chat_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockChatService extends Mock implements ChatService {}

class FakeTool extends Tool {
  FakeTool({required this.name, this.result = 'ok', this.labels});

  @override
  final String name;

  @override
  String get description => '';

  @override
  Map<String, dynamic> get parameters => {};

  @override
  final ToolLabels? labels;

  final String result;

  @override
  Future<String> execute(Map<String, dynamic> arguments) async => result;
}

class FailingTool extends Tool {
  @override
  String get name => 'failing_tool';

  @override
  String get description => '';

  @override
  Map<String, dynamic> get parameters => {};

  @override
  Future<String> execute(Map<String, dynamic> arguments) async =>
      throw Exception('tool error');
}

void main() {
  late MockChatService mockService;
  late ToolRegistry registry;

  setUp(() {
    mockService = MockChatService();
    registry = ToolRegistry();
  });

  group('AgentService', () {
    test('forwards events when no tool calls', () async {
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([const TextDelta('Hello'), const Done()]),
      );

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      final events = await agent.chat([Message.user('Hi')]).toList();

      expect(events, hasLength(2));
      expect(events[0], isA<TextDelta>());
      expect(events[1], isA<Done>());
    });

    test('executes tool and sends result back to LLM', () async {
      registry.register(FakeTool(name: 'weather', result: 'Sunny, 25C'));

      var callCount = 0;
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return Stream.fromIterable([
            const ToolCallRequest(
              ToolCall(
                id: 'call_1',
                type: 'function',
                function: ToolCallFunction(
                  name: 'weather',
                  arguments: '{"city": "Beijing"}',
                ),
              ),
            ),
            const Done(),
          ]);
        }
        return Stream.fromIterable([
          const TextDelta('It is sunny in Beijing, 25C.'),
          const Done(),
        ]);
      });

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      final events = await agent.chat([Message.user('Weather?')]).toList();

      final executing = events.whereType<ToolExecuting>().toList();
      expect(executing, hasLength(1));
      expect(executing.first.toolName, 'weather');
      expect(executing.first.label, 'Loading...');

      final results = events.whereType<ToolResult>().toList();
      expect(results, hasLength(1));
      expect(results.first.toolName, 'weather');
      expect(results.first.label, 'Done');
      expect(results.first.isError, false);

      final textDeltas = events.whereType<TextDelta>().toList();
      expect(textDeltas.last.text, contains('sunny'));

      verify(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).called(2);
    });

    test('emits error when max rounds exceeded', () async {
      registry.register(FakeTool(name: 'loop_tool'));

      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const ToolCallRequest(
            ToolCall(
              id: 'call_1',
              type: 'function',
              function: ToolCallFunction(name: 'loop_tool', arguments: '{}'),
            ),
          ),
          const Done(),
        ]),
      );

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
        maxToolRounds: 2,
      );
      final events = await agent.chat([Message.user('Loop')]).toList();

      final errors = events.whereType<ChatError>().toList();
      expect(errors, hasLength(1));
      expect(errors.first.message, contains('Max tool calling rounds'));
    });

    test('handles unknown tool name', () async {
      var callCount = 0;
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return Stream.fromIterable([
            const ToolCallRequest(
              ToolCall(
                id: 'call_1',
                type: 'function',
                function: ToolCallFunction(
                  name: 'nonexistent',
                  arguments: '{}',
                ),
              ),
            ),
            const Done(),
          ]);
        }
        return Stream.fromIterable([
          const TextDelta('Tool not found.'),
          const Done(),
        ]);
      });

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      final events = await agent.chat([Message.user('Use tool')]).toList();

      final results = events.whereType<ToolResult>().toList();
      expect(results, hasLength(1));
      expect(results.first.isError, true);
      expect(results.first.label, 'Failed');

      verify(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).called(2);
    });

    test('yields custom labels from tool', () async {
      registry.register(
        FakeTool(
          name: 'weather',
          result: 'Sunny',
          labels: const ToolLabels(
            executing: 'Checking weather...',
            result: 'Weather retrieved',
          ),
        ),
      );

      var callCount = 0;
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return Stream.fromIterable([
            const ToolCallRequest(
              ToolCall(
                id: 'call_1',
                type: 'function',
                function: ToolCallFunction(name: 'weather', arguments: '{}'),
              ),
            ),
            const Done(),
          ]);
        }
        return Stream.fromIterable([const TextDelta('Ok'), const Done()]);
      });

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      final events = await agent.chat([Message.user('Weather')]).toList();

      final executing = events.whereType<ToolExecuting>().first;
      expect(executing.label, 'Checking weather...');

      final result = events.whereType<ToolResult>().first;
      expect(result.label, 'Weather retrieved');
    });

    test('yields error ToolResult when tool throws', () async {
      registry.register(FailingTool());

      var callCount = 0;
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return Stream.fromIterable([
            const ToolCallRequest(
              ToolCall(
                id: 'call_1',
                type: 'function',
                function: ToolCallFunction(
                  name: 'failing_tool',
                  arguments: '{}',
                ),
              ),
            ),
            const Done(),
          ]);
        }
        return Stream.fromIterable([const TextDelta('Ok'), const Done()]);
      });

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      final events = await agent.chat([Message.user('Fail')]).toList();

      final executing = events.whereType<ToolExecuting>().toList();
      expect(executing, hasLength(1));

      final results = events.whereType<ToolResult>().toList();
      expect(results, hasLength(1));
      expect(results.first.isError, true);
      expect(results.first.label, 'Failed');
    });

    test('passes tool definitions to chat service', () async {
      registry.register(FakeTool(name: 'my_tool'));

      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([const TextDelta('Hi'), const Done()]),
      );

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      await agent.chat([Message.user('Hi')]).toList();

      final captured = verify(
        () => mockService.chat(any(), tools: captureAny(named: 'tools')),
      ).captured;
      final tools = captured.first as List<Map<String, dynamic>>;
      expect(tools, hasLength(1));
      expect(tools.first['function']['name'], 'my_tool');
    });

    test('passes null tools when registry is empty', () async {
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([const TextDelta('Hi'), const Done()]),
      );

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      await agent.chat([Message.user('Hi')]).toList();

      verify(() => mockService.chat(any(), tools: null)).called(1);
    });
  });
}
