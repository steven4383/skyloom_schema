/// The visual action requested for a schema field.
enum SkyloomFieldNavigationIntent {
  /// Change steps/sections and scroll the field into view.
  reveal,

  /// Reveal the field and request input focus when supported.
  focus,
}

/// Immutable request emitted by [SkyloomFormController] navigation methods.
///
/// Renderers can observe the controller and fulfill the latest request without
/// introducing widget dependencies into the headless form engine.
final class SkyloomFieldNavigationRequest {
  const SkyloomFieldNavigationRequest({
    required this.id,
    required this.fieldPath,
    required this.intent,
  });

  final int id;
  final String fieldPath;
  final SkyloomFieldNavigationIntent intent;

  bool get requestsFocus => intent == SkyloomFieldNavigationIntent.focus;
}
