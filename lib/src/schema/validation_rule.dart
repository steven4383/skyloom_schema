/// Built-in validation rule names for Dart-authored schemas.
abstract final class ValidationRule {
  /// Rejects missing, blank, empty, or required-false values.
  static const String required = 'required';

  /// Minimum string length.
  static const String minLength = 'minLength';

  /// Maximum string length.
  static const String maxLength = 'maxLength';

  /// Inclusive minimum numeric value.
  static const String min = 'min';

  /// Inclusive maximum numeric value.
  static const String max = 'max';

  /// Inclusive earliest ISO date.
  static const String minDate = 'minDate';

  /// Inclusive latest ISO date.
  static const String maxDate = 'maxDate';

  /// Enables email-address format validation.
  static const String email = 'email';

  /// Regular-expression pattern applied to a string value.
  static const String pattern = 'pattern';

  /// Alias for [pattern].
  static const String regex = 'regex';

  /// Enables HTTP or HTTPS URL validation.
  static const String url = 'url';

  /// Requires equality with the value at another field path.
  static const String sameAs = 'sameAs';

  /// Requires inequality with the value at another field path.
  static const String notSameAs = 'notSameAs';

  /// Requires a value greater than the value at another field path.
  static const String greaterThan = 'greaterThan';

  /// Requires a value greater than or equal to another field value.
  static const String greaterThanOrEqual = 'greaterThanOrEqual';

  /// Requires a value less than the value at another field path.
  static const String lessThan = 'lessThan';

  /// Requires a value less than or equal to another field value.
  static const String lessThanOrEqual = 'lessThanOrEqual';

  /// Names one or more application-registered synchronous validators.
  static const String custom = 'custom';
}
