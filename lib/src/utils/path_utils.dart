/// Utilities for reading and updating nested JSON-compatible values.
final class PathUtils {
  const PathUtils._();

  static final RegExp _validPath = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_-]*(?:\[\d+\])*(?:\.[A-Za-z_][A-Za-z0-9_-]*(?:\[\d+\])*)*$',
  );
  static final RegExp _tokenPattern = RegExp(
    r'[A-Za-z_][A-Za-z0-9_-]*|\[(\d+)\]',
  );

  /// Gets the value at [path], or `null` when the path does not exist.
  static Object? getValue(Object? root, String path) {
    Object? current = root;
    for (final token in _tokens(path)) {
      if (token is String) {
        if (current is! Map<Object?, Object?> || !current.containsKey(token)) {
          return null;
        }
        current = current[token];
      } else {
        final index = token as int;
        if (current is! List<Object?> || index >= current.length) {
          return null;
        }
        current = current[index];
      }
    }
    return current;
  }

  /// Whether [path] exists, including when its value is explicitly `null`.
  static bool contains(Object? root, String path) {
    Object? current = root;
    for (final token in _tokens(path)) {
      if (token is String) {
        if (current is! Map<Object?, Object?> || !current.containsKey(token)) {
          return false;
        }
        current = current[token];
      } else {
        final index = token as int;
        if (current is! List<Object?> || index >= current.length) {
          return false;
        }
        current = current[index];
      }
    }
    return true;
  }

  /// Mutates [root], creating missing maps and lists needed by [path].
  static void setValue(Map<String, Object?> root, String path, Object? value) {
    final tokens = _tokens(path);
    Object current = root;
    for (var index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      final isLast = index == tokens.length - 1;
      final nextIsIndex = !isLast && tokens[index + 1] is int;

      if (token is String) {
        if (current is! Map<Object?, Object?>) {
          throw StateError('Cannot write "$path" through a non-object value.');
        }
        if (isLast) {
          current[token] = value;
          return;
        }
        final existing = current[token];
        if (existing == null) {
          final created = nextIsIndex ? <Object?>[] : <String, Object?>{};
          current[token] = created;
          current = created;
        } else {
          current = existing;
        }
      } else {
        final arrayIndex = token as int;
        if (current is! List<Object?>) {
          throw StateError('Cannot write "$path" through a non-array value.');
        }
        while (current.length <= arrayIndex) {
          current.add(null);
        }
        if (isLast) {
          current[arrayIndex] = value;
          return;
        }
        final existing = current[arrayIndex];
        if (existing == null) {
          final created = nextIsIndex ? <Object?>[] : <String, Object?>{};
          current[arrayIndex] = created;
          current = created;
        } else {
          current = existing;
        }
      }
    }
  }

  static List<Object> _tokens(String path) {
    if (!_validPath.hasMatch(path)) {
      throw ArgumentError.value(path, 'path', 'Invalid Skyloom value path.');
    }
    return <Object>[
      for (final match in _tokenPattern.allMatches(path))
        match.group(1) == null ? match.group(0)! : int.parse(match.group(1)!),
    ];
  }
}
