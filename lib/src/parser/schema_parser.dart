import '../errors/schema_parse_exception.dart';
import '../schema/field_option.dart';
import '../schema/field_schema.dart';
import '../schema/form_schema.dart';
import '../schema/validation_schema.dart';
import '../utils/json_value_utils.dart';

/// Parses and validates JSON-compatible Skyloom form definitions.
final class SchemaParser {
  const SchemaParser();

  static final RegExp _fieldPathPattern = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_-]*(?:\[\d+\])*(?:\.[A-Za-z_][A-Za-z0-9_-]*(?:\[\d+\])*)*$',
  );

  FormSchema parse(Object? source) {
    final json = _object(source, r'$');
    final fieldsValue = json['fields'];
    if (fieldsValue is! List<Object?>) {
      throw const SchemaParseException(
        'Required property "fields" must be an array.',
        path: r'$.fields',
      );
    }

    final fields = <FieldSchema>[];
    final keys = <String>{};
    for (var index = 0; index < fieldsValue.length; index++) {
      final path = '\$.fields[$index]';
      final field = _parseField(fieldsValue[index], path);
      if (!keys.add(field.key)) {
        throw SchemaParseException(
          'Field key "${field.key}" is duplicated.',
          path: '$path.key',
        );
      }
      fields.add(field);
    }

    return FormSchema(
      id: _requiredString(json, 'id', r'$.id'),
      schemaVersion:
          _optionalString(json, 'schemaVersion', r'$.schemaVersion') ?? '1.0',
      title: _optionalString(json, 'title', r'$.title'),
      description: _optionalString(json, 'description', r'$.description'),
      fields: fields,
      metadata: _optionalObject(json, 'metadata', r'$.metadata'),
      additionalProperties: _additionalProperties(json, const {
        'schemaVersion',
        'id',
        'title',
        'description',
        'fields',
        'metadata',
      }, r'$'),
    );
  }

  FieldSchema _parseField(Object? source, String path) {
    final json = _object(source, path);
    final key = _requiredString(json, 'key', '$path.key');
    if (!_fieldPathPattern.hasMatch(key)) {
      throw SchemaParseException(
        'Field keys must use dot-separated identifiers and optional numeric '
        'indexes, for example "address.city" or "employees[0].name".',
        path: '$path.key',
      );
    }

    final optionsValue = json['options'];
    List<FieldOption>? options;
    if (optionsValue != null) {
      if (optionsValue is! List<Object?>) {
        throw SchemaParseException(
          'Property "options" must be an array.',
          path: '$path.options',
        );
      }
      options = <FieldOption>[
        for (var index = 0; index < optionsValue.length; index++)
          _parseOption(optionsValue[index], '$path.options[$index]'),
      ];
    }

    ValidationSchema? validation;
    if (json['validation'] != null) {
      final rules = _object(json['validation'], '$path.validation');
      for (final key in rules.keys) {
        if (key.trim().isEmpty) {
          throw SchemaParseException(
            'Validation rule names cannot be empty.',
            path: '$path.validation',
          );
        }
      }
      validation = ValidationSchema(rules);
    }

    return FieldSchema(
      key: key,
      type: _requiredString(json, 'type', '$path.type'),
      label: _optionalString(json, 'label', '$path.label'),
      description: _optionalString(json, 'description', '$path.description'),
      helperText: _optionalString(json, 'helperText', '$path.helperText'),
      placeholder: _optionalString(json, 'placeholder', '$path.placeholder'),
      defaultValue: json['defaultValue'],
      hasDefaultValue: json.containsKey('defaultValue'),
      required: _optionalBool(json, 'required', '$path.required'),
      disabled: _optionalBool(json, 'disabled', '$path.disabled'),
      readOnly: _optionalBool(json, 'readOnly', '$path.readOnly'),
      hidden: _optionalBool(json, 'hidden', '$path.hidden'),
      options: options,
      validation: validation,
      metadata: _optionalObject(json, 'metadata', '$path.metadata'),
      additionalProperties: _additionalProperties(json, const {
        'key',
        'type',
        'label',
        'description',
        'helperText',
        'placeholder',
        'defaultValue',
        'required',
        'disabled',
        'readOnly',
        'hidden',
        'options',
        'validation',
        'metadata',
      }, path),
    );
  }

  FieldOption _parseOption(Object? source, String path) {
    final json = _object(source, path);
    if (!json.containsKey('value')) {
      throw SchemaParseException(
        'Required property "value" is missing.',
        path: '$path.value',
      );
    }
    return FieldOption(
      label: _requiredString(json, 'label', '$path.label'),
      value: json['value'],
      metadata: _optionalObject(json, 'metadata', '$path.metadata'),
      additionalProperties: _additionalProperties(json, const {
        'label',
        'value',
        'metadata',
      }, path),
    );
  }

  Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map<Object?, Object?>) {
      throw SchemaParseException('Expected a JSON object.', path: path);
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw SchemaParseException(
          'JSON object keys must be strings.',
          path: path,
        );
      }
      result[entry.key! as String] = entry.value;
    }
    return result;
  }

  String _requiredString(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw SchemaParseException(
        'Required property "$key" must be a non-empty string.',
        path: path,
      );
    }
    return value;
  }

  String? _optionalString(Map<String, Object?> json, String key, String path) {
    if (!json.containsKey(key) || json[key] == null) {
      return null;
    }
    final value = json[key];
    if (value is! String) {
      throw SchemaParseException(
        'Property "$key" must be a string.',
        path: path,
      );
    }
    return value;
  }

  bool _optionalBool(Map<String, Object?> json, String key, String path) {
    if (!json.containsKey(key)) {
      return false;
    }
    final value = json[key];
    if (value is! bool) {
      throw SchemaParseException(
        'Property "$key" must be a boolean.',
        path: path,
      );
    }
    return value;
  }

  Map<String, Object?> _optionalObject(
    Map<String, Object?> json,
    String key,
    String path,
  ) {
    if (!json.containsKey(key)) {
      return const {};
    }
    return _object(json[key], path);
  }

  Map<String, Object?> _additionalProperties(
    Map<String, Object?> json,
    Set<String> knownKeys,
    String path,
  ) {
    return <String, Object?>{
      for (final entry in json.entries)
        if (!knownKeys.contains(entry.key))
          entry.key: freezeJsonValue(entry.value, path: '$path.${entry.key}'),
    };
  }
}
