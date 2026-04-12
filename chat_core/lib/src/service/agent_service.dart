import 'dart:convert';

import '../models/chat_event.dart';
import '../models/message.dart';
import '../prompt/system_prompt.dart';
import '../tool/tool_labels.dart';
import '../tool/tool_registry.dart';
import 'chat_service.dart';

class AgentService implements ChatService {
  AgentService({
    required ChatService baseChatService,
    required ToolRegistry toolRegistry,
    this.systemPrompt = agentSystemPrompt,
    this.maxToolRounds = 5,
  }) : _baseChatService = baseChatService,
       _toolRegistry = toolRegistry;

  final ChatService _baseChatService;
  final ToolRegistry _toolRegistry;
  final String systemPrompt;
  final int maxToolRounds;

  @override
  Stream<ChatEvent> chat(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
  }) async* {
    final currentMessages = [Message.system(systemPrompt), ...messages];
    final toolDefs = _toolRegistry.toToolDefinitions();
    final tools = toolDefs.isEmpty ? null : toolDefs;

    for (var round = 0; round <= maxToolRounds; round++) {
      final events = <ChatEvent>[];

      await for (final event in _baseChatService.chat(
        currentMessages,
        tools: tools,
      )) {
        events.add(event);
        // Don't yield Done yet — we need to check for tool calls first
        if (event is! Done) yield event;
      }

      final toolCallRequests = events.whereType<ToolCallRequest>().toList();
      if (toolCallRequests.isEmpty) {
        // No tool calls — this is the final round, yield Done now
        yield const Done();
        return;
      }

      if (round == maxToolRounds) {
        yield ChatError('Max tool calling rounds ($maxToolRounds) exceeded');
        return;
      }

      final assistantToolCalls = toolCallRequests
          .map((r) => r.toolCall)
          .toList();
      currentMessages.add(Message.assistant(toolCalls: assistantToolCalls));

      for (final request in toolCallRequests) {
        final toolName = request.toolCall.function.name;
        final tool = _toolRegistry.getTool(toolName);
        if (tool == null) {
          yield ToolResult(
            toolName: toolName,
            label: ToolLabels.defaultError,
            isError: true,
          );
          currentMessages.add(
            Message.tool(
              toolCallId: request.toolCall.id,
              content: 'Error: unknown tool "$toolName"',
            ),
          );
          continue;
        }

        final labels = tool.labels;
        yield ToolExecuting(
          toolName: toolName,
          label: labels?.executingLabel ?? ToolLabels.defaultExecuting,
        );

        try {
          final arguments =
              jsonDecode(request.toolCall.function.arguments)
                  as Map<String, dynamic>;
          final result = await tool.execute(arguments);
          yield ToolResult(
            toolName: toolName,
            label: labels?.resultLabel ?? ToolLabels.defaultResult,
          );
          currentMessages.add(
            Message.tool(toolCallId: request.toolCall.id, content: result),
          );
        } on Exception catch (e) {
          yield ToolResult(
            toolName: toolName,
            label: labels?.errorLabel ?? ToolLabels.defaultError,
            isError: true,
          );
          currentMessages.add(
            Message.tool(
              toolCallId: request.toolCall.id,
              content: 'Error executing tool "$toolName": $e',
            ),
          );
        }
      }
    }
  }

  @override
  void close() => _baseChatService.close();
}
