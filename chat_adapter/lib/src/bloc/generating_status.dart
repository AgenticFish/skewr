import 'package:equatable/equatable.dart';

class GeneratingStatus extends Equatable {
  const GeneratingStatus({this.isGenerating = false, this.label});

  const GeneratingStatus.idle() : isGenerating = false, label = null;

  const GeneratingStatus.thinking()
    : isGenerating = true,
      label = 'Thinking...';

  const GeneratingStatus.toolExecuting(this.label) : isGenerating = true;

  final bool isGenerating;
  final String? label;

  @override
  List<Object?> get props => [isGenerating, label];
}
