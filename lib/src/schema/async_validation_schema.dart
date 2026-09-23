/// Configuration for a named asynchronous field validator.
final class AsyncValidationSchema {
  /// Creates configuration for the registered async validator named [handler].
  const AsyncValidationSchema({
    required this.handler,
    this.debounceMilliseconds = 300,
    this.cache = true,
  });

  /// Name used to look up the validator callback supplied to the form.
  final String handler;

  /// Delay after editing before the validator is invoked.
  final int debounceMilliseconds;

  /// Whether results may be reused for identical values and form state.
  final bool cache;

  /// Converts this configuration to its JSON-compatible representation.
  Map<String, Object?> toJson() => {
    'handler': handler,
    if (debounceMilliseconds != 300)
      'debounceMilliseconds': debounceMilliseconds,
    if (!cache) 'cache': false,
  };
}
