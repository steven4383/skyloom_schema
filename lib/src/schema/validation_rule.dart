/// Built-in validation rule names for Dart-authored schemas.
abstract final class ValidationRule {
  static const String required = 'required';
  static const String minLength = 'minLength';
  static const String maxLength = 'maxLength';
  static const String min = 'min';
  static const String max = 'max';
  static const String minDate = 'minDate';
  static const String maxDate = 'maxDate';
  static const String email = 'email';
  static const String pattern = 'pattern';
  static const String regex = 'regex';
  static const String url = 'url';
  static const String sameAs = 'sameAs';
  static const String notSameAs = 'notSameAs';
  static const String greaterThan = 'greaterThan';
  static const String greaterThanOrEqual = 'greaterThanOrEqual';
  static const String lessThan = 'lessThan';
  static const String lessThanOrEqual = 'lessThanOrEqual';
  static const String custom = 'custom';
}
