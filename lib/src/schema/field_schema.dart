import '../utils/json_value_utils.dart';
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
    List<FieldOption>? options,
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
  final List<FieldOption>? options;
  final ValidationSchema? validation;
  final Map<String, Object?> metadata;

  /// Properties preserved for forward compatibility but not interpreted yet.
  final Map<String, Object?> additionalProperties;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      ..._thawMap(additionalProperties),
      'key': key,
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
