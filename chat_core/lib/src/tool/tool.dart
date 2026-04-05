import 'tool_labels.dart';

abstract class Tool {
  String get name;
  String get description;
  Map<String, dynamic> get parameters;
  ToolLabels? get labels => null;
  Future<String> execute(Map<String, dynamic> arguments);
}
