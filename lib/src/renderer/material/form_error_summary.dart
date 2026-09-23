import 'package:flutter/material.dart';

import '../../controller/form_error.dart';
import '../../controller/form_controller.dart';
import '../../engine/skyloom_messages.dart';
import 'skyloom_theme.dart';

typedef SkyloomFieldLabelResolver = String Function(String fieldPath);
typedef SkyloomRevealErrorCallback = void Function(String fieldPath);

/// Material summary for field-level and form-level errors.
final class SkyloomMaterialErrorSummary extends StatelessWidget {
  const SkyloomMaterialErrorSummary({
    required this.controller,
    required this.visible,
    required this.bottomSpacing,
    required this.fieldLabel,
    required this.onReveal,
    this.messages = const EnglishSkyloomMessages(),
    super.key,
  });

  final SkyloomFormController controller;
  final bool visible;
  final double bottomSpacing;
  final SkyloomFieldLabelResolver fieldLabel;
  final SkyloomRevealErrorCallback onReveal;
  final SkyloomMessages messages;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final errors = controller.errorEntries;
        if (!visible || errors.isEmpty) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;
        final tokens = SkyloomThemeTokens.of(context);
        return Semantics(
          container: true,
          liveRegion: true,
          label: messages.errorCount(errors.length),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomSpacing),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(tokens.surfaceRadius),
                border: tokens.surfaceBorder(colors),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      messages.reviewErrors(errors.length),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final error in errors)
                      if (error.fieldKey == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error.message,
                            style: TextStyle(color: colors.onErrorContainer),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: colors.onErrorContainer,
                              padding: const EdgeInsets.only(top: 8),
                            ),
                            onPressed: () => onReveal(error.fieldKey!),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(_fieldErrorText(error)),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _fieldErrorText(SkyloomErrorEntry error) {
    final label = fieldLabel(error.fieldKey!);
    final message = error.message.trim();
    if (message.toLowerCase().startsWith(label.trim().toLowerCase())) {
      return message;
    }
    return '$label: $message';
  }
}
