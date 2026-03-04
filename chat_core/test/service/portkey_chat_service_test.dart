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
        () => mockClient.sendMessageStream(messages),
      ).thenAnswer((_) => events);

      expect(
        service.chat(messages),
        emitsInOrder([
          isA<TextDelta>().having((e) => e.text, 'text', 'Hi'),
          isA<Done>(),
        ]),
      );

      verify(() => mockClient.sendMessageStream(messages)).called(1);
    });

    test('chat() forwards ChatError from client', () {
      final messages = [Message.user('Hello')];
      when(() => mockClient.sendMessageStream(messages)).thenAnswer(
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
