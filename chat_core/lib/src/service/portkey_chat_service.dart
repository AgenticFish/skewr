import '../client/portkey_client.dart';
import '../models/chat_event.dart';
import '../models/message.dart';
import 'chat_service.dart';

class PortkeyChatService implements ChatService {
  PortkeyChatService(this._client);

  final PortkeyClient _client;

  @override
  Stream<ChatEvent> chat(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
  }) => _client.sendMessageStream(messages, tools: tools);

  @override
  void close() => _client.close();
}
