/// Logical grouping of root form fields.
final class SectionSchema {
  SectionSchema({
    required this.id,
    required List<String> fields,
    this.title,
    this.description,
    this.collapsible = false,
    this.defaultExpanded = true,
    this.order = 0,
  }) : fields = List<String>.unmodifiable(fields);

  final String id;
  final String? title;
  final String? description;
  final List<String> fields;
  final bool collapsible;
  final bool defaultExpanded;
  final int order;

  Map<String, Object?> toJson() => {
    'id': id,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    'fields': fields,
    if (collapsible) 'collapsible': true,
    if (!defaultExpanded) 'defaultExpanded': false,
    if (order != 0) 'order': order,
  };
}
