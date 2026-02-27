import 'package:equatable/equatable.dart';

import 'tool_call.dart';
import 'usage.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
}

class TextDelta extends ChatEvent {
  const TextDelta(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

class ToolCallRequest extends ChatEvent {
  const ToolCallRequest(this.toolCall);

  final ToolCall toolCall;

  @override
  List<Object?> get props => [toolCall];
}

class Done extends ChatEvent {
  const Done({this.usage});

  final Usage? usage;

  @override
  List<Object?> get props => [usage];
}

class ChatError extends ChatEvent {
  const ChatError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
