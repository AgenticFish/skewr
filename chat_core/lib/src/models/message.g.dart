// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  role: $enumDecode(_$RoleEnumMap, json['role']),
  content: json['content'] as String?,
  toolCalls: (json['tool_calls'] as List<dynamic>?)
      ?.map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
      .toList(),
  toolCallId: json['tool_call_id'] as String?,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'role': _$RoleEnumMap[instance.role]!,
  'content': ?instance.content,
  'tool_calls': ?instance.toolCalls?.map((e) => e.toJson()).toList(),
  'tool_call_id': ?instance.toolCallId,
};

const _$RoleEnumMap = {
  Role.system: 'system',
  Role.user: 'user',
  Role.assistant: 'assistant',
  Role.tool: 'tool',
};
