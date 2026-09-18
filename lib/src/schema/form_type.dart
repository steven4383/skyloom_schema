/// Built-in field type names accepted by Skyloom schemas.
///
/// These are string constants, so they remain JSON-compatible values:
///
/// ```dart
/// {'key': 'name', 'type': FormType.text}
/// ```
abstract final class FormType {
  static const String text = 'text';
  static const String number = 'number';
  static const String email = 'email';
  static const String password = 'password';
  static const String textarea = 'textarea';
  static const String checkbox = 'checkbox';
  static const String radio = 'radio';
  static const String switchField = 'switch';
  static const String select = 'select';
  static const String date = 'date';
  static const String chip = 'chip';
  static const String object = 'object';
  static const String array = 'array';

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
    chip,
  };
}
