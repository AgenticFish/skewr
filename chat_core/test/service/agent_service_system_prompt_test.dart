import 'package:chat_core/chat_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockChatService mockService;
  late ToolRegistry registry;

  setUp(() {
    mockService = MockChatService();
    registry = ToolRegistry();
  });

  group('AgentService system prompt', () {
    test('prepends default system prompt', () async {
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([const TextDelta('Hi'), const Done()]),
      );

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      await agent.chat([Message.user('Hello')]).toList();

      final captured = verify(
        () => mockService.chat(captureAny(), tools: any(named: 'tools')),
      ).captured;
      final messages = captured.first as List<Message>;
      expect(messages.first.role, Role.system);
      expect(messages.first.content, agentSystemPrompt);
      expect(messages[1].role, Role.user);
      expect(messages[1].content, 'Hello');
    });

    test('prepends custom system prompt when provided', () async {
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([const TextDelta('Hi'), const Done()]),
      );

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
        systemPrompt: 'You are a CLI assistant.',
      );
      await agent.chat([Message.user('Hello')]).toList();

      final captured = verify(
        () => mockService.chat(captureAny(), tools: any(named: 'tools')),
      ).captured;
      final messages = captured.first as List<Message>;
      expect(messages.first.role, Role.system);
      expect(messages.first.content, 'You are a CLI assistant.');
    });

    test('system message comes before user messages', () async {
      when(
        () => mockService.chat(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([const TextDelta('Hi'), const Done()]),
      );

      final agent = AgentService(
        baseChatService: mockService,
        toolRegistry: registry,
      );
      final userMessages = [
        Message.user('First'),
        Message.assistant(content: 'Reply'),
        Message.user('Second'),
      ];
      await agent.chat(userMessages).toList();

      final captured = verify(
        () => mockService.chat(captureAny(), tools: any(named: 'tools')),
      ).captured;
      final messages = captured.first as List<Message>;
      expect(messages, hasLength(4));
      expect(messages[0].role, Role.system);
      expect(messages[1].content, 'First');
      expect(messages[2].content, 'Reply');
      expect(messages[3].content, 'Second');
    });
  });
}
