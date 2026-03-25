import 'tool.dart';

class ToolRegistry {
  final _tools = <String, Tool>{};

  void register(Tool tool) {
    _tools[tool.name] = tool;
  }

  void unregister(String toolName) {
    _tools.remove(toolName);
  }

  Tool? getTool(String name) => _tools[name];

  List<Tool> get enabledTools => List.unmodifiable(_tools.values);

  List<Map<String, dynamic>> toToolDefinitions() {
    return enabledTools
        .map(
          (tool) => {
            'type': 'function',
            'function': {
              'name': tool.name,
              'description': tool.description,
              'parameters': tool.parameters,
            },
          },
        )
        .toList();
  }
}
