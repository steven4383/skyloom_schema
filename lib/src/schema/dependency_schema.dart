/// Behavior applied when a field named in `dependsOn` changes.
final class DependencySchema {
  /// Creates behavior for a field whose dependency value changes.
  const DependencySchema({
    this.clearOnChange = false,
    this.revalidateOnChange = true,
    this.reloadDataOnChange = false,
    this.preserveValueIfValid = false,
  });

  /// Whether the dependent field value is cleared after a source change.
  final bool clearOnChange;

  /// Whether the dependent field is revalidated after a source change.
  final bool revalidateOnChange;

  /// Whether a registered data source is reloaded after a source change.
  final bool reloadDataOnChange;

  /// Whether a still-valid value is retained when options are reloaded.
  final bool preserveValueIfValid;

  /// Converts this configuration to its JSON-compatible representation.
  Map<String, Object?> toJson() => <String, Object?>{
    if (clearOnChange) 'clearOnChange': true,
    if (!revalidateOnChange) 'revalidateOnChange': false,
    if (reloadDataOnChange) 'reloadDataOnChange': true,
    if (preserveValueIfValid) 'preserveValueIfValid': true,
  };
}
