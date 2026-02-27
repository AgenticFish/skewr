import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'role.dart';
import 'tool_call.dart';

part 'message.g.dart';

@JsonSerializable()
class Message extends Equatable {
  const Message({
    required this.role,
    this.content,
    this.toolCalls,
    this.toolCallId,
  });

  factory Message.system(String content) =>
      Message(role: Role.system, content: content);

  factory Message.user(String content) =>
      Message(role: Role.user, content: content);

  factory Message.assistant({String? content, List<ToolCall>? toolCalls}) =>
      Message(role: Role.assistant, content: content, toolCalls: toolCalls);

  factory Message.tool({required String toolCallId, required String content}) =>
      Message(role: Role.tool, content: content, toolCallId: toolCallId);

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  final Role role;
  final String? content;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  List<Object?> get props => [role, content, toolCalls, toolCallId];
}
