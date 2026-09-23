/// Built-in field type names accepted by Skyloom schemas.
///
/// These are string constants, so they remain JSON-compatible values:
///
/// ```dart
/// {'key': 'name', 'type': FormType.text}
/// ```
abstract final class FormType {
  /// Single-line text input.
  static const String text = 'text';

  /// Numeric text input.
  static const String number = 'number';

  /// Email-address input.
  static const String email = 'email';

  /// Obscured password input.
  static const String password = 'password';

  /// Multi-line text input.
  static const String textarea = 'textarea';

  /// Boolean checkbox input.
  static const String checkbox = 'checkbox';

  /// Single-choice radio group.
  static const String radio = 'radio';

  /// Boolean switch input; named differently because `switch` is reserved.
  static const String switchField = 'switch';

  /// Dropdown or asynchronously loaded selection input.
  static const String select = 'select';

  /// Calendar-backed ISO date input.
  static const String date = 'date';

  /// Application-provided single or multiple file upload.
  static const String file = 'file';

  /// Single-choice or multi-choice chip group.
  static const String chip = 'chip';

  /// Nested object containing child fields.
  static const String object = 'object';

  /// Repeatable list containing one item schema.
  static const String array = 'array';

  /// Built-in leaf field types supplied by the Material renderer registry.
  static const Set<String> basicTypes = {
    text,
    number,
    email,
    password,
    textarea,
    checkbox,
    radio,
    switchField,
    select,
    date,
    file,
    chip,
  };

  /// All built-in types, including structural object and array fields.
  static const Set<String> builtInTypes = {...basicTypes, object, array};
}
