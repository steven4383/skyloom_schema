import 'dart:async';

import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../engine/skyloom_messages.dart';

/// Material progress header for a schema-driven multi-step workflow.
final class SkyloomMaterialStepProgress extends StatelessWidget {
  const SkyloomMaterialStepProgress({
    required this.controller,
    required this.visible,
    required this.allowNavigation,
    required this.bottomSpacing,
    this.messages = const EnglishSkyloomMessages(),
    super.key,
  });

  final SkyloomFormController controller;
  final bool visible;
  final bool allowNavigation;
  final double bottomSpacing;
  final SkyloomMessages messages;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final step = controller.currentStep;
        final steps = controller.visibleSteps;
        if (step == null || steps.isEmpty || !visible) {
          return const SizedBox.shrink();
        }
        final index = controller.currentStepIndex;
        final label = messages.stepProgress(index + 1, steps.length);
        return Semantics(
          container: true,
          label: '$label: ${step.title ?? step.id}',
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title ?? step.id,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(label),
                  ],
                ),
                if (step.description != null) ...[
                  const SizedBox(height: 4),
                  Text(step.description!),
                ],
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (index + 1) / steps.length,
                  semanticsLabel: label,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (
                      var stepIndex = 0;
                      stepIndex < steps.length;
                      stepIndex++
                    )
                      ChoiceChip(
                        selected: stepIndex == index,
                        avatar:
                            controller.stepErrorCount(steps[stepIndex].id) > 0
                            ? Icon(
                                Icons.error_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              )
                            : controller.isStepComplete(steps[stepIndex].id)
                            ? const Icon(Icons.check, size: 18)
                            : null,
                        label: Text(
                          '${stepIndex + 1}. '
                          '${steps[stepIndex].title ?? steps[stepIndex].id}',
                        ),
                        onSelected: allowNavigation
                            ? (_) => unawaited(
                                controller.goToStep(
                                  steps[stepIndex].id,
                                  validateCurrent: stepIndex > index,
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
