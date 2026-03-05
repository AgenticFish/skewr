import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import 'chat_bloc_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatBlocEvent, ChatState> {
  ChatBloc(this._chatService) : super(const ChatState.initial()) {
    on<SendMessageRequested>(_onSendMessage);
  }

  final ChatService _chatService;

  Future<void> _onSendMessage(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = Message.user(event.content);
    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isGenerating: true,
        error: null,
        currentResponse: '',
      ),
    );

    await emit.forEach(
      _chatService.chat(state.messages),
      onData: (ChatEvent chatEvent) {
        return switch (chatEvent) {
          TextDelta(:final text) => state.copyWith(
            currentResponse: state.currentResponse + text,
          ),
          Done() => state.copyWith(
            messages: [
              ...state.messages,
              Message.assistant(content: state.currentResponse),
            ],
            isGenerating: false,
            currentResponse: '',
          ),
          ChatError(:final message) => state.copyWith(
            isGenerating: false,
            error: message,
          ),
          // Tool calls not handled yet (Milestone 3)
          ToolCallRequest() => state,
        };
      },
    );
  }
}
