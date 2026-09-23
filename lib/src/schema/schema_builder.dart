import '../parser/schema_parser.dart';
import 'async_validation_schema.dart';
import 'data_source_schema.dart';
import 'dependency_schema.dart';
import 'field_option.dart';
import 'field_schema.dart';
import 'file_upload_schema.dart';
import 'form_schema.dart';
import 'form_type.dart';
import 'section_schema.dart';
import 'step_schema.dart';
import 'ui_schema.dart';
import 'validation_rule.dart';
import 'validation_schema.dart';

const Object _unsetSchemaValue = Object();

/// Autocomplete-friendly entry point for authoring a form in Dart.
abstract final class SkyloomSchema {
  /// Builds and validates a typed form definition.
  ///
  /// The resulting model uses the same parser and contract as a JSON schema.
  static FormSchema form({
    required String id,
    required List<FieldSchema> fields,
    String schemaVersion = '1.0',
    String? title,
    String? description,
    Map<String, FieldUiSchema> uiSchema = const {},
    List<SectionSchema> sections = const [],
    List<StepSchema> steps = const [],
    Map<String, Object?> metadata = const {},
    Map<String, Object?> additionalProperties = const {},
    SchemaParser parser = const SchemaParser(),
  }) {
    final schema = FormSchema(
      id: id,
      fields: fields,
      schemaVersion: schemaVersion,
      title: title,
      description: description,
      uiSchema: uiSchema,
      sections: sections,
      steps: steps,
      metadata: metadata,
      additionalProperties: additionalProperties,
    );
    return parser.parse(schema.toJson());
  }
}

