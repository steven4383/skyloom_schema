import '../utils/json_value_utils.dart';

/// Built-in visual-hint names understood by the Material renderers.
abstract final class FormUiHint {
  static const String radioDirection = 'radioDirection';
  static const String multiSelect = 'multiSelect';
}

/// JSON-safe direction values used by [FormUiHint.radioDirection].
abstract final class FormUiDirection {
  static const String row = 'row';
  static const String column = 'column';
}

/// Responsive twelve-column span configuration for one field.
final class ResponsiveLayoutSchema {
  const ResponsiveLayoutSchema({
    this.mobile = 12,
    this.tablet = 12,
    this.desktop = 12,
  });

  final int mobile;
  final int tablet;
  final int desktop;

  Map<String, Object?> toJson() => {
    if (mobile != 12) 'mobile': mobile,
    if (tablet != 12) 'tablet': tablet,
    if (desktop != 12) 'desktop': desktop,
  };
}

/// Renderer and layout metadata kept separate from a field's data schema.
final class FieldUiSchema {
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

  final String? widget;
  final ResponsiveLayoutSchema layout;
  final int? order;
  final String? group;
  final Map<String, Object?> visualHints;

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
