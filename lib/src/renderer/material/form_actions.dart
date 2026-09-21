import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';

/// Material Back, Next, and Submit action row.
final class SkyloomMaterialFormActions extends StatelessWidget {
  const SkyloomMaterialFormActions({
    required this.controller,
    required this.visible,
    required this.canSubmit,
    required this.submitLabel,
    required this.nextLabel,
    required this.backLabel,
    required this.onSubmit,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final SkyloomFormController controller;
  final bool visible;
  final bool canSubmit;
  final String submitLabel;
  final String nextLabel;
  final String backLabel;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!visible) return const SizedBox.shrink();
        final hasSteps = controller.hasSteps;
        final showSubmit = !hasSteps || controller.isLastStep;
        if (showSubmit && !canSubmit) return const SizedBox.shrink();
        final busy = controller.submitting || controller.navigatingSteps;
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasSteps && !controller.isFirstStep)
              OutlinedButton(
                onPressed: busy ? null : onBack,
                child: Text(backLabel),
              ),
            if (hasSteps && !controller.isFirstStep) const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: FilledButton(
                onPressed: busy
                    ? null
                    : showSubmit
                    ? onSubmit
                    : onNext,
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(showSubmit ? submitLabel : nextLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}
