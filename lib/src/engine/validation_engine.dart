import '../schema/field_schema.dart';
import '../schema/form_type.dart';
import '../schema/validation_rule.dart';
import '../utils/path_utils.dart';

/// Executes the built-in synchronous validation rules.
final class ValidationEngine {
  const ValidationEngine();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Returns the first validation message, or `null` when [value] is valid.
  String? validateField(
    FieldSchema field,
    Object? value,
    Map<String, Object?> formValues,
    {bool? requiredOverride}
  ) {
    final rules = field.validation?.rules ?? const <String, Object?>{};
    final label = field.label ?? field.key;

    final requiredRule = rules[ValidationRule.required];
    final isRequired =
        (requiredOverride ?? field.required) || _enabled(requiredRule);
    final isMissing =
        _isEmpty(value) || (field.type == FormType.checkbox && value == false);
    if (isRequired && isMissing) {
      return _message(requiredRule) ?? '$label is required.';
    }

    // Optional empty values do not run the remaining validators.
    if (_isEmpty(value)) {
      return null;
    }

    final minLength = _numberValue(rules[ValidationRule.minLength]);
    if (minLength != null &&
        value is String &&
        value.length < minLength.toInt()) {
      return _message(rules[ValidationRule.minLength]) ??
          '$label must contain at least ${minLength.toInt()} characters.';
    }

    final maxLength = _numberValue(rules[ValidationRule.maxLength]);
    if (maxLength != null &&
        value is String &&
        value.length > maxLength.toInt()) {
      return _message(rules[ValidationRule.maxLength]) ??
          '$label must contain at most ${maxLength.toInt()} characters.';
    }

    final numericValue = value is num
        ? value
        : value is String
        ? num.tryParse(value)
        : null;
    if (field.type == FormType.number && numericValue == null) {
      return '$label must be a valid number.';
    }
    final min = _numberValue(rules[ValidationRule.min]);
    if (min != null && numericValue != null && numericValue < min) {
      return _message(rules[ValidationRule.min]) ??
          '$label must be at least $min.';
    }

    final max = _numberValue(rules[ValidationRule.max]);
    if (max != null && numericValue != null && numericValue > max) {
      return _message(rules[ValidationRule.max]) ??
          '$label must be at most $max.';
    }

    final emailRule = rules[ValidationRule.email];
    final shouldValidateEmail =
        field.type == FormType.email || _enabled(emailRule);
    if (shouldValidateEmail &&
        (value is! String || !_emailPattern.hasMatch(value))) {
      return _message(emailRule) ?? 'Enter a valid email address.';
    }

    final urlRule = rules[ValidationRule.url];
    if (_enabled(urlRule) && !_isUrl(value)) {
      return _message(urlRule) ?? 'Enter a valid URL.';
    }

    final sameAsRule = rules[ValidationRule.sameAs];
    final sameAsPath = _stringValue(sameAsRule);
    if (sameAsPath != null &&
        !_deepEquals(value, PathUtils.getValue(formValues, sameAsPath))) {
      return _message(sameAsRule) ?? '$label must match $sameAsPath.';
    }

    final notSameAsRule = rules[ValidationRule.notSameAs];
    final notSameAsPath = _stringValue(notSameAsRule);
    if (notSameAsPath != null &&
        _deepEquals(value, PathUtils.getValue(formValues, notSameAsPath))) {
      return _message(notSameAsRule) ?? '$label must not match $notSameAsPath.';
    }

    final patternRule =
        rules[ValidationRule.pattern] ?? rules[ValidationRule.regex];
    final pattern = _stringValue(patternRule);
    if (pattern != null) {
      try {
        if (value is! String || !RegExp(pattern).hasMatch(value)) {
          return _message(patternRule) ?? '$label has an invalid format.';
        }
      } on FormatException {
        return '$label has an invalid validation pattern.';
      }
    }

    return null;
  }

  bool _enabled(Object? rule) {
    final value = _configuredValue(rule);
    return value == true;
  }

  num? _numberValue(Object? rule) {
    final value = _configuredValue(rule);
    return value is num ? value : null;
  }

  String? _stringValue(Object? rule) {
    final value = _configuredValue(rule);
    return value is String ? value : null;
  }

  Object? _configuredValue(Object? rule) {
    if (rule is Map<String, Object?>) {
      return rule['value'];
    }
    return rule;
  }

  String? _message(Object? rule) {
    if (rule is Map<String, Object?> && rule['message'] is String) {
      return rule['message']! as String;
    }
    return null;
  }

  bool _isEmpty(Object? value) {
    return value == null ||
        value is String && value.trim().isEmpty ||
        value is Iterable<Object?> && value.isEmpty ||
        value is Map<Object?, Object?> && value.isEmpty;
  }

  bool _isUrl(Object? value) {
    if (value is! String) return false;
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
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
}
