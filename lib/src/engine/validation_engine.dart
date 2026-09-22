import '../schema/field_schema.dart';
import '../schema/form_type.dart';
import '../schema/validation_rule.dart';
import '../utils/path_utils.dart';
import 'file_upload.dart';
import 'skyloom_messages.dart';
import 'validation_error.dart';

/// Executes the built-in synchronous validation rules.
final class ValidationEngine {
  const ValidationEngine({this.messages = const EnglishSkyloomMessages()});

  final SkyloomMessages messages;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Returns the first validation message, or `null` when [value] is valid.
  String? validateField(
    FieldSchema field,
    Object? value,
    Map<String, Object?> formValues, {
    bool? requiredOverride,
  }) => validateFieldError(
    field,
    value,
    formValues,
    requiredOverride: requiredOverride,
  )?.message;

  /// Returns the first structured validation error, or `null` when valid.
  SkyloomValidationError? validateFieldError(
    FieldSchema field,
    Object? value,
    Map<String, Object?> formValues, {
    bool? requiredOverride,
  }) {
    final rules = field.validation?.rules ?? const <String, Object?>{};
    final label = field.label ?? field.key;

    final requiredRule = rules[ValidationRule.required];
    final isRequired =
        (requiredOverride ?? field.required) || _enabled(requiredRule);
    final isMissing =
        _isEmpty(value) || (field.type == FormType.checkbox && value == false);
    if (isRequired && isMissing) {
      return _error(SkyloomValidationCode.required, label, rule: requiredRule);
    }

    if (field.type == FormType.object && value is! Map<Object?, Object?>) {
      if (_isEmpty(value)) return null;
      return _error(SkyloomValidationCode.expectedObject, label);
    }
    if (field.type == FormType.array) {
      if (value is! List<Object?>) {
        if (_isEmpty(value)) return null;
        return _error(SkyloomValidationCode.expectedArray, label);
      }
      if (field.minItems != null && value.length < field.minItems!) {
        return _error(
          SkyloomValidationCode.minItems,
          label,
          arguments: {'limit': field.minItems},
        );
      }
      if (field.maxItems != null && value.length > field.maxItems!) {
        return _error(
          SkyloomValidationCode.maxItems,
          label,
          arguments: {'limit': field.maxItems},
        );
      }
    }

    // Optional empty values do not run the remaining validators.
    if (_isEmpty(value)) return null;

    final minLength = _numberValue(rules[ValidationRule.minLength]);
    if (minLength != null &&
        value is String &&
        value.length < minLength.toInt()) {
      return _error(
        SkyloomValidationCode.minLength,
        label,
        rule: rules[ValidationRule.minLength],
        arguments: {'limit': minLength.toInt()},
      );
    }

    final maxLength = _numberValue(rules[ValidationRule.maxLength]);
    if (maxLength != null &&
        value is String &&
        value.length > maxLength.toInt()) {
      return _error(
        SkyloomValidationCode.maxLength,
        label,
        rule: rules[ValidationRule.maxLength],
        arguments: {'limit': maxLength.toInt()},
      );
    }

    final numericValue = value is num
        ? value
        : value is String
        ? num.tryParse(value)
        : null;
    if (field.type == FormType.number && numericValue == null) {
      return _error(SkyloomValidationCode.invalidNumber, label);
    }
    final min = _numberValue(rules[ValidationRule.min]);
    if (min != null && numericValue != null && numericValue < min) {
      return _error(
        SkyloomValidationCode.min,
        label,
        rule: rules[ValidationRule.min],
        arguments: {'limit': min},
      );
    }

    final max = _numberValue(rules[ValidationRule.max]);
    if (max != null && numericValue != null && numericValue > max) {
      return _error(
        SkyloomValidationCode.max,
        label,
        rule: rules[ValidationRule.max],
        arguments: {'limit': max},
      );
    }

    if (field.type == FormType.date) {
      final dateValue = _dateValue(value);
      if (dateValue == null) {
        return _error(SkyloomValidationCode.invalidDate, label);
      }

      final minDateRule = rules[ValidationRule.minDate];
      final minDateText = _stringValue(minDateRule);
      final minDate = _dateValue(minDateText);
      if (minDate != null && dateValue.isBefore(minDate)) {
        return _error(
          SkyloomValidationCode.minDate,
          label,
          rule: minDateRule,
          arguments: {'limit': _formatDate(minDate)},
        );
      }

      final maxDateRule = rules[ValidationRule.maxDate];
      final maxDateText = _stringValue(maxDateRule);
      final maxDate = _dateValue(maxDateText);
      if (maxDate != null && dateValue.isAfter(maxDate)) {
        return _error(
          SkyloomValidationCode.maxDate,
          label,
          rule: maxDateRule,
          arguments: {'limit': _formatDate(maxDate)},
        );
      }
    }

    if (field.type == FormType.file) {
      final config = field.fileUpload;
      final rawFiles = config?.multiple == true
          ? value is List<Object?>
                ? value
                : null
          : value is Map<Object?, Object?>
          ? <Object?>[value]
          : null;
      final files = rawFiles
          ?.map(SkyloomUploadedFile.tryParse)
          .whereType<SkyloomUploadedFile>()
          .toList(growable: false);
      if (config == null ||
          rawFiles == null ||
          files == null ||
          files.length != rawFiles.length) {
        return _error(SkyloomValidationCode.uploadInvalidValue, label);
      }
      if (files.length > config.maxFiles) {
        return _error(
          SkyloomValidationCode.uploadMaxFiles,
          label,
          arguments: {'limit': config.maxFiles},
        );
      }
      if (config.maxBytes != null &&
          files.any(
            (file) => file.size != null && file.size! > config.maxBytes!,
          )) {
        return _error(
          SkyloomValidationCode.uploadMaxBytes,
          label,
          arguments: {'limit': config.maxBytes},
        );
      }
      if (config.accept.isNotEmpty &&
          files.any((file) => !_acceptsFile(file, config.accept))) {
        return _error(
          SkyloomValidationCode.uploadInvalidType,
          label,
          arguments: {'accept': config.accept},
        );
      }
    }

    final emailRule = rules[ValidationRule.email];
    final shouldValidateEmail =
        field.type == FormType.email || _enabled(emailRule);
    if (shouldValidateEmail &&
        (value is! String || !_emailPattern.hasMatch(value))) {
      return _error(SkyloomValidationCode.invalidEmail, label, rule: emailRule);
    }

    final urlRule = rules[ValidationRule.url];
    if (_enabled(urlRule) && !_isUrl(value)) {
      return _error(SkyloomValidationCode.invalidUrl, label, rule: urlRule);
    }

    final sameAsRule = rules[ValidationRule.sameAs];
    final sameAsPath = _stringValue(sameAsRule);
    if (sameAsPath != null &&
        !_deepEquals(value, PathUtils.getValue(formValues, sameAsPath))) {
      return _error(
        SkyloomValidationCode.sameAs,
        label,
        rule: sameAsRule,
        arguments: {'path': sameAsPath},
      );
    }

    final notSameAsRule = rules[ValidationRule.notSameAs];
    final notSameAsPath = _stringValue(notSameAsRule);
    if (notSameAsPath != null &&
        _deepEquals(value, PathUtils.getValue(formValues, notSameAsPath))) {
      return _error(
        SkyloomValidationCode.notSameAs,
        label,
        rule: notSameAsRule,
        arguments: {'path': notSameAsPath},
      );
    }

    final comparisonRules = <(String, bool Function(int))>[
      (ValidationRule.greaterThan, (comparison) => comparison > 0),
      (ValidationRule.greaterThanOrEqual, (comparison) => comparison >= 0),
      (ValidationRule.lessThan, (comparison) => comparison < 0),
      (ValidationRule.lessThanOrEqual, (comparison) => comparison <= 0),
    ];
    for (final (ruleName, predicate) in comparisonRules) {
      final rule = rules[ruleName];
      final otherPath = _stringValue(rule);
      if (otherPath == null) continue;
      final comparison = _compare(
        value,
        PathUtils.getValue(formValues, otherPath),
      );
      if (comparison == null || !predicate(comparison)) {
        return _error(
          ruleName,
          label,
          rule: rule,
          arguments: {'path': otherPath},
        );
      }
    }

    final patternRule =
        rules[ValidationRule.pattern] ?? rules[ValidationRule.regex];
    final pattern = _stringValue(patternRule);
    if (pattern != null) {
      try {
        if (value is! String || !RegExp(pattern).hasMatch(value)) {
          return _error(
            SkyloomValidationCode.invalidPattern,
            label,
            rule: patternRule,
          );
        }
      } on FormatException {
        return _error(SkyloomValidationCode.invalidPattern, label);
      }
    }

    return null;
  }

