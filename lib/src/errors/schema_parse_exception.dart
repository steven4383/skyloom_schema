/// Describes an invalid Skyloom form schema.
final class SchemaParseException implements Exception {
  const SchemaParseException(this.message, {this.path = r'$'});

  /// Human-readable explanation of the schema problem.
  final String message;

  /// JSON path at which the problem was found.
  final String path;

  @override
  String toString() => 'SchemaParseException at $path: $message';
}
