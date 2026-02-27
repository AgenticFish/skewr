// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCallFunction _$ToolCallFunctionFromJson(Map<String, dynamic> json) =>
    ToolCallFunction(
      name: json['name'] as String,
      arguments: json['arguments'] as String,
    );

Map<String, dynamic> _$ToolCallFunctionToJson(ToolCallFunction instance) =>
    <String, dynamic>{'name': instance.name, 'arguments': instance.arguments};

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => ToolCall(
  id: json['id'] as String,
  type: json['type'] as String,
  function: ToolCallFunction.fromJson(json['function'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ToolCallToJson(ToolCall instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'function': instance.function.toJson(),
};
