import 'package:equatable/equatable.dart';

class ToolLabels extends Equatable {
  const ToolLabels({this.executing, this.result, this.error});

  final String? executing;
  final String? result;
  final String? error;

  static const defaultExecuting = 'Loading...';
  static const defaultResult = 'Done';
  static const defaultError = 'Failed';

  String get executingLabel => executing ?? defaultExecuting;
  String get resultLabel => result ?? defaultResult;
  String get errorLabel => error ?? defaultError;

  @override
  List<Object?> get props => [executing, result, error];
}
