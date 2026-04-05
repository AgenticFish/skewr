import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import 'chat_bloc_event.dart';
import 'chat_state.dart';
import 'generating_status.dart';

class ChatBloc extends Bloc<ChatBlocEvent, ChatState> {
  ChatBloc(this._chatService) : super(const ChatState.initial()) {
    on<SendMessageRequested>(_onSendMessage);
    on<StopGenerationRequested>(_onStopGeneration);
  }

  final ChatService _chatService;
  StreamSubscription<ChatEvent>? _chatSubscription;

  Future<void> _onSendMessage(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = Message.user(event.content);
    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        generatingStatus: const GeneratingStatus.thinking(),
        error: null,
        currentResponse: '',
      ),
    );

    final completer = Completer<void>();
    _chatSubscription = _chatService
        .chat(state.messages)
        .listen(
          (chatEvent) => _handleChatEvent(chatEvent, emit),
          onDone: () => _completeSubscription(completer),
          onError: (Object e) {
            emit(
              state.copyWith(
                generatingStatus: const GeneratingStatus.idle(),
                error: e.toString(),
              ),
            );
            _completeSubscription(completer);
          },
        );
    await completer.future;
  }

  void _handleChatEvent(ChatEvent chatEvent, Emitter<ChatState> emit) {
    emit(switch (chatEvent) {
      TextDelta(:final text) => state.copyWith(
        currentResponse: state.currentResponse + text,
      ),
      ToolExecuting(:final label) => state.copyWith(
        generatingStatus: GeneratingStatus.toolExecuting(label),
      ),
      ToolResult() => state.copyWith(
        generatingStatus: const GeneratingStatus.thinking(),
      ),
      Done() => state.copyWith(
        messages: [
          ...state.messages,
          Message.assistant(content: state.currentResponse),
        ],
        generatingStatus: const GeneratingStatus.idle(),
        currentResponse: '',
      ),
      ChatError(:final message) => state.copyWith(
        generatingStatus: const GeneratingStatus.idle(),
        error: message,
      ),
      ToolCallRequest() => state,
    });
  }

  void _completeSubscription(Completer<void> completer) {
    _chatSubscription = null;
    if (!completer.isCompleted) completer.complete();
  }

  void _cancelSubscription() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
  }

  void _onStopGeneration(
    StopGenerationRequested event,
    Emitter<ChatState> emit,
  ) {
    _cancelSubscription();
    if (state.isGenerating) {
      emit(
        state.copyWith(
          messages: [
            ...state.messages,
            Message.assistant(content: state.currentResponse),
          ],
          generatingStatus: const GeneratingStatus.idle(),
          currentResponse: '',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
