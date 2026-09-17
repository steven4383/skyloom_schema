import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../engine/condition_engine.dart';
import '../engine/validation_engine.dart';
import '../schema/dependency_schema.dart';
import '../schema/field_schema.dart';
import '../schema/form_schema.dart';
import '../schema/form_type.dart';
import '../schema/validation_rule.dart';
import '../utils/json_value_utils.dart';
import '../utils/path_utils.dart';
import 'field_controller.dart';

const Object _unsetArrayItem = Object();

typedef SkyloomSubmitCallback =
    FutureOr<void> Function(Map<String, Object?> values);

typedef SkyloomValidator =
    String? Function(Object? value, SkyloomValidatorContext context);

typedef SkyloomDependencyCallback =
    FutureOr<void> Function(SkyloomDependencyChange change);

/// Information supplied to an application-defined synchronous validator.
final class SkyloomValidatorContext {
  const SkyloomValidatorContext({
    required this.fieldSchema,
    required this.formController,
    required this.values,
  });

  final FieldSchema fieldSchema;
  final SkyloomFormController formController;
  final Map<String, Object?> values;
}

/// Describes a dependency edge activated by a source-field value change.
final class SkyloomDependencyChange {
  const SkyloomDependencyChange({
    required this.sourceKey,
    required this.dependentKey,
    required this.configuration,
    required this.formController,
  });

  final String sourceKey;
  final String dependentKey;
  final DependencySchema configuration;
  final SkyloomFormController formController;
}

/// Coordinates recursive field state, values, validation, and dependencies.
final class SkyloomFormController extends ChangeNotifier {
  SkyloomFormController({
    required this.schema,
    Map<String, Object?> initialValues = const {},
    this.validationEngine = const ValidationEngine(),
    this.conditionEngine = const ConditionEngine(),
    Map<String, SkyloomValidator> validators = const {},
    this.onDependencyChanged,
  }) : _validators = Map<String, SkyloomValidator>.unmodifiable(validators) {
    _buildDefaultValues(schema.fields);
    _registerFields(schema.fields, initialValues);
    _buildDependencyGraph();
    _captureValueSnapshots();
    _applyConditions();
  }

  final FormSchema schema;
  final ValidationEngine validationEngine;
  final ConditionEngine conditionEngine;
  final SkyloomDependencyCallback? onDependencyChanged;

  Map<String, SkyloomValidator> _validators;
  final Map<String, SkyloomFieldController> _fields = {};
  final Map<String, VoidCallback> _fieldListeners = {};
  final Map<String, List<String>> _dependents = {};
  final Map<String, String> _valueSnapshots = {};
  final Map<String, Object?> _defaultValues = {};

  bool _submitting = false;
  bool _submitted = false;
  bool _loading = false;
  bool _disposed = false;
  bool _applyingConditions = false;
  int _batchDepth = 0;
  bool _batchNotificationPending = false;

  Map<String, SkyloomValidator> get validators => _validators;

  Map<String, SkyloomFieldController> get fields =>
      Map<String, SkyloomFieldController>.unmodifiable(_fields);

  /// Returns a fresh, mutable, JSON-compatible value tree.
  Map<String, Object?> get values {
    final result = <String, Object?>{};

    // Create structural objects before inserting their descendant leaves.
    final objects =
        _fields.values
            .where((field) => field.schema.type == FormType.object)
            .toList()
          ..sort(
            (left, right) =>
                _pathDepth(left.key).compareTo(_pathDepth(right.key)),
          );
    for (final field in objects) {
      PathUtils.setValue(result, field.key, <String, Object?>{});
    }

    for (final field in _fields.values) {
      if (field.schema.type == FormType.object) continue;
      PathUtils.setValue(result, field.key, thawJsonValue(field.value));
    }
    return result;
  }

  Object? value(String key) {
    final target = field(key);
    if (target.schema.type == FormType.object) {
      return PathUtils.getValue(values, key);
    }
    return target.value;
  }