/// Type-specific field factories for Dart-authored schemas.
abstract final class SkyloomField {
  /// Creates a single-line text field.
  static FieldSchema text({
    required String key,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    List<String> dependsOn = const [],
    DependencySchema dependency = const DependencySchema(),
    AsyncValidationSchema? asyncValidation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.text,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    dependsOn: dependsOn,
    dependency: dependency,
    asyncValidation: asyncValidation,
    metadata: metadata,
  );

  /// Creates an email-address field.
  static FieldSchema email({
    required String key,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    AsyncValidationSchema? asyncValidation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.email,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    asyncValidation: asyncValidation,
    metadata: metadata,
  );

  /// Creates an obscured password field.
  static FieldSchema password({
    required String key,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.password,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    metadata: metadata,
  );

  /// Creates a numeric field.
  static FieldSchema number({
    required String key,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.number,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    metadata: metadata,
  );

  /// Creates a multi-line text field.
  static FieldSchema textarea({
    required String key,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.textarea,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    metadata: metadata,
  );

  /// Creates a boolean checkbox field.
  static FieldSchema checkbox({
    required String key,
    String? label,
    String? description,
    bool? defaultValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.checkbox,
    label: label,
    description: description,
    defaultValue: defaultValue ?? _unsetSchemaValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    metadata: metadata,
  );

  /// Creates a boolean switch field.
  static FieldSchema switchField({
    required String key,
    String? label,
    String? description,
    bool? defaultValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.switchField,
    label: label,
    description: description,
    defaultValue: defaultValue ?? _unsetSchemaValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    metadata: metadata,
  );

  /// Creates an ISO-date field rendered with a calendar picker.
  static FieldSchema date({
    required String key,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    String? defaultValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    List<String> dependsOn = const [],
    DependencySchema dependency = const DependencySchema(),
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.date,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue ?? _unsetSchemaValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    dependsOn: dependsOn,
    dependency: dependency,
    metadata: metadata,
  );

  /// Creates a selection field with static or asynchronously loaded options.
  static FieldSchema select({
    required String key,
    List<FieldOption> options = const [],
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    List<String> dependsOn = const [],
    DependencySchema dependency = const DependencySchema(),
    DataSourceSchema? dataSource,
    AsyncValidationSchema? asyncValidation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.select,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    options: options,
    dependsOn: dependsOn,
    dependency: dependency,
    dataSource: dataSource,
    asyncValidation: asyncValidation,
    metadata: metadata,
  );

  /// Creates a single-choice radio group.
  static FieldSchema radio({
    required String key,
    required List<FieldOption> options,
    String? label,
    String? description,
    String? helperText,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.radio,
    label: label,
    description: description,
    helperText: helperText,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    options: options,
    metadata: metadata,
  );

  /// Creates a choice-chip field.
  static FieldSchema chip({
    required String key,
    required List<FieldOption> options,
    String? label,
    String? description,
    String? helperText,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.chip,
    label: label,
    description: description,
    helperText: helperText,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    options: options,
    metadata: metadata,
  );

  /// Creates a nested object field containing [fields].
  static FieldSchema object({
    required String key,
    required List<FieldSchema> fields,
    String? label,
    String? description,
    String? helperText,
    Map<String, Object?>? defaultValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
    bool includeKey = true,
  }) => _basic(
    key: key,
    type: FormType.object,
    label: label,
    description: description,
    helperText: helperText,
    defaultValue: defaultValue ?? _unsetSchemaValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    fields: fields,
    metadata: metadata,
    includeKey: includeKey,
  );

  /// Creates a repeatable array whose entries follow [items].
  static FieldSchema array({
    required String key,
    required FieldSchema items,
    String? label,
    String? description,
    String? helperText,
    List<Object?>? defaultValue,
    int? minItems,
    int? maxItems,
    Object? defaultItem = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
    bool includeKey = true,
  }) => _basic(
    key: key,
    type: FormType.array,
    label: label,
    description: description,
    helperText: helperText,
    defaultValue: defaultValue ?? _unsetSchemaValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    items: items,
    minItems: minItems,
    maxItems: maxItems,
    defaultItem: defaultItem,
    metadata: metadata,
    includeKey: includeKey,
  );

  /// Creates a provider-neutral file upload field.
  static FieldSchema file({
    required String key,
    required FileUploadSchema upload,
    String? label,
    String? description,
    String? helperText,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
  }) => _basic(
    key: key,
    type: FormType.file,
    label: label,
    description: description,
    helperText: helperText,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    validation: validation,
    fileUpload: upload,
    metadata: metadata,
  );

  /// Creates a field rendered by an application-defined [type].
  static FieldSchema custom({
    required String key,
    required String type,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    List<FieldOption>? options,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
    Map<String, Object?> properties = const {},
  }) => _basic(
    key: key,
    type: type,
    label: label,
    description: description,
    helperText: helperText,
    placeholder: placeholder,
    defaultValue: defaultValue,
    required: required,
    disabled: disabled,
    readOnly: readOnly,
    hidden: hidden,
    options: options,
    validation: validation,
    metadata: metadata,
    additionalProperties: properties,
  );

  static FieldSchema _basic({
    required String key,
    required String type,
    String? label,
    String? description,
    String? helperText,
    String? placeholder,
    Object? defaultValue = _unsetSchemaValue,
    bool required = false,
    bool disabled = false,
    bool readOnly = false,
    bool hidden = false,
    List<FieldOption>? options,
    List<FieldSchema>? fields,
    FieldSchema? items,
    int? minItems,
    int? maxItems,
    Object? defaultItem = _unsetSchemaValue,
    List<String> dependsOn = const [],
    DependencySchema dependency = const DependencySchema(),
    DataSourceSchema? dataSource,
    AsyncValidationSchema? asyncValidation,
    FileUploadSchema? fileUpload,
    ValidationSchema? validation,
    Map<String, Object?> metadata = const {},
    Map<String, Object?> additionalProperties = const {},
    bool includeKey = true,
  }) {
    final hasDefault = !identical(defaultValue, _unsetSchemaValue);
    final hasDefaultItem = !identical(defaultItem, _unsetSchemaValue);
    return FieldSchema(
      key: key,
      type: type,
      label: label,
      description: description,
      helperText: helperText,
      placeholder: placeholder,
      defaultValue: hasDefault ? defaultValue : null,
      hasDefaultValue: hasDefault,
      required: required,
      disabled: disabled,
      readOnly: readOnly,
      hidden: hidden,
      hasExplicitKey: includeKey,
      options: options,
      fields: fields,
      items: items,
      minItems: minItems,
      maxItems: maxItems,
      defaultItem: hasDefaultItem ? defaultItem : null,
      hasDefaultItem: hasDefaultItem,
      dependsOn: dependsOn,
      dependency: dependency,
      dataSource: dataSource,
      asyncValidation: asyncValidation,
      fileUpload: fileUpload,
      validation: validation,
      metadata: metadata,
      additionalProperties: additionalProperties,
    );
  }
}

/// Named, typed construction of built-in validation rules.
abstract final class SkyloomValidation {
  /// Builds validation rules from named Dart parameters.
  ///
  /// Entries in [messages] override localized defaults for matching rules.
  /// [additionalRules] preserves application-defined validation extensions.
  static ValidationSchema rules({
    bool required = false,
    int? minLength,
    int? maxLength,
    num? min,
    num? max,
    String? minDate,
    String? maxDate,
    bool email = false,
    bool url = false,
    String? pattern,
    String? sameAs,
    String? notSameAs,
    String? greaterThan,
    String? greaterThanOrEqual,
    String? lessThan,
    String? lessThanOrEqual,
    List<String> custom = const [],
    Map<String, String> messages = const {},
    Map<String, Object?> additionalRules = const {},
  }) {
    final result = <String, Object?>{...additionalRules};

    void add(String name, Object? value) {
      final message = messages[name];
      result[name] = message == null
          ? value
          : <String, Object?>{'value': value, 'message': message};
    }

    if (required) add(ValidationRule.required, true);
    if (minLength != null) add(ValidationRule.minLength, minLength);
    if (maxLength != null) add(ValidationRule.maxLength, maxLength);
    if (min != null) add(ValidationRule.min, min);
    if (max != null) add(ValidationRule.max, max);
    if (minDate != null) add(ValidationRule.minDate, minDate);
    if (maxDate != null) add(ValidationRule.maxDate, maxDate);
    if (email) add(ValidationRule.email, true);
    if (url) add(ValidationRule.url, true);
    if (pattern != null) add(ValidationRule.pattern, pattern);
    if (sameAs != null) add(ValidationRule.sameAs, sameAs);
    if (notSameAs != null) add(ValidationRule.notSameAs, notSameAs);
    if (greaterThan != null) add(ValidationRule.greaterThan, greaterThan);
    if (greaterThanOrEqual != null) {
      add(ValidationRule.greaterThanOrEqual, greaterThanOrEqual);
    }
    if (lessThan != null) add(ValidationRule.lessThan, lessThan);
    if (lessThanOrEqual != null) {
      add(ValidationRule.lessThanOrEqual, lessThanOrEqual);
    }
    if (custom.isNotEmpty) add(ValidationRule.custom, custom);
    return ValidationSchema(result);
  }
}
