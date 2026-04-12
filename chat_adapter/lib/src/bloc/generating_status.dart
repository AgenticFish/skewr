import 'package:equatable/equatable.dart';

class GeneratingStatus extends Equatable {
  const GeneratingStatus({
    this.isGenerating = false,
    this.label,
    this.isToolResult = false,
  });

  const GeneratingStatus.idle()
    : isGenerating = false,
      label = null,
      isToolResult = false;

  const GeneratingStatus.thinking()
    : isGenerating = true,
      label = 'Thinking...',
      isToolResult = false;

  const GeneratingStatus.toolExecuting(this.label)
    : isGenerating = true,
      isToolResult = false;

  const GeneratingStatus.toolResult(this.label)
    : isGenerating = true,
      isToolResult = true;

  final bool isGenerating;
  final String? label;
  final bool isToolResult;

  @override
  List<Object?> get props => [isGenerating, label, isToolResult];
}
