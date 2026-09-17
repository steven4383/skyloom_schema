import '../errors/schema_parse_exception.dart';

/// Copies [value] into an immutable, JSON-compatible representation.
Object? freezeJsonValue(Object? value, {required String path}) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }

  if (value is num) {
    if (!value.isFinite) {
      throw SchemaParseException(
        'Numbers must be finite JSON values.',
        path: path,
      );
    }
    return value;
  }

  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(
      value.indexed.map(
        (entry) => freezeJsonValue(entry.$2, path: '$path[${entry.$1}]'),
      ),
    );
  }

  if (value is Map<Object?, Object?>) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw SchemaParseException(
          'JSON object keys must be strings.',
          path: path,
        );
      }
      result[key] = freezeJsonValue(entry.value, path: _childPath(path, key));
    }
    return Map<String, Object?>.unmodifiable(result);
  }

  throw SchemaParseException(
    'Expected a JSON-compatible value, but found ${value.runtimeType}.',
    path: path,
  );
}

/// Returns a mutable JSON copy suitable for encoding or editing.
Object? thawJsonValue(Object? value) {
  if (value is List<Object?>) {
    return value.map(thawJsonValue).toList(growable: true);
  }
  if (value is Map<String, Object?>) {
    return value.map((key, child) => MapEntry(key, thawJsonValue(child)));
  }
  return value;
}

String _childPath(String parent, String key) {
  final identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
  return identifier.hasMatch(key) ? '$parent.$key' : "$parent['$key']";
}
