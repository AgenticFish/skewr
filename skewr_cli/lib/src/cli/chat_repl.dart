import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_adapter/chat_adapter.dart';

class ChatRepl {
  ChatRepl(this._bloc);

  static const _spinnerFrames = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏',
  ];

  final ChatBloc _bloc;
  bool _pendingExit = false;
  Timer? _exitTimer;
  Timer? _spinnerTimer;
  int _spinnerIndex = 0;
  String _spinnerLabel = '';

  Future<void> run() async {
    final sigintSub = _listenSigint();

    _printWelcome();

    final lines = stdin
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());
    await for (final input in _prompt(lines)) {
      if (input.trim().isEmpty) continue;

      _pendingExit = false;
      _exitTimer?.cancel();
      _bloc.add(SendMessageRequested(input));
      await _renderResponse();
    }

    _exitTimer?.cancel();
    await sigintSub.cancel();
  }

  StreamSubscription<ProcessSignal> _listenSigint() {
    return ProcessSignal.sigint.watch().listen((_) {
      if (_bloc.state.isGenerating) {
        _bloc.add(const StopGenerationRequested());
        stdout.writeln();
        stdout.writeln('[ \u270b interrupted ]');
        return;
      }
      if (_pendingExit) {
        _clearLine();
        stdout.writeln('Goodbye!');
        exit(0);
      }
      _pendingExit = true;
      _clearLine();
      stdout.writeln('Press Ctrl+C again to exit.');
      stdout.write('> ');
      _exitTimer?.cancel();
      _exitTimer = Timer(const Duration(seconds: 2), () {
        _pendingExit = false;
      });
    });
  }

  void _printWelcome() {
    stdout.writeln();
    stdout.writeln(
      '\ud83d\udd25 --|###|--|###|--|###|-- \ud83d\udd25  skewr CLI',
    );
    stdout.writeln();
    stdout.write('> ');
  }

  Stream<String> _prompt(Stream<String> lines) async* {
    await for (final line in lines) {
      yield line;
      stdout.write('> ');
    }
  }

  Future<void> _renderResponse() async {
    var previousLength = 0;
    var generationStarted = false;
    var hasTextOutput = false;

    await for (final state in _bloc.stream) {
      if (state.error != null) {
        _stopSpinner();
        stdout.writeln('\n[ \u274c Error: ${state.error} ]');
        break;
      }

      if (state.isGenerating) {
        generationStarted = true;
        final label = state.generatingStatus.label;
        if (state.currentResponse.length > previousLength) {
          if (_spinnerTimer != null) {
            _stopSpinner();
          }
          final newText = state.currentResponse.substring(previousLength);
          stdout.write(newText);
          previousLength = state.currentResponse.length;
          hasTextOutput = true;
        } else if (label != null) {
          if (hasTextOutput && _spinnerTimer == null) {
            stdout.writeln();
          }
          _updateSpinner(label);
        }
      } else if (generationStarted) {
        _stopSpinner();
        final lastContent = state.messages.lastOrNull?.content;
        if (lastContent != null && lastContent.length > previousLength) {
          stdout.write(lastContent.substring(previousLength));
        }
        stdout.writeln();
        stdout.writeln();
        break;
      }
    }
  }

  void _updateSpinner(String label) {
    if (_spinnerTimer != null && _spinnerLabel == label) return;
    _spinnerLabel = label;
    _spinnerTimer?.cancel();
    _spinnerIndex = 0;
    _spinnerTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _clearLine();
      stdout.write('${_spinnerFrames[_spinnerIndex]} $_spinnerLabel');
      _spinnerIndex = (_spinnerIndex + 1) % _spinnerFrames.length;
    });
  }

  void _stopSpinner() {
    if (_spinnerTimer == null) return;
    _spinnerTimer!.cancel();
    _spinnerTimer = null;
    _clearLine();
  }

  void _clearLine() {
    stdout.write('\x1B[2K\r');
  }
}
