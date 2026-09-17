import 'package:flutter/foundation.dart';

import '../schema/field_schema.dart';
import '../utils/json_value_utils.dart';

/// Reactive state for one schema field.
final class SkyloomFieldController extends ChangeNotifier {
  SkyloomFieldController({
    required this.schema,
    String? key,
    Object? initialValue,
  }) : _key = key ?? schema.key,
       _initialValue = freezeJsonValue(initialValue, path: r'$.initialValue'),
       _value = freezeJsonValue(initialValue, path: r'$.value'),
       _visible = !schema.hidden,
       _enabled = !schema.disabled,
       _readOnly = schema.readOnly,
       _required = schema.required;

  final FieldSchema schema;
  final String _key;
  Object? _initialValue;
  Object? _value;
  String? _error;
  bool _touched = false;
  bool _focused = false;
  bool _loading = false;
  bool _visible;
  bool _enabled;
  bool _readOnly;
  bool _required;

  String get key => _key;
  Object? get value => _value;
  Object? get initialValue => _initialValue;
  String? get error => _error;
  bool get dirty => !_deepEquals(_value, _initialValue);
  bool get pristine => !dirty;
  bool get touched => _touched;
  bool get untouched => !touched;
  bool get focused => _focused;
  bool get loading => _loading;
  bool get visible => _visible;
  bool get hidden => !visible;
  bool get enabled => _enabled;
  bool get disabled => !enabled;
  bool get readOnly => _readOnly;
  bool get required => _required;
  bool get valid => _error == null;
  bool get invalid => !valid;

  /// Updates the field value and optionally marks it as touched.
  void setValue(Object? value, {bool markTouched = true}) {
    final nextValue = freezeJsonValue(value, path: r'$.value');
    final valueChanged = !_deepEquals(_value, nextValue);
    final touchedChanged = markTouched && !_touched;
    if (!valueChanged && !touchedChanged) {
      return;
    }
    _value = nextValue;
    if (markTouched) {
      _touched = true;
    }
    notifyListeners();
  }

  void markTouched() {
    if (_touched) return;
    _touched = true;
    notifyListeners();
  }

  void setFocused(bool focused) {
    if (_focused == focused) return;
    _focused = focused;
    if (focused) {
      _touched = true;
    }
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_loading == loading) return;
    _loading = loading;
    notifyListeners();
  }

  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  void setReadOnly(bool readOnly) {
    if (_readOnly == readOnly) return;
    _readOnly = readOnly;
    notifyListeners();
  }

  void setRequired(bool required) {
    if (_required == required) return;
    _required = required;
    notifyListeners();
  }

  void setError(String? error) {
    if (_error == error) return;
    _error = error;
    notifyListeners();
  }

  void clearError() => setError(null);

  /// Replaces the dirty-tracking baseline, typically with edit-form data.
  void setInitialValue(Object? value, {bool updateValue = true}) {
    final nextValue = freezeJsonValue(value, path: r'$.initialValue');
    final changed =
        !_deepEquals(_initialValue, nextValue) ||
        (updateValue && !_deepEquals(_value, nextValue)) ||
        _error != null ||
        _touched ||
        _focused;
    _initialValue = nextValue;
    if (updateValue) {
      _value = nextValue;
    }
    _error = null;
    _touched = false;
    _focused = false;
    if (changed) notifyListeners();
  }

  void reset() {
    final changed =
        !_deepEquals(_value, _initialValue) ||
        _error != null ||
        _touched ||
        _focused ||
        _loading;
    _value = _initialValue;
    _error = null;
    _touched = false;
    _focused = false;
    _loading = false;
    if (changed) notifyListeners();
  }

  void clear() {
    final changed =
        _value != null || _error != null || _touched || _focused || _loading;
    _value = null;
    _error = null;
    _touched = false;
    _focused = false;
    _loading = false;
    if (changed) notifyListeners();
  }
}

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is List<Object?> && right is List<Object?>) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_deepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  if (left is Map<Object?, Object?> && right is Map<Object?, Object?>) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}
