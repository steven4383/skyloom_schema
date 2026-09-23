import '../utils/json_value_utils.dart';

/// One ordered page in a multi-step form workflow.
final class StepSchema {
  /// Creates one ordered workflow step containing root [fields].
  StepSchema({
    required this.id,
    required List<String> fields,
    this.title,
    this.description,
    this.order = 0,
    Object? visibleWhen,
  }) : fields = List<String>.unmodifiable(fields),
       visibleWhen = freezeJsonValue(
         visibleWhen,
         path: r'$.steps[].visibleWhen',
       );

  /// Unique workflow-step identifier.
  final String id;

  /// Optional heading displayed for this step.
  final String? title;

  /// Optional supporting step text.
  final String? description;

  /// Root field keys assigned to this step.
  final List<String> fields;

  /// Sort order relative to other steps.
  final int order;

  /// Optional condition-engine expression controlling step visibility.
  final Object? visibleWhen;

  /// Converts this step to its JSON-compatible representation.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    'fields': fields,
    if (order != 0) 'order': order,
    if (visibleWhen != null) 'visibleWhen': thawJsonValue(visibleWhen),
  };
}
