import '../utils/json_value_utils.dart';

/// Immutable validation rules attached to a field.
///
/// Rule interpretation belongs to the validation engine. Keeping this model
/// open allows applications to introduce custom rule names without changing
/// the schema model.
final class ValidationSchema {
  /// Creates an immutable open set of validation [rules].
  ValidationSchema(Map<String, Object?> rules)
    : rules = Map<String, Object?>.unmodifiable(
        rules.map(
          (key, value) => MapEntry(
            key,
            freezeJsonValue(value, path: r'$.validation.' + key),
          ),
        ),
      );

  /// Validation rule name to JSON-compatible configuration.
  final Map<String, Object?> rules;

  /// Returns a mutable JSON-compatible copy of the validation rules.
  Map<String, Object?> toJson() =>
      rules.map((key, value) => MapEntry(key, thawJsonValue(value)));
}