  SkyloomFieldController field(String key) {
    final controller = _fields[key];
    if (controller == null) {
      throw ArgumentError.value(key, 'key', 'Unknown schema field.');
    }
    return controller;
  }

  bool get valid => _fields.values.every((field) => field.valid);
  bool get invalid => !valid;
  bool get dirty => _fields.values.any((field) => field.dirty);
  bool get pristine => !dirty;
  bool get touched => _fields.values.any((field) => field.touched);
  bool get submitting => _submitting;
  bool get submitted => _submitted;
  bool get loading => _loading || _fields.values.any((field) => field.loading);

  Map<String, String> get errors => <String, String>{
    for (final field in _fields.values)
      if (field.error != null) field.key: field.error!,
  };

  void setValue(String key, Object? value, {bool markTouched = true}) {
    final target = field(key);
    if (target.schema.type == FormType.object) {
      if (value != null && value is! Map<Object?, Object?>) {
        throw ArgumentError.value(
          value,
          'value',
          'Object fields require a map.',
        );
      }
      final patch = <String, Object?>{};
      PathUtils.setValue(patch, key, value);
      _runBatch(() {
        for (final descendant in _descendantLeaves(key)) {
          descendant.setValue(
            value != null && PathUtils.contains(patch, descendant.key)
                ? PathUtils.getValue(patch, descendant.key)
                : null,
            markTouched: markTouched,
          );
        }
      });
      return;
    }
    target.setValue(value, markTouched: markTouched);
  }

  /// Replaces all leaf and array values. Missing fields are cleared.
  void setValues(Map<String, Object?> newValues, {bool markTouched = true}) {
    _runBatch(() {
      for (final target in _leafFields) {
        target.setValue(
          PathUtils.contains(newValues, target.key)
              ? PathUtils.getValue(newValues, target.key)
              : null,
          markTouched: markTouched,
        );
      }
    });
  }

  /// Updates only leaf and array fields present in [newValues].
  void patchValues(Map<String, Object?> newValues, {bool markTouched = true}) {
    _runBatch(() {
      for (final target in _leafFields) {
        if (PathUtils.contains(newValues, target.key)) {
          target.setValue(
            PathUtils.getValue(newValues, target.key),
            markTouched: markTouched,
          );
        }
      }
    });
  }

  bool validateField(String key) {
    final target = field(key);
    if (!target.visible || !target.enabled) {
      target.clearError();
      return true;
    }

    final actualValue = value(key);
    var error = validationEngine.validateField(
      target.schema,
      actualValue,
      values,
      requiredOverride: target.required,
    );
    if (error == null && target.schema.type == FormType.array) {
      error = _validateArrayItems(target.schema, actualValue, key);
    }
    final customError = error == null
        ? _runCustomValidators(target, actualValue)
        : null;
    target.setError(error ?? customError);
    return error == null && customError == null;
  }

  bool validate() {
    var result = true;
    _runBatch(() {
      for (final target in _fields.values) {
        if (!validateField(target.key)) result = false;
      }
    });
    return result;
  }

  void setError(String key, String error) => field(key).setError(error);

  void setErrors(Map<String, String> newErrors) {
    _runBatch(() {
      for (final entry in newErrors.entries) {
        setError(entry.key, entry.value);
      }
    });
  }

  void clearError(String key) => field(key).clearError();

  void clearErrors() {
    _runBatch(() {
      for (final target in _fields.values) {
        target.clearError();
      }
    });
  }

  void setLoading(bool loading) {
    if (_loading == loading) return;
    _loading = loading;
    _markChanged();
  }

  void setValidators(Map<String, SkyloomValidator> validators) {
    _validators = Map<String, SkyloomValidator>.unmodifiable(validators);
  }

  void markAllTouched() {
    _runBatch(() {
      for (final target in _fields.values) {
        target.markTouched();
      }
    });
  }

