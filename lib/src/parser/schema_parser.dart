import '../errors/schema_parse_exception.dart';
import '../schema/dependency_schema.dart';
import '../schema/field_option.dart';
import '../schema/field_schema.dart';
import '../schema/form_type.dart';
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

    final fields = _parseFields(fieldsValue, r'$.fields');

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

  List<FieldSchema> _parseFields(List<Object?> source, String path) {
    final fields = <FieldSchema>[];
    final keys = <String>{};
    for (var index = 0; index < source.length; index++) {
      final fieldPath = '$path[$index]';
      final field = _parseField(source[index], fieldPath);
      if (!keys.add(field.key)) {
        throw SchemaParseException(
          'Field key "${field.key}" is duplicated.',
          path: '$fieldPath.key',
        );
      }
      fields.add(field);
    }
    return fields;
  }

  FieldSchema _parseField(
    Object? source,
    String path, {
    bool requireKey = true,
  }) {
    final json = _object(source, path);
    final hasExplicitKey = json.containsKey('key');
    final key = requireKey || hasExplicitKey
        ? _requiredString(json, 'key', '$path.key')
        : 'item';
    if (!_fieldPathPattern.hasMatch(key)) {
      throw SchemaParseException(
        'Field keys must use dot-separated identifiers and optional numeric '
        'indexes, for example "address.city" or "employees[0].name".',
        path: '$path.key',
      );
    }

    final type = _requiredString(json, 'type', '$path.type');

    List<FieldSchema>? childFields;
    if (json.containsKey('fields')) {
      final fieldsValue = json['fields'];
      if (fieldsValue is! List<Object?>) {
        throw SchemaParseException(
          'Property "fields" must be an array.',
          path: '$path.fields',
        );
      }
      childFields = _parseFields(fieldsValue, '$path.fields');
    }
    if (type == FormType.object && childFields == null) {
      throw SchemaParseException(
        'Object fields require a "fields" array.',
        path: '$path.fields',
      );
    }

    FieldSchema? items;
    if (json.containsKey('items')) {
      items = _parseField(json['items'], '$path.items', requireKey: false);
    }
    if (type == FormType.array && items == null) {
      throw SchemaParseException(
        'Array fields require an "items" schema.',
        path: '$path.items',
      );
    }

    final minItems = _optionalInt(json, 'minItems', '$path.minItems');
    final maxItems = _optionalInt(json, 'maxItems', '$path.maxItems');
    if (minItems != null && minItems < 0) {
      throw SchemaParseException(
        'Property "minItems" cannot be negative.',
        path: '$path.minItems',
      );
    }
    if (maxItems != null && maxItems < 0) {
      throw SchemaParseException(
        'Property "maxItems" cannot be negative.',
        path: '$path.maxItems',
      );
    }
    if (minItems != null && maxItems != null && minItems > maxItems) {
      throw SchemaParseException(
        'Property "minItems" cannot exceed "maxItems".',
        path: '$path.minItems',
      );
    }

    final dependsOn = _stringList(json, 'dependsOn', '$path.dependsOn');
    var dependency = const DependencySchema();
    if (json.containsKey('dependencyConfig')) {
      final config = _object(
        json['dependencyConfig'],
        '$path.dependencyConfig',
      );
      dependency = DependencySchema(
        clearOnChange: _optionalBool(
          config,
          'clearOnChange',
          '$path.dependencyConfig.clearOnChange',
        ),
        revalidateOnChange: _optionalBoolDefault(
          config,
          'revalidateOnChange',
          '$path.dependencyConfig.revalidateOnChange',
          defaultValue: true,
        ),
        reloadDataOnChange: _optionalBool(
          config,
          'reloadDataOnChange',
          '$path.dependencyConfig.reloadDataOnChange',
        ),
        preserveValueIfValid: _optionalBool(
          config,
          'preserveValueIfValid',
          '$path.dependencyConfig.preserveValueIfValid',
        ),
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
      final frozenRules = <String, Object?>{};
      for (final entry in rules.entries) {
        if (entry.key.trim().isEmpty) {
          throw SchemaParseException(
            'Validation rule names cannot be empty.',
            path: '$path.validation',
          );
        }
        frozenRules[entry.key] = freezeJsonValue(
          entry.value,
          path: '$path.validation.${entry.key}',
        );
      }
      validation = ValidationSchema(frozenRules);
    }

    return FieldSchema(
      key: key,
      type: type,
      label: _optionalString(json, 'label', '$path.label'),
      description: _optionalString(json, 'description', '$path.description'),
      helperText: _optionalString(json, 'helperText', '$path.helperText'),
      placeholder: _optionalString(json, 'placeholder', '$path.placeholder'),
      defaultValue: json.containsKey('defaultValue')
          ? freezeJsonValue(json['defaultValue'], path: '$path.defaultValue')
          : null,
      hasDefaultValue: json.containsKey('defaultValue'),
      required: _optionalBool(json, 'required', '$path.required'),
      disabled: _optionalBool(json, 'disabled', '$path.disabled'),
      readOnly: _optionalBool(json, 'readOnly', '$path.readOnly'),
      hidden: _optionalBool(json, 'hidden', '$path.hidden'),
      hasExplicitKey: hasExplicitKey,
      options: options,
      fields: childFields,
      items: items,
      minItems: minItems,
      maxItems: maxItems,
      defaultItem: json.containsKey('defaultItem')
          ? freezeJsonValue(json['defaultItem'], path: '$path.defaultItem')
          : null,
      hasDefaultItem: json.containsKey('defaultItem'),
      dependsOn: dependsOn,
      dependency: dependency,
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
        'fields',
        'items',
        'minItems',
        'maxItems',
        'defaultItem',
        'dependsOn',
        'dependencyConfig',
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
      value: freezeJsonValue(json['value'], path: '$path.value'),
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

  bool _optionalBoolDefault(
    Map<String, Object?> json,
    String key,
    String path, {
    required bool defaultValue,
  }) {
    if (!json.containsKey(key)) return defaultValue;
    return _optionalBool(json, key, path);
  }

  int? _optionalInt(Map<String, Object?> json, String key, String path) {
    if (!json.containsKey(key)) return null;
    final value = json[key];
    if (value is! int) {
      throw SchemaParseException(
        'Property "$key" must be an integer.',
        path: path,
      );
    }
    return value;
  }

  List<String> _stringList(Map<String, Object?> json, String key, String path) {
    if (!json.containsKey(key)) return const [];
    final value = json[key];
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      throw SchemaParseException(
        'Property "$key" must be an array of strings.',
        path: path,
      );
    }
    return value.cast<String>();
  }

  Map<String, Object?> _optionalObject(
    Map<String, Object?> json,
    String key,
    String path,
  ) {
    if (!json.containsKey(key)) {
      return const {};
    }
    final value = _object(json[key], path);
    return freezeJsonValue(value, path: path)! as Map<String, Object?>;
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
