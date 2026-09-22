/// A normalized field-level or form-level validation error.
final class SkyloomErrorEntry {
  const SkyloomErrorEntry({
    required this.message,
    this.fieldKey,
    this.code,
    this.arguments = const {},
  });

  /// Null for a form-level error.
  final String? fieldKey;
  final String message;
  final String? code;
  final Map<String, Object?> arguments;

  bool get isFormError => fieldKey == null;
}

/// Determines how [SkyloomFormController.applyErrors] handles unknown fields.
enum SkyloomUnknownFieldErrorPolicy {
  /// Reject the error response with an [ArgumentError].
  throwException,

  /// Convert unknown field errors into form-level errors.
  formError,

  /// Ignore unknown field errors and report them in the result.
  ignore,
}

/// Summary returned after applying backend validation errors.
final class SkyloomAppliedErrors {
  SkyloomAppliedErrors({
    required Iterable<String> appliedFields,
    required Iterable<String> unknownFields,
  }) : appliedFields = List<String>.unmodifiable(appliedFields),
       unknownFields = List<String>.unmodifiable(unknownFields);

  final List<String> appliedFields;
  final List<String> unknownFields;
}
