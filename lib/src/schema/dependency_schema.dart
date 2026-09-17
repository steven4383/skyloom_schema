/// Behavior applied when a field named in `dependsOn` changes.
final class DependencySchema {
  const DependencySchema({
    this.clearOnChange = false,
    this.revalidateOnChange = true,
    this.reloadDataOnChange = false,
    this.preserveValueIfValid = false,
  });

  final bool clearOnChange;
  final bool revalidateOnChange;
  final bool reloadDataOnChange;
  final bool preserveValueIfValid;

  Map<String, Object?> toJson() => <String, Object?>{
    if (clearOnChange) 'clearOnChange': true,
    if (!revalidateOnChange) 'revalidateOnChange': false,
    if (reloadDataOnChange) 'reloadDataOnChange': true,
    if (preserveValueIfValid) 'preserveValueIfValid': true,
  };
}
