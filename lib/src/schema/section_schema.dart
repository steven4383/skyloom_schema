/// Logical grouping of root form fields.
final class SectionSchema {
  /// Creates a visual section containing the supplied root [fields].
  SectionSchema({
    required this.id,
    required List<String> fields,
    this.title,
    this.description,
    this.collapsible = false,
    this.defaultExpanded = true,
    this.order = 0,
  }) : fields = List<String>.unmodifiable(fields);

  /// Unique section identifier.
  final String id;

  /// Optional section heading.
  final String? title;

  /// Optional supporting section text.
  final String? description;

  /// Root field keys rendered inside this section.
  final List<String> fields;

  /// Whether users may collapse the section.
  final bool collapsible;

  /// Initial expansion state when [collapsible] is true.
  final bool defaultExpanded;

  /// Sort order relative to other sections.
  final int order;

  /// Converts this section to its JSON-compatible representation.
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
