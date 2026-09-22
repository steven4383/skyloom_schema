/// Handling policy for schema field types without a built-in renderer.
enum SchemaUnknownFieldTypePolicy { allow, warning, error }

/// Defensive limits for local, remote, and AI-generated schemas.
final class SchemaLimits {
  const SchemaLimits({
    this.maxFields = 500,
    this.maxNestingDepth = 12,
    this.maxArrayItems = 1000,
    this.maxOptionsPerField = 1000,
    this.maxConditionDepth = 12,
    this.maxConditionNodes = 200,
  }) : assert(maxFields > 0),
       assert(maxNestingDepth > 0),
       assert(maxArrayItems > 0),
       assert(maxOptionsPerField > 0),
       assert(maxConditionDepth > 0),
       assert(maxConditionNodes > 0);

  final int maxFields;
  final int maxNestingDepth;
  final int maxArrayItems;
  final int maxOptionsPerField;
  final int maxConditionDepth;
  final int maxConditionNodes;
}
