import 'package:chat_core/chat_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockChatService extends Mock implements ChatService {}

class FakeTool implements Tool {
  FakeTool({required this.name, this.result = 'ok'});

  @override
  final String name;

  @override
  String get description => '';

  @override
  Map<String, dynamic> get parameters => {};

  final String result;

  @override
  Future<String> execute(Map<String, dynamic> arguments) async => result;
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
      await agent.chat([Message.user('Use tool')]).toList();

      verify(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).called(2);
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