  /// Replaces initial and current values, resetting dirty and touched state.
  void setInitialValues(Map<String, Object?> newValues) {
    _runBatch(() {
      for (final target in _leafFields) {
        final initialValue = PathUtils.contains(newValues, target.key)
            ? PathUtils.getValue(newValues, target.key)
            : PathUtils.contains(_defaultValues, target.key)
            ? PathUtils.getValue(_defaultValues, target.key)
            : null;
        target.setInitialValue(initialValue);
      }
      if (_submitted) {
        _submitted = false;
        _markChanged();
      }
      _captureValueSnapshots();
    });
  }

  void reset() {
    _runBatch(() {
      for (final target in _fields.values) {
        target.reset();
      }
      if (_submitted) {
        _submitted = false;
        _markChanged();
      }
      _captureValueSnapshots();
    });
  }

  void resetToInitial() => reset();

  void clear() {
    _runBatch(() {
      for (final target in _fields.values) {
        target.clear();
      }
      if (_submitted) {
        _submitted = false;
        _markChanged();
      }
      _captureValueSnapshots();
    });
  }

  Future<bool> submit([SkyloomSubmitCallback? onSubmit]) {
    return _submit(onSubmit, shouldValidate: true);
  }

  Future<bool> submitWithoutValidation([SkyloomSubmitCallback? onSubmit]) {
    return _submit(onSubmit, shouldValidate: false);
  }

