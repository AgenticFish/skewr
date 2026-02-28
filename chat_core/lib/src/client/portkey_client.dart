import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_config.dart';
import '../models/chat_event.dart';
import '../models/message.dart';
import '../models/tool_call.dart';

class PortkeyClient {
  PortkeyClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final ChatConfig config;
  final http.Client _httpClient;

  Uri get _url {
    final baseUrl = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    return Uri.parse('$baseUrl/chat/completions');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-portkey-api-key': config.apiKey,
  };

  String _buildBody(List<Message> messages, {bool stream = false}) {
    return jsonEncode({
      'model': config.model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'max_tokens': config.maxTokens,
      if (stream) 'stream': true,
    });
  }

  Future<Message> sendMessage(List<Message> messages) async {
    final http.Response response;
    try {
      response = await _httpClient.post(
        _url,
        headers: _headers,
        body: _buildBody(messages),
      );
    } on Exception catch (e) {
      throw PortkeyApiException(statusCode: 0, message: e.toString());
    }

    if (response.statusCode != 200) {
      throw PortkeyApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>;
      if (choices.isEmpty) {
        throw PortkeyApiException(
          statusCode: response.statusCode,
          message: 'Response contains no choices',
        );
      }
      final messageJson = choices[0]['message'] as Map<String, dynamic>;
      return Message.fromJson(messageJson);
    } on PortkeyApiException {
      rethrow;
    } on Exception catch (e) {
      throw PortkeyApiException(
        statusCode: response.statusCode,
        message: 'Failed to parse response: $e',
      );
    }
  }

  Stream<ChatEvent> sendMessageStream(List<Message> messages) async* {
    final request = http.Request('POST', _url)
      ..headers.addAll(_headers)
      ..body = _buildBody(messages, stream: true);

    final http.StreamedResponse response;
    try {
      response = await _httpClient.send(request);
    } on Exception catch (e) {
      yield ChatError(e.toString());
      return;
    }

    if (response.statusCode != 200) {
      String body;
      try {
        body = await response.stream.bytesToString();
      } on Exception {
        body = 'Failed to read error response body';
      }
      yield ChatError(
        PortkeyApiException(
          statusCode: response.statusCode,
          message: body,
        ).toString(),
      );
      return;
    }

    final toolCallBuilders = <int, _ToolCallBuilder>{};

    try {
      await for (final data in _sseDataLines(response)) {
        if (data == '[DONE]') break;
        final event = _parseSseData(data, toolCallBuilders);
        if (event != null) yield event;
      }
    } on Exception catch (e) {
      yield ChatError(e.toString());
    }

    // Emit completed tool calls before Done
    for (final builder in toolCallBuilders.values) {
      yield ToolCallRequest(builder.build());
    }
    yield const Done();
  }

  Stream<String> _sseDataLines(http.StreamedResponse response) async* {
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty || !line.startsWith('data: ')) continue;
      yield line.substring(6).trim();
    }
  }

  ChatEvent? _parseSseData(
    String data,
    Map<int, _ToolCallBuilder> toolCallBuilders,
  ) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>;
      if (choices.isEmpty) return null;

      final delta = choices[0]['delta'] as Map<String, dynamic>?;
      if (delta == null) return null;

      final content = delta['content'] as String?;
      if (content != null && content.isNotEmpty) return TextDelta(content);

      _parseToolCallDelta(delta, toolCallBuilders);
      return null;
    } on FormatException {
      return null;
    }
  }

  void _parseToolCallDelta(
    Map<String, dynamic> delta,
    Map<int, _ToolCallBuilder> toolCallBuilders,
  ) {
    final toolCalls = delta['tool_calls'] as List<dynamic>?;
    if (toolCalls == null) return;

    for (final tc in toolCalls) {
      final tcMap = tc as Map<String, dynamic>;
      final index = tcMap['index'] as int;
      final builder = toolCallBuilders[index] ??= _ToolCallBuilder();

      if (tcMap.containsKey('id')) builder.id = tcMap['id'] as String;
      if (tcMap.containsKey('type')) builder.type = tcMap['type'] as String;

      final function = tcMap['function'] as Map<String, dynamic>?;
      if (function == null) return;
      if (function.containsKey('name')) {
        builder.functionName = function['name'] as String;
      }
      if (function.containsKey('arguments')) {
        builder.argumentsBuffer.write(function['arguments'] as String);
      }
    }
  }

  void close() {
    _httpClient.close();
  }
}

class _ToolCallBuilder {
  String id = '';
  String type = 'function';
  String functionName = '';
  final argumentsBuffer = StringBuffer();

  ToolCall build() => ToolCall(
    id: id,
    type: type,
    function: ToolCallFunction(
      name: functionName,
      arguments: argumentsBuffer.toString(),
    ),
  );
}

class PortkeyApiException implements Exception {
  const PortkeyApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'PortkeyApiException($statusCode): $message';
}
