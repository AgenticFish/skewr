import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_call.g.dart';

@JsonSerializable()
class ToolCallFunction extends Equatable {
  const ToolCallFunction({required this.name, required this.arguments});

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFunctionFromJson(json);

  final String name;
  final String arguments;

  Map<String, dynamic> toJson() => _$ToolCallFunctionToJson(this);

  @override
  List<Object?> get props => [name, arguments];
}

@JsonSerializable()
class ToolCall extends Equatable {
  const ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  final String id;
  final String type;
  final ToolCallFunction function;

  Map<String, dynamic> toJson() => _$ToolCallToJson(this);

  @override
  List<Object?> get props => [id, type, function];
}
