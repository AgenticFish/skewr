import 'package:chat_core/chat_core.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.isGenerating = false,
    this.currentResponse = '',
    this.error,
  });

  const ChatState.initial() : this();

  final List<Message> messages;
  final bool isGenerating;
  final String currentResponse;
  final String? error;

  ChatState copyWith({
    List<Message>? messages,
    bool? isGenerating,
    String? currentResponse,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      currentResponse: currentResponse ?? this.currentResponse,
      error: error,
    );
  }

  @override
  List<Object?> get props => [messages, isGenerating, currentResponse, error];
}
