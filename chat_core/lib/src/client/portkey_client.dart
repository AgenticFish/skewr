import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_config.dart';
import '../models/message.dart';

class PortkeyClient {
  PortkeyClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final ChatConfig config;
  final http.Client _httpClient;

  Future<Message> sendMessage(List<Message> messages) async {
    final baseUrl = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    final url = Uri.parse('$baseUrl/chat/completions');
    final body = jsonEncode({
      'model': config.model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'max_tokens': config.maxTokens,
    });

    final response = await _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-portkey-api-key': config.apiKey,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw PortkeyApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>;
    final messageJson = choices[0]['message'] as Map<String, dynamic>;
    return Message.fromJson(messageJson);
  }

  void close() {
    _httpClient.close();
  }
}

class PortkeyApiException implements Exception {
  const PortkeyApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'PortkeyApiException($statusCode): $message';
}
