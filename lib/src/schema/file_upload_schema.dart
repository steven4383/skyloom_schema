/// Declarative configuration for a JSON-safe file-upload field.
final class FileUploadSchema {
  FileUploadSchema({
    required String handler,
    this.multiple = false,
    List<String> accept = const [],
    int? maxBytes,
    int maxFiles = 1,
  }) : handler = _requiredHandler(handler),
       accept = List<String>.unmodifiable(_acceptedTypes(accept)),
       maxBytes = _positiveMaxBytes(maxBytes),
       maxFiles = _validMaxFiles(maxFiles, multiple);

  final String handler;
  final bool multiple;
  final List<String> accept;
  final int? maxBytes;
  final int maxFiles;

  Map<String, Object?> toJson() => <String, Object?>{
    'handler': handler,
    if (multiple) 'multiple': true,
    if (accept.isNotEmpty) 'accept': accept,
    if (maxBytes != null) 'maxBytes': maxBytes,
    'maxFiles': maxFiles,
  };
}

String _requiredHandler(String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, 'handler', 'Must not be empty.');
  }
  return value;
}

List<String> _acceptedTypes(List<String> values) {
  if (values.any((value) => value.trim().isEmpty)) {
    throw ArgumentError.value(values, 'accept', 'Entries must not be empty.');
  }
  return values;
}

int? _positiveMaxBytes(int? value) {
  if (value != null && value <= 0) {
    throw ArgumentError.value(value, 'maxBytes', 'Must be positive.');
  }
  return value;
}

int _validMaxFiles(int value, bool multiple) {
  if (value <= 0 || !multiple && value != 1) {
    throw ArgumentError.value(
      value,
      'maxFiles',
      multiple ? 'Must be positive.' : 'Must be 1 for a single upload.',
    );
  }
  return value;
}
