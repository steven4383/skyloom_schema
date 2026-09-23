import '../utils/json_value_utils.dart';
import 'field_schema.dart';
import 'section_schema.dart';
import 'step_schema.dart';
import 'ui_schema.dart';

/// Immutable, parsed definition of a Skyloom form.
final class FormSchema {
  /// Creates an immutable form definition from typed schema models.
  FormSchema({
    required this.id,
    required List<FieldSchema> fields,
    this.schemaVersion = '1.0',
    this.title,
    this.description,
    Map<String, FieldUiSchema> uiSchema = const {},
    List<SectionSchema> sections = const [],
    List<StepSchema> steps = const [],
    Map<String, Object?> metadata = const {},
    Map<String, Object?> additionalProperties = const {},
  }) : fields = List<FieldSchema>.unmodifiable(fields),
       uiSchema = Map<String, FieldUiSchema>.unmodifiable(uiSchema),
       sections = List<SectionSchema>.unmodifiable(sections),
       steps = List<StepSchema>.unmodifiable(steps),
       metadata = _freezeMap(metadata, r'$.metadata'),
       additionalProperties = _freezeMap(additionalProperties, r'$');

  /// Stable identifier for this form definition.
  final String id;

  /// Version of the serialized schema contract.
  final String schemaVersion;

  /// Optional human-readable form title.
  final String? title;

  /// Optional supporting form description.
  final String? description;

  /// Ordered root field definitions.
  final List<FieldSchema> fields;

  /// Presentation metadata keyed by root field key.
  final Map<String, FieldUiSchema> uiSchema;

  /// Optional visual groups for root fields.
  final List<SectionSchema> sections;

  /// Optional ordered workflow steps.
  final List<StepSchema> steps;

  /// JSON-compatible application metadata.
  final Map<String, Object?> metadata;

  /// Properties preserved for forward compatibility but not interpreted yet.
  final Map<String, Object?> additionalProperties;

  /// Returns a mutable JSON-compatible copy of this definition.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ..._thawMap(additionalProperties),
      'schemaVersion': schemaVersion,
      'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'fields': fields.map((field) => field.toJson()).toList(),
      if (uiSchema.isNotEmpty)
        'uiSchema': uiSchema.map((key, value) => MapEntry(key, value.toJson())),
      if (sections.isNotEmpty)
        'sections': sections.map((section) => section.toJson()).toList(),
      if (steps.isNotEmpty)
        'steps': steps.map((step) => step.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': _thawMap(metadata),
    };
  }
}

Map<String, Object?> _freezeMap(Map<String, Object?> value, String path) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, child) => MapEntry(key, freezeJsonValue(child, path: '$path.$key')),
    ),
  );
}

Map<String, Object?> _thawMap(Map<String, Object?> value) {
  return value.map((key, child) => MapEntry(key, thawJsonValue(child)));
}
