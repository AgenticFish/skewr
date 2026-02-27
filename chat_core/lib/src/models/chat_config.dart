import 'package:equatable/equatable.dart';

const _defaultBaseUrl = 'https://api.portkey.ai/v1';
const _defaultMaxTokens = 1024;

class ChatConfig extends Equatable {
  const ChatConfig({
    required this.apiKey,
    required this.model,
    this.baseUrl = _defaultBaseUrl,
    this.maxTokens = _defaultMaxTokens,
  });

  final String apiKey;
  final String model;
  final String baseUrl;
  final int maxTokens;

  @override
  List<Object?> get props => [apiKey, model, baseUrl, maxTokens];
}
