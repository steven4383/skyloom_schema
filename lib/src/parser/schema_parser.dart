import '../errors/schema_parse_exception.dart';
import '../errors/schema_diagnostic.dart';
import '../schema/dependency_schema.dart';
import '../schema/data_source_schema.dart';
import '../schema/async_validation_schema.dart';
import '../schema/field_option.dart';
import '../schema/file_upload_schema.dart';
import '../schema/field_schema.dart';
import '../schema/form_type.dart';
import '../schema/form_schema.dart';
import '../schema/validation_schema.dart';
import '../schema/ui_schema.dart';
import '../schema/section_schema.dart';
import '../schema/step_schema.dart';
import '../utils/json_value_utils.dart';
import 'schema_limits.dart';

/// Parses and validates JSON-compatible Skyloom form definitions.
final class SchemaParser {
  const SchemaParser({
    this.limits = const SchemaLimits(),
    this.unknownFieldTypePolicy = SchemaUnknownFieldTypePolicy.allow,
    this.knownFieldTypes = FormType.builtInTypes,
  });

  final SchemaLimits limits;
  final SchemaUnknownFieldTypePolicy unknownFieldTypePolicy;
  final Set<String> knownFieldTypes;

  static final RegExp _fieldPathPattern = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_-]*(?:\[\d+\])*(?:\.[A-Za-z_][A-Za-z0-9_-]*(?:\[\d+\])*)*$',
  );

  /// Validates a schema and reports independent errors and warnings together.
  SchemaValidationResult validate(Object? source) {
    final diagnostics = _collectDiagnostics(source);
    FormSchema? schema;
    try {
      schema = parse(source);
    } on SchemaParseException catch (error) {
      final duplicate = diagnostics.any(
        (item) => item.path == error.path && item.message == error.message,
      );
      if (!duplicate) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'schema.parse',
            message: error.message,
            path: error.path,
          ),
        );
      }
    }
    return SchemaValidationResult(diagnostics: diagnostics, schema: schema);
  }

  FormSchema parse(Object? source) {
    final guardError = _collectDiagnostics(source).where(
      (item) =>
          item.severity == SchemaDiagnosticSeverity.error &&
          (item.code.startsWith('limit.') ||
              item.code == 'schema.unknownFieldType'),
    );
    if (guardError.isNotEmpty) {
      final error = guardError.first;
      throw SchemaParseException(error.message, path: error.path);
    }
    final json = _object(source, r'$');
    final fieldsValue = json['fields'];
    if (fieldsValue is! List<Object?>) {
      throw const SchemaParseException(
        'Required property "fields" must be an array.',
        path: r'$.fields',
      );
    }

    final fields = _parseFields(fieldsValue, r'$.fields');
    final uiSchema = _parseUiSchema(json['uiSchema'], r'$.uiSchema');
    final rootFieldKeys = fields.map((field) => field.key).toSet();
    for (final fieldKey in uiSchema.keys) {
      if (!rootFieldKeys.contains(fieldKey)) {
        throw SchemaParseException(
          'UI schema references unknown root field "$fieldKey".',
          path: r'$.uiSchema',
        );
      }
    }
    final sections = _parseSections(json['sections'], r'$.sections', fields);
    final steps = _parseSteps(json['steps'], r'$.steps', fields);

    return FormSchema(
      id: _requiredString(json, 'id', r'$.id'),
      schemaVersion:
          _optionalString(json, 'schemaVersion', r'$.schemaVersion') ?? '1.0',
      title: _optionalString(json, 'title', r'$.title'),
      description: _optionalString(json, 'description', r'$.description'),
      fields: fields,
      uiSchema: uiSchema,
      sections: sections,
      steps: steps,
      metadata: _optionalObject(json, 'metadata', r'$.metadata'),
      additionalProperties: _additionalProperties(json, const {
        'schemaVersion',
        'id',
        'title',
        'description',
        'fields',
        'metadata',
        'uiSchema',
        'sections',
        'steps',
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

    DataSourceSchema? dataSource;
    if (json.containsKey('dataSource')) {
      final config = _object(json['dataSource'], '$path.dataSource');
      final pageSize =
          _optionalInt(config, 'pageSize', '$path.dataSource.pageSize') ?? 20;
      final debounce =
          _optionalInt(
            config,
            'debounceMilliseconds',
            '$path.dataSource.debounceMilliseconds',
          ) ??
          300;
      if (pageSize <= 0 || debounce < 0) {
        throw SchemaParseException(
          'Data-source page size must be positive and debounce cannot be negative.',
          path: '$path.dataSource',
        );
      }
      dataSource = DataSourceSchema(
        handler: _requiredString(config, 'handler', '$path.dataSource.handler'),
        search: _optionalBoolDefault(
          config,
          'search',
          '$path.dataSource.search',
          defaultValue: true,
        ),
        pageSize: pageSize,
        debounceMilliseconds: debounce,
        cache: _optionalBoolDefault(
          config,
          'cache',
          '$path.dataSource.cache',
          defaultValue: true,
        ),
        labelField: config.containsKey('mapping')
            ? _requiredString(
                _object(config['mapping'], '$path.dataSource.mapping'),
                'label',
                '$path.dataSource.mapping.label',
              )
            : 'label',
        valueField: config.containsKey('mapping')
            ? _requiredString(
                _object(config['mapping'], '$path.dataSource.mapping'),
                'value',
                '$path.dataSource.mapping.value',
              )
            : 'value',
        metadataField: config.containsKey('mapping')
            ? _optionalString(
                    _object(config['mapping'], '$path.dataSource.mapping'),
                    'metadata',
                    '$path.dataSource.mapping.metadata',
                  ) ??
                  'metadata'
            : 'metadata',
      );
    }

    AsyncValidationSchema? asyncValidation;
    if (json.containsKey('asyncValidation')) {
      final config = _object(json['asyncValidation'], '$path.asyncValidation');
      final debounce =
          _optionalInt(
            config,
            'debounceMilliseconds',
            '$path.asyncValidation.debounceMilliseconds',
          ) ??
          300;
      if (debounce < 0) {
        throw SchemaParseException(
          'Async-validation debounce cannot be negative.',
          path: '$path.asyncValidation.debounceMilliseconds',
        );
      }
      asyncValidation = AsyncValidationSchema(
        handler: _requiredString(
          config,
          'handler',
          '$path.asyncValidation.handler',
        ),
        debounceMilliseconds: debounce,
        cache: _optionalBoolDefault(
          config,
          'cache',
          '$path.asyncValidation.cache',
          defaultValue: true,
        ),
      );
    }

    FileUploadSchema? fileUpload;
    if (json.containsKey('upload')) {
      final config = _object(json['upload'], '$path.upload');
      final multiple = _optionalBool(
        config,
        'multiple',
        '$path.upload.multiple',
      );
      final maxBytes = _optionalInt(
        config,
        'maxBytes',
        '$path.upload.maxBytes',
      );
      final maxFiles =
          _optionalInt(config, 'maxFiles', '$path.upload.maxFiles') ??
          (multiple ? 10 : 1);
      if (maxBytes != null && maxBytes <= 0) {
        throw SchemaParseException(
          'Upload maxBytes must be positive.',
          path: '$path.upload.maxBytes',
        );
      }
      if (maxFiles <= 0 || maxFiles > limits.maxArrayItems) {
        throw SchemaParseException(
          'Upload maxFiles must be between 1 and ${limits.maxArrayItems}.',
          path: '$path.upload.maxFiles',
        );
      }
      if (!multiple && maxFiles != 1) {
        throw SchemaParseException(
          'Single-file uploads require maxFiles to be 1.',
          path: '$path.upload.maxFiles',
        );
      }
      final accept = _stringList(config, 'accept', '$path.upload.accept');
      if (accept.any((value) => value.trim().isEmpty)) {
        throw SchemaParseException(
          'Upload accept entries must not be empty.',
          path: '$path.upload.accept',
        );
      }
      fileUpload = FileUploadSchema(
        handler: _requiredString(config, 'handler', '$path.upload.handler'),
        multiple: multiple,
        accept: accept,
        maxBytes: maxBytes,
        maxFiles: maxFiles,
      );
    }
    if (type == FormType.file && fileUpload == null) {
      throw SchemaParseException(
        'File fields require an "upload" configuration.',
        path: '$path.upload',
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
      dataSource: dataSource,
      asyncValidation: asyncValidation,
      fileUpload: fileUpload,
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
        'dataSource',
        'asyncValidation',
        'upload',
        'validation',
        'metadata',
      }, path),
    );
  }

  Map<String, FieldUiSchema> _parseUiSchema(Object? source, String path) {
    if (source == null) return const {};
    final json = _object(source, path);
    return json.map((fieldKey, value) {
      final fieldPath = '$path.$fieldKey';
      final config = _object(value, fieldPath);
      var layout = const ResponsiveLayoutSchema();
      if (config.containsKey('layout')) {
        final layoutJson = _object(config['layout'], '$fieldPath.layout');
        final mobile = _layoutSpan(
          layoutJson,
          'mobile',
          '$fieldPath.layout.mobile',
        );
        final tablet = _layoutSpan(
          layoutJson,
          'tablet',
          '$fieldPath.layout.tablet',
        );
        final desktop = _layoutSpan(
          layoutJson,
          'desktop',
          '$fieldPath.layout.desktop',
        );
        layout = ResponsiveLayoutSchema(
          mobile: mobile,
          tablet: tablet,
          desktop: desktop,
        );
      }
      return MapEntry(
        fieldKey,
        FieldUiSchema(
          widget: _optionalString(config, 'widget', '$fieldPath.widget'),
          layout: layout,
          order: _optionalInt(config, 'order', '$fieldPath.order'),
          group: _optionalString(config, 'group', '$fieldPath.group'),
          visualHints: _optionalObject(
            config,
            'visualHints',
            '$fieldPath.visualHints',
          ),
        ),
      );
    });
  }

  int _layoutSpan(Map<String, Object?> json, String key, String path) {
    final value = _optionalInt(json, key, path) ?? 12;
    if (value < 1 || value > 12) {
      throw SchemaParseException(
        'Layout spans must be between 1 and 12.',
        path: path,
      );
    }
    return value;
  }

  List<SectionSchema> _parseSections(
    Object? source,
    String path,
    List<FieldSchema> fields,
  ) {
    if (source == null) return const [];
    if (source is! List<Object?>) {
      throw SchemaParseException(
        'Property "sections" must be an array.',
        path: path,
      );
    }
    final fieldKeys = fields.map((field) => field.key).toSet();
    final ids = <String>{};
    final assignedFields = <String>{};
    return <SectionSchema>[
      for (var index = 0; index < source.length; index++)
        _parseSection(
          source[index],
          '$path[$index]',
          fieldKeys,
          ids,
          assignedFields,
        ),
    ];
  }

  SectionSchema _parseSection(
    Object? source,
    String path,
    Set<String> fieldKeys,
    Set<String> ids,
    Set<String> assignedFields,
  ) {
    final json = _object(source, path);
    final id = _requiredString(json, 'id', '$path.id');
    if (!ids.add(id)) {
      throw SchemaParseException(
        'Section id "$id" is duplicated.',
        path: '$path.id',
      );
    }
    final fields = _stringList(json, 'fields', '$path.fields');
    if (!json.containsKey('fields')) {
      throw SchemaParseException(
        'Required property "fields" must be an array.',
        path: '$path.fields',
      );
    }
    for (final field in fields) {
      if (!fieldKeys.contains(field)) {
        throw SchemaParseException(
          'Section references unknown root field "$field".',
          path: '$path.fields',
        );
      }
      if (!assignedFields.add(field)) {
        throw SchemaParseException(
          'Field "$field" belongs to more than one section.',
          path: '$path.fields',
        );
      }
    }
    return SectionSchema(
      id: id,
      title: _optionalString(json, 'title', '$path.title'),
      description: _optionalString(json, 'description', '$path.description'),
      fields: fields,
      collapsible: _optionalBool(json, 'collapsible', '$path.collapsible'),
      defaultExpanded: _optionalBoolDefault(
        json,
        'defaultExpanded',
        '$path.defaultExpanded',
        defaultValue: true,
      ),
      order: _optionalInt(json, 'order', '$path.order') ?? 0,
    );
  }

  List<StepSchema> _parseSteps(
    Object? source,
    String path,
    List<FieldSchema> fields,
  ) {
    if (source == null) return const [];
    if (source is! List<Object?> || source.isEmpty) {
      throw SchemaParseException(
        'Property "steps" must be a non-empty array.',
        path: path,
      );
    }
    final fieldKeys = fields.map((field) => field.key).toSet();
    final ids = <String>{};
    final assignedFields = <String>{};
    final steps = <StepSchema>[];
    for (var index = 0; index < source.length; index++) {
      final stepPath = '$path[$index]';
      final json = _object(source[index], stepPath);
      final id = _requiredString(json, 'id', '$stepPath.id');
      if (!ids.add(id)) {
        throw SchemaParseException(
          'Step id "$id" is duplicated.',
          path: '$stepPath.id',
        );
      }
      final stepFields = _stringList(json, 'fields', '$stepPath.fields');
      if (!json.containsKey('fields') || stepFields.isEmpty) {
        throw SchemaParseException(
          'A step requires a non-empty "fields" array.',
          path: '$stepPath.fields',
        );
      }
      for (final field in stepFields) {
        if (!fieldKeys.contains(field)) {
          throw SchemaParseException(
            'Step references unknown root field "$field".',
            path: '$stepPath.fields',
          );
        }
        if (!assignedFields.add(field)) {
          throw SchemaParseException(
            'Field "$field" belongs to more than one step.',
            path: '$stepPath.fields',
          );
        }
      }
      steps.add(
        StepSchema(
          id: id,
          title: _optionalString(json, 'title', '$stepPath.title'),
          description: _optionalString(
            json,
            'description',
            '$stepPath.description',
          ),
          fields: stepFields,
          order: _optionalInt(json, 'order', '$stepPath.order') ?? 0,
          visibleWhen: json.containsKey('visibleWhen')
              ? freezeJsonValue(
                  json['visibleWhen'],
                  path: '$stepPath.visibleWhen',
                )
              : null,
        ),
      );
    }
    final unassigned = fieldKeys.difference(assignedFields);
    if (unassigned.isNotEmpty) {
      throw SchemaParseException(
        'Every root field must belong to a step. Missing: '
        '${unassigned.join(', ')}.',
        path: path,
      );
    }
    return steps;
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

  List<SchemaDiagnostic> _collectDiagnostics(Object? source) {
    final diagnostics = <SchemaDiagnostic>[];
    void report(String code, String message, String path) {
      diagnostics.add(
        SchemaDiagnostic(code: code, message: message, path: path),
      );
    }

    if (source is! Map<Object?, Object?>) {
      diagnostics.add(
        const SchemaDiagnostic(
          code: 'schema.expectedObject',
          message: 'Expected a JSON object.',
          path: r'$',
        ),
      );
      return diagnostics;
    }
    final root = _stringKeyedMap(source);
    if (root == null) {
      diagnostics.add(
        const SchemaDiagnostic(
          code: 'schema.nonStringKey',
          message: 'JSON object keys must be strings.',
          path: r'$',
        ),
      );
      return diagnostics;
    }
    if (root['id'] is! String || (root['id']! as String).trim().isEmpty) {
      diagnostics.add(
        const SchemaDiagnostic(
          code: 'schema.requiredString',
          message: 'Required property "id" must be a non-empty string.',
          path: r'$.id',
        ),
      );
    }
    for (final property in const ['schemaVersion', 'title', 'description']) {
      if (root.containsKey(property) && root[property] is! String) {
        report(
          'schema.expectedString',
          'Property "$property" must be a string.',
          r'$.' + property,
        );
      }
    }
    if (root.containsKey('metadata') &&
        root['metadata'] is! Map<Object?, Object?>) {
      report(
        'schema.expectedObject',
        'Property "metadata" must be an object.',
        r'$.metadata',
      );
    }
    final fields = root['fields'];
    if (fields is! List<Object?>) {
      diagnostics.add(
        const SchemaDiagnostic(
          code: 'schema.requiredArray',
          message: 'Required property "fields" must be an array.',
          path: r'$.fields',
        ),
      );
      return diagnostics;
    }

    var fieldCount = 0;
    var conditionNodes = 0;
    var fieldLimitReported = false;
    var conditionNodeLimitReported = false;

    void inspectCondition(Object? value, String path, int depth) {
      if (value == null) return;
      conditionNodes++;
      if (conditionNodes > limits.maxConditionNodes &&
          !conditionNodeLimitReported) {
        conditionNodeLimitReported = true;
        diagnostics.add(
          SchemaDiagnostic(
            code: 'limit.conditionNodes',
            message:
                'Condition graph exceeds ${limits.maxConditionNodes} nodes.',
            path: path,
          ),
        );
      }
      if (depth > limits.maxConditionDepth) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'limit.conditionDepth',
            message:
                'Condition nesting exceeds ${limits.maxConditionDepth} levels.',
            path: path,
          ),
        );
        return;
      }
      if (value is Map<Object?, Object?>) {
        for (final entry in value.entries) {
          if (entry.key == 'all' || entry.key == 'any') {
            final children = entry.value;
            if (children is List<Object?>) {
              for (var index = 0; index < children.length; index++) {
                inspectCondition(
                  children[index],
                  '$path.${entry.key}[$index]',
                  depth + 1,
                );
              }
            }
          } else if (entry.key == 'not') {
            inspectCondition(entry.value, '$path.not', depth + 1);
          }
        }
      }
    }

    void inspectField(
      Object? value,
      String path,
      int depth, {
      bool requireKey = true,
    }) {
      fieldCount++;
      if (fieldCount > limits.maxFields && !fieldLimitReported) {
        fieldLimitReported = true;
        diagnostics.add(
          SchemaDiagnostic(
            code: 'limit.fields',
            message: 'Schema exceeds ${limits.maxFields} fields.',
            path: path,
          ),
        );
      }
      if (depth > limits.maxNestingDepth) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'limit.nestingDepth',
            message: 'Field nesting exceeds ${limits.maxNestingDepth} levels.',
            path: path,
          ),
        );
        return;
      }
      if (value is! Map<Object?, Object?>) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'schema.expectedFieldObject',
            message: 'Expected a field object.',
            path: path,
          ),
        );
        return;
      }
      final field = _stringKeyedMap(value);
      if (field == null) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'schema.nonStringKey',
            message: 'JSON object keys must be strings.',
            path: path,
          ),
        );
        return;
      }
      final key = field['key'];
      if ((requireKey || field.containsKey('key')) &&
          (key is! String || key.trim().isEmpty)) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'schema.requiredString',
            message: 'Required property "key" must be a non-empty string.',
            path: '$path.key',
          ),
        );
      }
      if (key is String && key.isNotEmpty && !_fieldPathPattern.hasMatch(key)) {
        report(
          'schema.invalidFieldPath',
          'Field key "$key" is not a valid value path.',
          '$path.key',
        );
      }
      final type = field['type'];
      if (type is! String || type.trim().isEmpty) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'schema.requiredString',
            message: 'Required property "type" must be a non-empty string.',
            path: '$path.type',
          ),
        );
      } else if (!knownFieldTypes.contains(type) &&
          unknownFieldTypePolicy != SchemaUnknownFieldTypePolicy.allow) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'schema.unknownFieldType',
            message: 'Field type "$type" has no registered built-in type.',
            path: '$path.type',
            severity:
                unknownFieldTypePolicy == SchemaUnknownFieldTypePolicy.error
                ? SchemaDiagnosticSeverity.error
                : SchemaDiagnosticSeverity.warning,
          ),
        );
      }
      for (final property in const [
        'label',
        'description',
        'helperText',
        'placeholder',
      ]) {
        if (field.containsKey(property) && field[property] is! String) {
          report(
            'schema.expectedString',
            'Property "$property" must be a string.',
            '$path.$property',
          );
        }
      }
      for (final property in const [
        'required',
        'disabled',
        'readOnly',
        'hidden',
      ]) {
        if (field.containsKey(property) && field[property] is! bool) {
          report(
            'schema.expectedBoolean',
            'Property "$property" must be a boolean.',
            '$path.$property',
          );
        }
      }
      final options = field['options'];
      if (field.containsKey('options') && options is! List<Object?>) {
        report(
          'schema.expectedArray',
          'Property "options" must be an array.',
          '$path.options',
        );
      }
      if (options is List<Object?> &&
          options.length > limits.maxOptionsPerField) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'limit.options',
            message: 'Field options exceed ${limits.maxOptionsPerField} items.',
            path: '$path.options',
          ),
        );
      }
      if (options is List<Object?>) {
        for (var index = 0; index < options.length; index++) {
          final optionPath = '$path.options[$index]';
          final option = options[index];
          if (option is! Map<Object?, Object?>) {
            report(
              'schema.expectedOptionObject',
              'Expected an option object.',
              optionPath,
            );
            continue;
          }
          final normalized = _stringKeyedMap(option);
          if (normalized == null) {
            report(
              'schema.nonStringKey',
              'JSON object keys must be strings.',
              optionPath,
            );
            continue;
          }
          if (normalized['label'] is! String ||
              (normalized['label']! as String).trim().isEmpty) {
            report(
              'schema.requiredString',
              'Required property "label" must be a non-empty string.',
              '$optionPath.label',
            );
          }
          if (!normalized.containsKey('value')) {
            report(
              'schema.requiredProperty',
              'Required property "value" is missing.',
              '$optionPath.value',
            );
          }
        }
      }
      final minItems = field['minItems'];
      final maxItems = field['maxItems'];
      if (field.containsKey('minItems') && minItems is! int) {
        report(
          'schema.expectedInteger',
          'Property "minItems" must be an integer.',
          '$path.minItems',
        );
      } else if (minItems is int && minItems < 0) {
        report(
          'schema.invalidRange',
          'Property "minItems" cannot be negative.',
          '$path.minItems',
        );
      }
      if (field.containsKey('maxItems') && maxItems is! int) {
        report(
          'schema.expectedInteger',
          'Property "maxItems" must be an integer.',
          '$path.maxItems',
        );
      } else if (maxItems is int && maxItems < 0) {
        report(
          'schema.invalidRange',
          'Property "maxItems" cannot be negative.',
          '$path.maxItems',
        );
      }
      if (minItems is int && maxItems is int && minItems > maxItems) {
        report(
          'schema.invalidRange',
          'Property "minItems" cannot exceed "maxItems".',
          '$path.minItems',
        );
      }
      if (maxItems is int && maxItems > limits.maxArrayItems) {
        diagnostics.add(
          SchemaDiagnostic(
            code: 'limit.arrayItems',
            message:
                'Array maxItems exceeds the limit of ${limits.maxArrayItems}.',
            path: '$path.maxItems',
          ),
        );
      }
      if (field.containsKey('validation') &&
          field['validation'] is! Map<Object?, Object?>) {
        report(
          'schema.expectedObject',
          'Property "validation" must be an object.',
          '$path.validation',
        );
      }
      if (field.containsKey('metadata') &&
          field['metadata'] is! Map<Object?, Object?>) {
        report(
          'schema.expectedObject',
          'Property "metadata" must be an object.',
          '$path.metadata',
        );
      }

      final upload = field['upload'];
      if (type == FormType.file && upload is! Map<Object?, Object?>) {
        report(
          'schema.requiredUpload',
          'File fields require an "upload" configuration.',
          '$path.upload',
        );
      } else if (upload != null && upload is! Map<Object?, Object?>) {
        report(
          'schema.expectedObject',
          'Property "upload" must be an object.',
          '$path.upload',
        );
      } else if (upload is Map<Object?, Object?>) {
        final normalized = _stringKeyedMap(upload);
        if (normalized == null) {
          report(
            'schema.nonStringKey',
            'JSON object keys must be strings.',
            '$path.upload',
          );
        } else {
          if (normalized['handler'] is! String ||
              (normalized['handler']! as String).trim().isEmpty) {
            report(
              'schema.requiredString',
              'Required property "handler" must be a non-empty string.',
              '$path.upload.handler',
            );
          }
          if (normalized.containsKey('multiple') &&
              normalized['multiple'] is! bool) {
            report(
              'schema.expectedBoolean',
              'Property "multiple" must be a boolean.',
              '$path.upload.multiple',
            );
          }
          final accept = normalized['accept'];
          if (accept != null &&
              (accept is! List<Object?> ||
                  accept.any((item) => item is! String))) {
            report(
              'schema.expectedStringArray',
              'Property "accept" must be an array of strings.',
              '$path.upload.accept',
            );
          } else if (accept is List<Object?> &&
              accept.cast<String>().any((item) => item.trim().isEmpty)) {
            report(
              'schema.emptyUploadAccept',
              'Upload accept entries must not be empty.',
              '$path.upload.accept',
            );
          }
          for (final property in const ['maxBytes', 'maxFiles']) {
            final limit = normalized[property];
            if (limit != null && (limit is! int || limit <= 0)) {
              report(
                'schema.expectedPositiveInteger',
                'Property "$property" must be a positive integer.',
                '$path.upload.$property',
              );
            }
          }
          final multiple = normalized['multiple'] == true;
          final uploadMaxFiles = normalized['maxFiles'];
          if (!multiple && uploadMaxFiles is int && uploadMaxFiles != 1) {
            report(
              'schema.invalidUploadMaxFiles',
              'Single-file uploads require maxFiles to be 1.',
              '$path.upload.maxFiles',
            );
          }
          if (uploadMaxFiles is int && uploadMaxFiles > limits.maxArrayItems) {
            report(
              'limit.uploadFiles',
              'Upload maxFiles exceeds the limit of '
                  '${limits.maxArrayItems}.',
              '$path.upload.maxFiles',
            );
          }
        }
      }
      for (final conditionName in const [
        'visibleWhen',
        'requiredWhen',
        'enabledWhen',
        'disabledWhen',
        'readOnlyWhen',
      ]) {
        if (field.containsKey(conditionName)) {
          inspectCondition(field[conditionName], '$path.$conditionName', 1);
        }
      }
      final children = field['fields'];
      if (type == FormType.object && children is! List<Object?>) {
        report(
          'schema.requiredFields',
          'Object fields require a "fields" array.',
          '$path.fields',
        );
      } else if (children != null && children is! List<Object?>) {
        report(
          'schema.expectedArray',
          'Property "fields" must be an array.',
          '$path.fields',
        );
      }
      if (children is List<Object?>) {
        final childKeys = <String>{};
        for (var index = 0; index < children.length; index++) {
          final child = children[index];
          inspectField(child, '$path.fields[$index]', depth + 1);
          if (child is Map<Object?, Object?> && child['key'] is String) {
            final childKey = child['key']! as String;
            if (!childKeys.add(childKey)) {
              report(
                'schema.duplicateField',
                'Field key "$childKey" is duplicated.',
                '$path.fields[$index].key',
              );
            }
          }
        }
      }
      if (type == FormType.array && !field.containsKey('items')) {
        report(
          'schema.requiredItems',
          'Array fields require an "items" schema.',
          '$path.items',
        );
      }
      if (field.containsKey('items')) {
        inspectField(
          field['items'],
          '$path.items',
          depth + 1,
          requireKey: false,
        );
      }
    }

    final rootKeys = <String>{};
    for (var index = 0; index < fields.length; index++) {
      final value = fields[index];
      inspectField(
        value,
        r'$.fields'
        '[$index]',
        1,
      );
      if (value is Map<Object?, Object?> && value['key'] is String) {
        final key = value['key']! as String;
        if (!rootKeys.add(key)) {
          diagnostics.add(
            SchemaDiagnostic(
              code: 'schema.duplicateField',
              message: 'Field key "$key" is duplicated.',
              path:
                  r'$.fields'
                  '[$index].key',
            ),
          );
        }
      }
    }
    final steps = root['steps'];
    if (steps is List<Object?>) {
      for (var index = 0; index < steps.length; index++) {
        final step = steps[index];
        if (step is Map<Object?, Object?> && step.containsKey('visibleWhen')) {
          inspectCondition(
            step['visibleWhen'],
            r'$.steps'
            '[$index].visibleWhen',
            1,
          );
        }
      }
    }
    return diagnostics;
  }

  Map<String, Object?>? _stringKeyedMap(Map<Object?, Object?> value) {
    if (value.keys.any((key) => key is! String)) return null;
    return <String, Object?>{
      for (final entry in value.entries) entry.key! as String: entry.value,
    };
  }
}
