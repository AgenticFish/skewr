import 'package:chat_adapter/chat_adapter.dart';
import 'package:chat_core/chat_core.dart';
import 'package:skewr_cli/skewr_cli.dart';

Future<void> main(List<String> args) async {
  final config = ConfigLoader.load(args: args);
  final client = PortkeyClient(config: config);
  final service = PortkeyChatService(client);
  final bloc = ChatBloc(service);

  final repl = ChatRepl(bloc);
  await repl.run();

  bloc.close();
  service.close();
}