  Future<bool> _submit(
    SkyloomSubmitCallback? onSubmit, {
    required bool shouldValidate,
  }) async {
    markAllTouched();
    if (shouldValidate && !validate()) return false;
    _submitting = true;
    notifyListeners();
    try {
      await onSubmit?.call(values);
      _submitted = true;
      return true;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Map<String, Object?> toJson() => values;

  void loadJson(Map<String, Object?> newValues) => setInitialValues(newValues);

  /// Adds an item to an array field. Returns `false` at `maxItems`.
  bool addArrayItem(String key, [Object? item = _unsetArrayItem]) {
    final target = _arrayField(key);
    final current = _mutableArray(target.value);
    final maxItems = target.schema.maxItems;
    if (maxItems != null && current.length >= maxItems) return false;
    current.add(
      identical(item, _unsetArrayItem)
          ? _defaultItemFor(target.schema)
          : thawJsonValue(item),
    );
    target.setValue(current);
    return true;
  }

  /// Removes an array item. Returns `false` at `minItems` or for a bad index.
  bool removeArrayItem(String key, int index) {
    final target = _arrayField(key);
    final current = _mutableArray(target.value);
    if (index < 0 || index >= current.length) return false;
    if (current.length <= (target.schema.minItems ?? 0)) return false;
    current.removeAt(index);
    target.setValue(current);
    return true;
  }

  bool duplicateArrayItem(String key, int index) {
    final target = _arrayField(key);
    final current = _mutableArray(target.value);
    if (index < 0 || index >= current.length) return false;
    final maxItems = target.schema.maxItems;
    if (maxItems != null && current.length >= maxItems) return false;
    current.insert(index + 1, thawJsonValue(current[index]));
    target.setValue(current);
    return true;
  }

  bool reorderArrayItem(String key, int oldIndex, int newIndex) {
    final target = _arrayField(key);
    final current = _mutableArray(target.value);
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length) {
      return false;
    }
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    target.setValue(current);
    return true;
  }

  void _buildDefaultValues(
    List<FieldSchema> schemas, {
    String parentPath = '',
  }) {
    for (final field in schemas) {
      final path = _joinPath(parentPath, field.key);
      if (field.type == FormType.object) {
        final objectDefault =
            field.hasDefaultValue && field.defaultValue is Map<Object?, Object?>
            ? thawJsonValue(field.defaultValue)
            : <String, Object?>{};
        PathUtils.setValue(_defaultValues, path, objectDefault);
        _buildDefaultValues(field.fields ?? const [], parentPath: path);
      } else if (field.type == FormType.array) {
        final arrayDefault = field.hasDefaultValue
            ? thawJsonValue(field.defaultValue)
            : <Object?>[
                for (var index = 0; index < (field.minItems ?? 0); index++)
                  _defaultItemFor(field),
              ];
        PathUtils.setValue(_defaultValues, path, arrayDefault);
      } else if (field.hasDefaultValue) {
        PathUtils.setValue(
          _defaultValues,
          path,
          thawJsonValue(field.defaultValue),
        );
      }
    }
  }

  void _registerFields(
    List<FieldSchema> schemas,
    Map<String, Object?> initialValues, {
    String parentPath = '',
  }) {
    for (final fieldSchema in schemas) {
      final path = _joinPath(parentPath, fieldSchema.key);
      if (_fields.containsKey(path)) {
        throw ArgumentError('Field path "$path" is duplicated.');
      }
      final initialValue = PathUtils.contains(initialValues, path)
          ? PathUtils.getValue(initialValues, path)
          : PathUtils.contains(_defaultValues, path)
          ? PathUtils.getValue(_defaultValues, path)
          : fieldSchema.type == FormType.array
          ? <Object?>[]
          : fieldSchema.type == FormType.object
          ? <String, Object?>{}
          : null;
      final target = SkyloomFieldController(
        schema: fieldSchema,
        key: path,
        initialValue: initialValue,
      );
      void listener() => _handleFieldChanged(path);
      target.addListener(listener);
      _fields[path] = target;
      _fieldListeners[path] = listener;

      if (fieldSchema.type == FormType.object) {
        _registerFields(
          fieldSchema.fields ?? const [],
          initialValues,
          parentPath: path,
        );
      }
    }
  }

  void _buildDependencyGraph() {
    for (final target in _fields.values) {
      for (final declaredSource in target.schema.dependsOn) {
        final source = _resolveDependencyPath(target.key, declaredSource);
        if (!_fields.containsKey(source)) {
          throw ArgumentError(
            'Field "${target.key}" depends on unknown field "$declaredSource".',
          );
        }
        _dependents.putIfAbsent(source, () => []).add(target.key);
      }
    }
    _assertDependencyGraphIsAcyclic();
  }

  String _resolveDependencyPath(String dependent, String source) {
    if (_fields.containsKey(source)) return source;
    final separator = dependent.lastIndexOf('.');
    if (separator >= 0) {
      final relative = '${dependent.substring(0, separator)}.$source';
      if (_fields.containsKey(relative)) return relative;
    }
    return source;
  }

  void _assertDependencyGraphIsAcyclic() {
    final visiting = <String>{};
    final visited = <String>{};

    void visit(String key) {
      if (visiting.contains(key)) {
        throw ArgumentError('Circular field dependency detected at "$key".');
      }
      if (!visited.add(key)) return;
      visiting.add(key);
      for (final dependent in _dependents[key] ?? const <String>[]) {
        visit(dependent);
      }
      visiting.remove(key);
    }

    for (final key in _fields.keys) {
      visit(key);
    }
  }

  void _captureValueSnapshots() {
    for (final key in _fields.keys) {
      _valueSnapshots[key] = jsonEncode(value(key));
    }
  }

  void _handleFieldChanged(String key) {
    if (_disposed) return;
    _runBatch(() {
      final changedValueKeys = <String>[];
      for (final candidate in <String>{key, ..._objectAncestors(key)}) {
        final encoded = jsonEncode(value(candidate));
        if (_valueSnapshots[candidate] != encoded) {
          _valueSnapshots[candidate] = encoded;
          changedValueKeys.add(candidate);
        }
      }
      for (final changedKey in changedValueKeys) {
        _processDependencies(changedKey);
      }
      if (!_applyingConditions) _applyConditions();
      _markChanged();
    });
  }

  void _processDependencies(String sourceKey) {
    for (final dependentKey in _dependents[sourceKey] ?? const <String>[]) {
      final dependent = field(dependentKey);
      final configuration = dependent.schema.dependency;

      if (configuration.clearOnChange) {
        final preserve =
            configuration.preserveValueIfValid &&
            _isValueValid(dependent, value(dependentKey));
        if (!preserve) {
          setValue(
            dependentKey,
            dependent.schema.type == FormType.array ? <Object?>[] : null,
            markTouched: false,
          );
        }
      }
      if (configuration.revalidateOnChange) {
        validateField(dependentKey);
      }
      onDependencyChanged?.call(
        SkyloomDependencyChange(
          sourceKey: sourceKey,
          dependentKey: dependentKey,
          configuration: configuration,
          formController: this,
        ),
      );
    }
  }

  bool _isValueValid(SkyloomFieldController target, Object? actualValue) {
    return validationEngine.validateField(
          target.schema,
          actualValue,
          values,
          requiredOverride: target.required,
        ) ==
        null;
  }

  String? _runCustomValidators(
    SkyloomFieldController target,
    Object? actualValue,
  ) {
    Object? configuration =
        target.schema.validation?.rules[ValidationRule.custom];
    if (configuration is Map<String, Object?>) {
      configuration = configuration['value'];
    }
    final names = switch (configuration) {
      String name => <String>[name],
      List<Object?> items => items.whereType<String>().toList(),
      _ => const <String>[],
    };
    if (names.isEmpty) return null;

    final context = SkyloomValidatorContext(
      fieldSchema: target.schema,
      formController: this,
      values: values,
    );
    for (final name in names) {
      final validator = validators[name];
      if (validator == null) return 'No validator is registered for "$name".';
      final error = validator(actualValue, context);
      if (error != null) return error;
    }
    return null;
  }

  String? _validateArrayItems(
    FieldSchema arraySchema,
    Object? value,
    String path,
  ) {
    if (value is! List<Object?> || arraySchema.items == null) return null;
    for (var index = 0; index < value.length; index++) {
      final error = _validateItemSchema(
        arraySchema.items!,
        value[index],
        '$path[$index]',
      );
      if (error != null) return error;
    }
    return null;
  }

  String? _validateItemSchema(
    FieldSchema itemSchema,
    Object? itemValue,
    String path,
  ) {
    final directError = validationEngine.validateField(
      itemSchema,
      itemValue,
      values,
    );
    if (directError != null) return '$path: $directError';

    if (itemSchema.type == FormType.object) {
      if (itemValue is! Map<Object?, Object?>) {
        return '$path must be an object.';
      }
      for (final child in itemSchema.fields ?? const <FieldSchema>[]) {
        final childValue = PathUtils.getValue(itemValue, child.key);
        final error = _validateItemSchema(
          child,
          childValue,
          '$path.${child.key}',
        );
        if (error != null) return error;
      }
    } else if (itemSchema.type == FormType.array) {
      return _validateArrayItems(itemSchema, itemValue, path);
    }
    return null;
  }

  void _applyConditions() {
    _applyingConditions = true;
    try {
      final currentValues = values;
      for (final target in _fields.values) {
        final properties = target.schema.additionalProperties;

        var visible = !target.schema.hidden;
        if (properties.containsKey('visibleWhen')) {
          visible =
              visible &&
              conditionEngine.evaluate(
                properties['visibleWhen'],
                currentValues,
              );
        }
        if (properties.containsKey('hiddenWhen')) {
          visible =
              visible &&
              !conditionEngine.evaluate(
                properties['hiddenWhen'],
                currentValues,
              );
        }

        var enabled = !target.schema.disabled;
        if (properties.containsKey('enabledWhen')) {
          enabled =
              enabled &&
              conditionEngine.evaluate(
                properties['enabledWhen'],
                currentValues,
              );
        }
        if (properties.containsKey('disabledWhen')) {
          enabled =
              enabled &&
              !conditionEngine.evaluate(
                properties['disabledWhen'],
                currentValues,
              );
        }

        final required =
            target.schema.required ||
            (properties.containsKey('requiredWhen') &&
                conditionEngine.evaluate(
                  properties['requiredWhen'],
                  currentValues,
                ));
        final readOnly =
            target.schema.readOnly ||
            (properties.containsKey('readOnlyWhen') &&
                conditionEngine.evaluate(
                  properties['readOnlyWhen'],
                  currentValues,
                ));

        target
          ..setVisible(visible)
          ..setEnabled(enabled)
          ..setRequired(required)
          ..setReadOnly(readOnly);
      }
    } finally {
      _applyingConditions = false;
    }
  }

  SkyloomFieldController _arrayField(String key) {
    final target = field(key);
    if (target.schema.type != FormType.array) {
      throw ArgumentError.value(key, 'key', 'Field is not an array.');
    }
    return target;
  }

  List<Object?> _mutableArray(Object? value) {
    if (value == null) return <Object?>[];
    if (value is! List<Object?>) {
      throw StateError('Array field value is not a list.');
    }
    return thawJsonValue(value)! as List<Object?>;
  }

  Object? _defaultItemFor(FieldSchema arraySchema) {
    if (arraySchema.hasDefaultItem) {
      return thawJsonValue(arraySchema.defaultItem);
    }
    final item = arraySchema.items;
    if (item == null) return null;
    if (item.hasDefaultValue) return thawJsonValue(item.defaultValue);
    if (item.type == FormType.object) {
      final result = <String, Object?>{};
      for (final child in item.fields ?? const <FieldSchema>[]) {
        PathUtils.setValue(result, child.key, _defaultValueForSchema(child));
      }
      return result;
    }
    if (item.type == FormType.array) return _defaultValueForSchema(item);
    return null;
  }

  Object? _defaultValueForSchema(FieldSchema schema) {
    if (schema.hasDefaultValue) return thawJsonValue(schema.defaultValue);
    if (schema.type == FormType.object) {
      final result = <String, Object?>{};
      for (final child in schema.fields ?? const <FieldSchema>[]) {
        PathUtils.setValue(result, child.key, _defaultValueForSchema(child));
      }
      return result;
    }
    if (schema.type == FormType.array) {
      return <Object?>[
        for (var index = 0; index < (schema.minItems ?? 0); index++)
          _defaultItemFor(schema),
      ];
    }
    return null;
  }

  Iterable<SkyloomFieldController> get _leafFields =>
      _fields.values.where((field) => field.schema.type != FormType.object);

  Iterable<SkyloomFieldController> _descendantLeaves(String parent) =>
      _leafFields.where((field) => field.key.startsWith('$parent.'));

  Iterable<String> _objectAncestors(String key) sync* {
    var separator = key.lastIndexOf('.');
    while (separator >= 0) {
      final candidate = key.substring(0, separator);
      if (_fields[candidate]?.schema.type == FormType.object) yield candidate;
      separator = candidate.lastIndexOf('.');
    }
  }

  String _joinPath(String parent, String child) =>
      parent.isEmpty ? child : '$parent.$child';

  int _pathDepth(String path) => '.'.allMatches(path).length;

  void _runBatch(VoidCallback action) {
    _batchDepth++;
    try {
      action();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0 && _batchNotificationPending) {
        _batchNotificationPending = false;
        notifyListeners();
      }
    }
  }

  void _markChanged() {
    if (_batchDepth > 0) {
      _batchNotificationPending = true;
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final entry in _fields.entries) {
      entry.value
        ..removeListener(_fieldListeners[entry.key]!)
        ..dispose();
    }
    super.dispose();
  }
}
