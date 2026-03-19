import 'package:equatable/equatable.dart';

sealed class ChatBlocEvent extends Equatable {
  const ChatBlocEvent();
}

class SendMessageRequested extends ChatBlocEvent {
  const SendMessageRequested(this.content);

  final String content;

  @override
  List<Object?> get props => [content];
}

class StopGenerationRequested extends ChatBlocEvent {
  const StopGenerationRequested();

  @override
  List<Object?> get props => [];
}
