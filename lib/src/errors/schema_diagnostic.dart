import '../schema/form_schema.dart';

enum SchemaDiagnosticSeverity { error, warning }

/// One machine-readable schema problem discovered without throwing.
final class SchemaDiagnostic {
  const SchemaDiagnostic({
    required this.code,
    required this.message,
    required this.path,
    this.severity = SchemaDiagnosticSeverity.error,
  });

  final String code;
  final String message;
  final String path;
  final SchemaDiagnosticSeverity severity;
}

/// Result of validating a schema while collecting independent problems.
final class SchemaValidationResult {
  SchemaValidationResult({
    required Iterable<SchemaDiagnostic> diagnostics,
    this.schema,
  }) : diagnostics = List<SchemaDiagnostic>.unmodifiable(diagnostics);

  final List<SchemaDiagnostic> diagnostics;
  final FormSchema? schema;

  List<SchemaDiagnostic> get errors => diagnostics
      .where((item) => item.severity == SchemaDiagnosticSeverity.error)
      .toList(growable: false);

  List<SchemaDiagnostic> get warnings => diagnostics
      .where((item) => item.severity == SchemaDiagnosticSeverity.warning)
      .toList(growable: false);

  bool get isValid => errors.isEmpty && schema != null;
}
