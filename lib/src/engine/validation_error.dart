/// Stable machine-readable validation error codes.
abstract final class SkyloomValidationCode {
  static const String required = 'required';
  static const String expectedObject = 'expectedObject';
  static const String expectedArray = 'expectedArray';
  static const String minItems = 'minItems';
  static const String maxItems = 'maxItems';
  static const String minLength = 'minLength';
  static const String maxLength = 'maxLength';
  static const String invalidNumber = 'invalidNumber';
  static const String min = 'min';
  static const String max = 'max';
  static const String invalidDate = 'invalidDate';
  static const String minDate = 'minDate';
  static const String maxDate = 'maxDate';
  static const String invalidEmail = 'invalidEmail';
  static const String invalidUrl = 'invalidUrl';
  static const String sameAs = 'sameAs';
  static const String notSameAs = 'notSameAs';
  static const String greaterThan = 'greaterThan';
  static const String greaterThanOrEqual = 'greaterThanOrEqual';
  static const String lessThan = 'lessThan';
  static const String lessThanOrEqual = 'lessThanOrEqual';
  static const String invalidPattern = 'invalidPattern';
  static const String custom = 'custom';
  static const String async = 'async';
  static const String server = 'server';
  static const String uploadMaxFiles = 'uploadMaxFiles';
  static const String uploadMaxBytes = 'uploadMaxBytes';
  static const String uploadInvalidType = 'uploadInvalidType';
  static const String uploadInvalidValue = 'uploadInvalidValue';
  static const String uploadHandlerMissing = 'uploadHandlerMissing';
  static const String uploadFailed = 'uploadFailed';
}

/// A validation failure with a stable code and localized display message.
final class SkyloomValidationError {
  SkyloomValidationError({
    required this.code,
    required this.message,
    Map<String, Object?> arguments = const {},
  }) : arguments = Map<String, Object?>.unmodifiable(arguments);

  final String code;
  final String message;
  final Map<String, Object?> arguments;
}
