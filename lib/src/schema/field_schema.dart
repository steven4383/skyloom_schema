import '../utils/json_value_utils.dart';
import 'dependency_schema.dart';
import 'field_option.dart';
import 'validation_schema.dart';

/// Immutable definition of one form field.
final class FieldSchema {
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

  final String key;

  /// A string rather than an enum so custom renderer types remain possible.
  final String type;
  final String? label;
  final String? description;
  final String? helperText;
  final String? placeholder;
  final Object? defaultValue;

  /// Distinguishes an omitted default from an explicit JSON `null` default.
  final bool hasDefaultValue;
  final bool required;
  final bool disabled;
  final bool readOnly;
  final bool hidden;
  final bool hasExplicitKey;
  final List<FieldOption>? options;
  final List<FieldSchema>? fields;
  final FieldSchema? items;
  final int? minItems;
  final int? maxItems;
  final Object? defaultItem;
  final bool hasDefaultItem;
  final List<String> dependsOn;
  final DependencySchema dependency;
  final ValidationSchema? validation;
  final Map<String, Object?> metadata;

  /// Properties preserved for forward compatibility but not interpreted yet.
  final Map<String, Object?> additionalProperties;

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
