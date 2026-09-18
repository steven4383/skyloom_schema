/// Configuration for a named asynchronous field validator.
final class AsyncValidationSchema {
  const AsyncValidationSchema({
    required this.handler,
    this.debounceMilliseconds = 300,
    this.cache = true,
  });

  final String handler;
  final int debounceMilliseconds;
  final bool cache;

  Map<String, Object?> toJson() => {
    'handler': handler,
    if (debounceMilliseconds != 300)
      'debounceMilliseconds': debounceMilliseconds,
    if (!cache) 'cache': false,
  };
}
