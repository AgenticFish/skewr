import 'package:chat_core/chat_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockPortkeyClient extends Mock implements PortkeyClient {}

void main() {
  late MockPortkeyClient mockClient;
  late PortkeyChatService service;

  setUp(() {
    mockClient = MockPortkeyClient();
    service = PortkeyChatService(mockClient);
  });

  group('PortkeyChatService', () {
    test('chat() delegates to PortkeyClient.sendMessageStream', () {
      final messages = [Message.user('Hello')];
      final events = Stream<ChatEvent>.fromIterable([
        const TextDelta('Hi'),
        const Done(),
      ]);

      when(
        () => mockClient.sendMessageStream(any(), tools: any(named: 'tools')),
      ).thenAnswer((_) => events);

      expect(
        service.chat(messages),
        emitsInOrder([
          isA<TextDelta>().having((e) => e.text, 'text', 'Hi'),
          isA<Done>(),
        ]),
      );

      verify(
        () => mockClient.sendMessageStream(messages, tools: null),
      ).called(1);
    });

    test('chat() passes tools to client', () {
      final messages = [Message.user('Hello')];
      final tools = [
        {
          'type': 'function',
          'function': {'name': 'test'},
        },
      ];

      when(
        () => mockClient.sendMessageStream(any(), tools: any(named: 'tools')),
      ).thenAnswer((_) => Stream.fromIterable([const Done()]));

      expect(service.chat(messages, tools: tools), emits(isA<Done>()));

      verify(
        () => mockClient.sendMessageStream(messages, tools: tools),
      ).called(1);
    });

    test('chat() forwards ChatError from client', () {
      final messages = [Message.user('Hello')];
      when(
        () => mockClient.sendMessageStream(any(), tools: any(named: 'tools')),
      ).thenAnswer(
        (_) => Stream.fromIterable([const ChatError('fail'), const Done()]),
      );

      expect(
        service.chat(messages),
        emitsInOrder([
          isA<ChatError>().having((e) => e.message, 'message', 'fail'),
          isA<Done>(),
        ]),
      );
    });

    test('close() delegates to client', () {
      when(() => mockClient.close()).thenReturn(null);

      service.close();

      verify(() => mockClient.close()).called(1);
    });

    test('implements ChatService interface', () {
      expect(service, isA<ChatService>());
    });
  });
}
