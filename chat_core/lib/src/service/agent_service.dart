import 'dart:convert';

import '../models/chat_event.dart';
import '../models/message.dart';
import '../tool/tool_registry.dart';
import 'chat_service.dart';

class AgentService implements ChatService {
  AgentService({
    required ChatService baseChatService,
    required ToolRegistry toolRegistry,
    this.maxToolRounds = 5,
  }) : _baseChatService = baseChatService,
       _toolRegistry = toolRegistry;

  final ChatService _baseChatService;
  final ToolRegistry _toolRegistry;
  final int maxToolRounds;

  @override
  Stream<ChatEvent> chat(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
  }) async* {
    final currentMessages = List<Message>.from(messages);
    final toolDefs = _toolRegistry.toToolDefinitions();
    final tools = toolDefs.isEmpty ? null : toolDefs;

    for (var round = 0; round <= maxToolRounds; round++) {
      final events = <ChatEvent>[];

      await for (final event in _baseChatService.chat(
        currentMessages,
        tools: tools,
      )) {
        yield event;
        events.add(event);
      }

      final toolCallRequests = events.whereType<ToolCallRequest>().toList();
      if (toolCallRequests.isEmpty) return;

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
          currentMessages.add(
            Message.tool(
              toolCallId: request.toolCall.id,
              content: 'Error: unknown tool "$toolName"',
            ),
          );
          continue;
        }

        try {
          final arguments =
              jsonDecode(request.toolCall.function.arguments)
                  as Map<String, dynamic>;
          final result = await tool.execute(arguments);
          currentMessages.add(
            Message.tool(toolCallId: request.toolCall.id, content: result),
          );
        } on Exception catch (e) {
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
