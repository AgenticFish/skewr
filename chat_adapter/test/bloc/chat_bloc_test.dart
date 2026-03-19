import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chat_adapter/chat_adapter.dart';
import 'package:chat_core/chat_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockChatService mockService;

  setUp(() {
    mockService = MockChatService();
  });

  group('ChatBloc', () {
    test('initial state', () {
      final bloc = ChatBloc(mockService);
      expect(bloc.state, const ChatState.initial());
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.isGenerating, isFalse);
      expect(bloc.state.currentResponse, isEmpty);
      expect(bloc.state.error, isNull);
      bloc.close();
    });

    blocTest<ChatBloc, ChatState>(
      'emits states for successful streaming response',
      build: () {
        when(() => mockService.chat(any())).thenAnswer(
          (_) => Stream.fromIterable([
            const TextDelta('Hello'),
            const TextDelta(' world'),
            const Done(),
          ]),
        );
        return ChatBloc(mockService);
      },
      act: (bloc) => bloc.add(const SendMessageRequested('Hi')),
      expect: () => [
        // User message added, generating starts
        ChatState(messages: [Message.user('Hi')], isGenerating: true),
        // First text delta
        ChatState(
          messages: [Message.user('Hi')],
          isGenerating: true,
          currentResponse: 'Hello',
        ),
        // Second text delta
        ChatState(
          messages: [Message.user('Hi')],
          isGenerating: true,
          currentResponse: 'Hello world',
        ),
        // Done: assistant message added, generating stops
        ChatState(
          messages: [
            Message.user('Hi'),
            Message.assistant(content: 'Hello world'),
          ],
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits error state on ChatError',
      build: () {
        when(() => mockService.chat(any())).thenAnswer(
          (_) => Stream.fromIterable([const ChatError('Something went wrong')]),
        );
        return ChatBloc(mockService);
      },
      act: (bloc) => bloc.add(const SendMessageRequested('Hi')),
      expect: () => [
        ChatState(messages: [Message.user('Hi')], isGenerating: true),
        ChatState(
          messages: [Message.user('Hi')],
          error: 'Something went wrong',
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'stops generation and keeps partial response',
      build: () {
        final controller = StreamController<ChatEvent>();
        when(
          () => mockService.chat(any()),
        ).thenAnswer((_) => controller.stream);
        // Emit some deltas then don't close (simulates ongoing stream)
        Future.microtask(() {
          controller.add(const TextDelta('Hello'));
          controller.add(const TextDelta(' wor'));
        });
        return ChatBloc(mockService);
      },
      act: (bloc) async {
        bloc.add(const SendMessageRequested('Hi'));
        // Wait for deltas to be processed
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const StopGenerationRequested());
      },
      expect: () => [
        ChatState(messages: [Message.user('Hi')], isGenerating: true),
        ChatState(
          messages: [Message.user('Hi')],
          isGenerating: true,
          currentResponse: 'Hello',
        ),
        ChatState(
          messages: [Message.user('Hi')],
          isGenerating: true,
          currentResponse: 'Hello wor',
        ),
        ChatState(
          messages: [
            Message.user('Hi'),
            Message.assistant(content: 'Hello wor'),
          ],
        ),
      ],
    );
  });
}