  SkyloomValidationError _error(
    String code,
    String label, {
    Object? rule,
    Map<String, Object?> arguments = const {},
  }) {
    return SkyloomValidationError(
      code: code,
      message:
          _message(rule) ??
          messages.validationMessage(code, label: label, arguments: arguments),
      arguments: arguments,
    );
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

  bool _acceptsFile(SkyloomUploadedFile file, List<String> acceptedTypes) {
    final mimeType = file.mimeType?.toLowerCase();
    final lowerName = file.name.toLowerCase();
    return acceptedTypes.any((rawPattern) {
      final pattern = rawPattern.trim().toLowerCase();
      if (pattern.isEmpty) return false;
      if (pattern.startsWith('.')) return lowerName.endsWith(pattern);
      if (pattern.endsWith('/*')) {
        final prefix = pattern.substring(0, pattern.length - 1);
        return mimeType?.startsWith(prefix) ?? false;
      }
      return mimeType == pattern;
    });
  }

  int? _compare(Object? left, Object? right) {
    if (left is num && right is num) return left.compareTo(right);
    if (left is String && right is String) {
      final leftNumber = num.tryParse(left);
      final rightNumber = num.tryParse(right);
      if (leftNumber != null && rightNumber != null) {
        return leftNumber.compareTo(rightNumber);
      }
      final leftDate = DateTime.tryParse(left);
      final rightDate = DateTime.tryParse(right);
      if (leftDate != null && rightDate != null) {
        return leftDate.compareTo(rightDate);
      }
      return left.compareTo(right);
    }
    return null;
  }

  DateTime? _dateValue(Object? value) {
    final parsed = switch (value) {
      DateTime date => date,
      String text => DateTime.tryParse(text),
      _ => null,
    };
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

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
