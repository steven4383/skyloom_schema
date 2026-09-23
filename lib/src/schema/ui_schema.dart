import '../utils/json_value_utils.dart';

/// Built-in visual-hint names understood by the Material renderers.
abstract final class FormUiHint {
  /// Controls whether a radio group renders as a row or column.
  static const String radioDirection = 'radioDirection';

  /// Enables multiple selection for a chip field.
  static const String multiSelect = 'multiSelect';
}

/// JSON-safe direction values used by [FormUiHint.radioDirection].
abstract final class FormUiDirection {
  /// Horizontal radio layout.
  static const String row = 'row';

  /// Vertical radio layout.
  static const String column = 'column';
}

/// Responsive twelve-column span configuration for one field.
final class ResponsiveLayoutSchema {
  /// Creates twelve-column spans for supported viewport sizes.
  const ResponsiveLayoutSchema({
    this.mobile = 12,
    this.tablet = 12,
    this.desktop = 12,
  });

  /// Span used on narrow mobile layouts.
  final int mobile;

  /// Span used on medium tablet layouts.
  final int tablet;

  /// Span used on wide desktop layouts.
  final int desktop;

  /// Converts non-default spans to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    if (mobile != 12) 'mobile': mobile,
    if (tablet != 12) 'tablet': tablet,
    if (desktop != 12) 'desktop': desktop,
  };
}

/// Renderer and layout metadata kept separate from a field's data schema.
final class FieldUiSchema {
  /// Creates presentation metadata for one root field.
  FieldUiSchema({
    this.widget,
    this.layout = const ResponsiveLayoutSchema(),
    this.order,
    this.group,
    Map<String, Object?> visualHints = const {},
  }) : visualHints = Map<String, Object?>.unmodifiable(
         visualHints.map(
           (key, value) => MapEntry(
             key,
             freezeJsonValue(value, path: r'$.uiSchema.visualHints'),
           ),
         ),
       );

  /// Optional renderer type overriding the field's data type.
  final String? widget;

  /// Responsive grid spans used by the Material renderer.
  final ResponsiveLayoutSchema layout;

  /// Optional display order within the field's section or form.
  final int? order;

  /// Optional application-defined grouping identifier.
  final String? group;

  /// JSON-compatible renderer hints such as radio direction.
  final Map<String, Object?> visualHints;

  /// Converts this UI metadata to its JSON-compatible representation.
  Map<String, Object?> toJson() => {
    if (widget != null) 'widget': widget,
    if (layout.toJson().isNotEmpty) 'layout': layout.toJson(),
    if (order != null) 'order': order,
    if (group != null) 'group': group,
    if (visualHints.isNotEmpty)
      'visualHints': visualHints.map(
        (key, value) => MapEntry(key, thawJsonValue(value)),
      ),
  };
}
