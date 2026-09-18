import '../utils/json_value_utils.dart';

/// One ordered page in a multi-step form workflow.
final class StepSchema {
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

  final String id;
  final String? title;
  final String? description;
  final List<String> fields;
  final int order;

  /// Optional condition-engine expression controlling step visibility.
  final Object? visibleWhen;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    'fields': fields,
    if (order != 0) 'order': order,
    if (visibleWhen != null) 'visibleWhen': thawJsonValue(visibleWhen),
  };
}
