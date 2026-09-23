import '../utils/json_value_utils.dart';
import 'async_validation_schema.dart';
import 'data_source_schema.dart';
import 'dependency_schema.dart';
import 'field_option.dart';
import 'file_upload_schema.dart';
import 'form_type.dart';
import 'validation_schema.dart';

/// Immutable definition of one form field.
final class FieldSchema {
  /// Creates an immutable field definition.
  FieldSchema({
    required this.key,
    required this.type,
    this.label,
    this.description,
    this.helperText,
    this.placeholder,
    Object? defaultValue,
    this.hasDefaultValue = false,
    this.required = false,
    this.disabled = false,
    this.readOnly = false,
    this.hidden = false,
    this.hasExplicitKey = true,
    List<FieldOption>? options,
    List<FieldSchema>? fields,
    this.items,
    this.minItems,
    this.maxItems,
    Object? defaultItem,
    this.hasDefaultItem = false,
    List<String> dependsOn = const [],
    this.dependency = const DependencySchema(),
    this.dataSource,
    this.asyncValidation,
    this.fileUpload,
    this.validation,
    Map<String, Object?> metadata = const {},
    Map<String, Object?> additionalProperties = const {},
  }) : defaultValue = freezeJsonValue(
         defaultValue,
         path: r'$.field.defaultValue',
       ),
       options = options == null
           ? null
           : List<FieldOption>.unmodifiable(options),
       fields = fields == null ? null : List<FieldSchema>.unmodifiable(fields),
       defaultItem = freezeJsonValue(defaultItem, path: r'$.field.defaultItem'),
       dependsOn = List<String>.unmodifiable(dependsOn),
       metadata = _freezeMap(metadata, r'$.field.metadata'),
       additionalProperties = _freezeMap(additionalProperties, r'$.field');

  /// Submitted-value key or nested value path for this field.
  final String key;

  /// A string rather than an enum so custom renderer types remain possible.
  final String type;

  /// Optional user-facing field label.
  final String? label;

  /// Optional longer description of the field.
  final String? description;

  /// Optional supporting text displayed near the control.
  final String? helperText;

  /// Optional prompt displayed when the control is empty.
  final String? placeholder;

  /// Immutable JSON-compatible initial value.
  final Object? defaultValue;

  /// Distinguishes an omitted default from an explicit JSON `null` default.
  final bool hasDefaultValue;

  /// Static required state before conditional rules are evaluated.
  final bool required;

  /// Static disabled state before conditional rules are evaluated.
  final bool disabled;

  /// Static read-only state before conditional rules are evaluated.
  final bool readOnly;

  /// Static hidden state before conditional rules are evaluated.
  final bool hidden;

  /// Whether [key] is emitted when this is serialized.
  final bool hasExplicitKey;

  /// Static choices for select, radio, or chip fields.
  final List<FieldOption>? options;

  /// Child definitions when [type] is [FormType.object].
  final List<FieldSchema>? fields;

  /// Item definition when [type] is [FormType.array].
  final FieldSchema? items;

  /// Minimum permitted number of array entries.
  final int? minItems;

  /// Maximum permitted number of array entries.
  final int? maxItems;

  /// JSON-compatible value used when a new array entry is added.
  final Object? defaultItem;

  /// Whether [defaultItem] was supplied, including explicit `null`.
  final bool hasDefaultItem;

  /// Field paths whose changes affect this field.
  final List<String> dependsOn;

  /// Behavior applied when a path in [dependsOn] changes.
  final DependencySchema dependency;

  /// Optional registered source for asynchronously loaded options.
  final DataSourceSchema? dataSource;

  /// Optional registered asynchronous validation configuration.
  final AsyncValidationSchema? asyncValidation;

  /// Upload behavior when [type] is [FormType.file].
  final FileUploadSchema? fileUpload;

  /// Built-in and application-defined validation rules.
  final ValidationSchema? validation;

  /// JSON-compatible application metadata.
  final Map<String, Object?> metadata;

  /// Properties preserved for forward compatibility but not interpreted yet.
  final Map<String, Object?> additionalProperties;

  /// Returns a mutable JSON-compatible copy of this field definition.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ..._thawMap(additionalProperties),
      if (hasExplicitKey) 'key': key,
      'type': type,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (helperText != null) 'helperText': helperText,
      if (placeholder != null) 'placeholder': placeholder,
      if (hasDefaultValue) 'defaultValue': thawJsonValue(defaultValue),
      if (required) 'required': true,
      if (disabled) 'disabled': true,
      if (readOnly) 'readOnly': true,
      if (hidden) 'hidden': true,
      if (options != null)
        'options': options!.map((option) => option.toJson()).toList(),
      if (fields != null)
        'fields': fields!.map((field) => field.toJson()).toList(),
      if (items != null) 'items': items!.toJson(),
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      if (hasDefaultItem) 'defaultItem': thawJsonValue(defaultItem),
      if (dependsOn.isNotEmpty) 'dependsOn': dependsOn,
      if (dependsOn.isNotEmpty && dependency.toJson().isNotEmpty)
        'dependencyConfig': dependency.toJson(),
      if (dataSource != null) 'dataSource': dataSource!.toJson(),
      if (asyncValidation != null) 'asyncValidation': asyncValidation!.toJson(),
      if (fileUpload != null) 'upload': fileUpload!.toJson(),
      if (validation != null) 'validation': validation!.toJson(),
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
