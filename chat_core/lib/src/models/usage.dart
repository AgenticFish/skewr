import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage.g.dart';

@JsonSerializable()
class Usage extends Equatable {
  const Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  Map<String, dynamic> toJson() => _$UsageToJson(this);

  @override
  List<Object?> get props => [promptTokens, completionTokens, totalTokens];
}
