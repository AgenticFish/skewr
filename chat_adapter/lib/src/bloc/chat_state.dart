import 'package:chat_core/chat_core.dart';
import 'package:equatable/equatable.dart';

import 'generating_status.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.generatingStatus = const GeneratingStatus.idle(),
    this.currentResponse = '',
    this.error,
  });

  const ChatState.initial() : this();

  final List<Message> messages;
  final GeneratingStatus generatingStatus;
  final String currentResponse;
  final String? error;

  bool get isGenerating => generatingStatus.isGenerating;

  ChatState copyWith({
    List<Message>? messages,
    GeneratingStatus? generatingStatus,
    String? currentResponse,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      generatingStatus: generatingStatus ?? this.generatingStatus,
      currentResponse: currentResponse ?? this.currentResponse,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    generatingStatus,
    currentResponse,
    error,
  ];
}
