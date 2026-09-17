import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engine/condition_engine.dart';
import '../engine/validation_engine.dart';
import '../schema/field_schema.dart';
import '../schema/form_schema.dart';
import '../schema/validation_rule.dart';
import '../utils/json_value_utils.dart';
import '../utils/path_utils.dart';
import 'field_controller.dart';

typedef SkyloomSubmitCallback =
    FutureOr<void> Function(Map<String, Object?> values);

typedef SkyloomValidator = String? Function(
  Object? value,
  SkyloomValidatorContext context,
);

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

/// Coordinates field state, values, validation, reset, and submission.
final class SkyloomFormController extends ChangeNotifier {
  SkyloomFormController({
    required this.schema,
    Map<String, Object?> initialValues = const {},
    this.validationEngine = const ValidationEngine(),
    this.conditionEngine = const ConditionEngine(),
    this.validators = const {},
  }) {
    for (final fieldSchema in schema.fields) {
      final hasInitialValue = PathUtils.contains(
        initialValues,
        fieldSchema.key,
      );
      final initialValue = hasInitialValue
          ? PathUtils.getValue(initialValues, fieldSchema.key)
          : fieldSchema.hasDefaultValue
          ? fieldSchema.defaultValue
          : null;
      final field = SkyloomFieldController(
        schema: fieldSchema,
        initialValue: initialValue,
      );
      field.addListener(_handleFieldChanged);
      _fields[field.key] = field;
    }
    _applyConditions();
  }

  final FormSchema schema;
  final ValidationEngine validationEngine;
  final ConditionEngine conditionEngine;
  final Map<String, SkyloomValidator> validators;
  final Map<String, SkyloomFieldController> _fields = {};
  bool _submitting = false;
  bool _submitted = false;
  bool _loading = false;
  bool _disposed = false;
  bool _applyingConditions = false;
  int _batchDepth = 0;
  bool _batchNotificationPending = false;

  Map<String, SkyloomFieldController> get fields =>
      Map<String, SkyloomFieldController>.unmodifiable(_fields);

  Map<String, Object?> get values {
    final result = <String, Object?>{};
    for (final field in _fields.values) {
      PathUtils.setValue(result, field.key, thawJsonValue(field.value));
    }
    return result;
  }

  Object? value(String key) => field(key).value;

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
    field(key).setValue(value, markTouched: markTouched);
  }

  /// Replaces all field values. Missing fields are cleared.
  void setValues(Map<String, Object?> values, {bool markTouched = true}) {
    _runBatch(() {
      for (final field in _fields.values) {
        field.setValue(
          PathUtils.contains(values, field.key)
              ? PathUtils.getValue(values, field.key)
              : null,
          markTouched: markTouched,
        );
      }
    });
  }

  /// Updates only fields present in [values].
  void patchValues(Map<String, Object?> values, {bool markTouched = true}) {
    _runBatch(() {
      for (final field in _fields.values) {
        if (PathUtils.contains(values, field.key)) {
          field.setValue(
            PathUtils.getValue(values, field.key),
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
    final error = validationEngine.validateField(
      target.schema,
      target.value,
      values,
      requiredOverride: target.required,
    );
    final customError = error == null ? _runCustomValidators(target) : null;
    target.setError(error ?? customError);
    return error == null && customError == null;
  }

  bool validate() {
    var result = true;
    _runBatch(() {
      for (final field in _fields.values) {
        if (!validateField(field.key)) {
          result = false;
        }
      }
    });
    return result;
  }

  void setError(String key, String error) => field(key).setError(error);

  void setErrors(Map<String, String> errors) {
    _runBatch(() {
      for (final entry in errors.entries) {
        setError(entry.key, entry.value);
      }
    });
  }

  void clearError(String key) => field(key).clearError();

  void clearErrors() {
    _runBatch(() {
      for (final field in _fields.values) {
        field.clearError();
      }
    });
  }

  void setLoading(bool loading) {
    if (_loading == loading) return;
    _loading = loading;
    _markChanged();
  }

  void markAllTouched() {
    _runBatch(() {
      for (final field in _fields.values) {
        field.markTouched();
      }
    });
  }

  /// Replaces initial and current values, resetting dirty and touched state.
  void setInitialValues(Map<String, Object?> values) {
    _runBatch(() {
      for (final field in _fields.values) {
        final initialValue = PathUtils.contains(values, field.key)
            ? PathUtils.getValue(values, field.key)
            : field.schema.hasDefaultValue
            ? field.schema.defaultValue
            : null;
        field.setInitialValue(initialValue);
      }
      if (_submitted) {
        _submitted = false;
        _markChanged();
      }
    });
  }

  void reset() {
    _runBatch(() {
      for (final field in _fields.values) {
        field.reset();
      }
      if (_submitted) {
        _submitted = false;
        _markChanged();
      }
    });
  }

  void resetToInitial() => reset();

  void clear() {
    _runBatch(() {
      for (final field in _fields.values) {
        field.clear();
      }
      if (_submitted) {
        _submitted = false;
        _markChanged();
      }
    });
  }

  Future<bool> submit([SkyloomSubmitCallback? onSubmit]) async {
    markAllTouched();
    if (!validate()) {
      return false;
    }
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

  /// Loads edit data as the new pristine baseline.
  void loadJson(Map<String, Object?> values) => setInitialValues(values);

  void _handleFieldChanged() {
    if (_disposed) return;
    _runBatch(() {
      if (!_applyingConditions) {
        _applyConditions();
      }
      _markChanged();
    });
  }

  String? _runCustomValidators(SkyloomFieldController target) {
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

    final currentValues = values;
    final context = SkyloomValidatorContext(
      fieldSchema: target.schema,
      formController: this,
      values: currentValues,
    );
    for (final name in names) {
      final validator = validators[name];
      if (validator == null) {
        return 'No validator is registered for "$name".';
      }
      final error = validator(target.value, context);
      if (error != null) return error;
    }
    return null;
  }

  void _applyConditions() {
    _applyingConditions = true;
    try {
      final currentValues = values;
      for (final field in _fields.values) {
        final properties = field.schema.additionalProperties;

        var visible = !field.schema.hidden;
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

        var enabled = !field.schema.disabled;
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
            field.schema.required ||
            (properties.containsKey('requiredWhen') &&
                conditionEngine.evaluate(
                  properties['requiredWhen'],
                  currentValues,
                ));
        final readOnly =
            field.schema.readOnly ||
            (properties.containsKey('readOnlyWhen') &&
                conditionEngine.evaluate(
                  properties['readOnlyWhen'],
                  currentValues,
                ));

        field
          ..setVisible(visible)
          ..setEnabled(enabled)
          ..setRequired(required)
          ..setReadOnly(readOnly);
      }
    } finally {
      _applyingConditions = false;
    }
  }

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
    for (final field in _fields.values) {
      field
        ..removeListener(_handleFieldChanged)
        ..dispose();
    }
    super.dispose();
  }
}
