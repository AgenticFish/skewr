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

class ToolExecuting extends ChatEvent {
  const ToolExecuting({required this.toolName, required this.label});

  final String toolName;
  final String label;

  @override
  List<Object?> get props => [toolName, label];
}

class ToolResult extends ChatEvent {
  const ToolResult({
    required this.toolName,
    required this.label,
    this.isError = false,
  });

  final String toolName;
  final String label;
  final bool isError;

  @override
  List<Object?> get props => [toolName, label, isError];
}
