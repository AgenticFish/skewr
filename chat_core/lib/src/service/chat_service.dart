import '../models/chat_event.dart';
import '../models/message.dart';

abstract class ChatService {
  Stream<ChatEvent> chat(List<Message> messages);

  void close();
}
