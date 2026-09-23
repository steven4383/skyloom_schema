/// Describes an application-registered asynchronous option source.
final class DataSourceSchema {
  /// Creates configuration for an application-registered option source.
  const DataSourceSchema({
    required this.handler,
    this.search = true,
    this.pageSize = 20,
    this.debounceMilliseconds = 300,
    this.cache = true,
    this.labelField = 'label',
    this.valueField = 'value',
    this.metadataField = 'metadata',
  });

  /// Name used to look up the data-source callback supplied to the form.
  final String handler;

  /// Whether the Material picker exposes a search input.
  final bool search;

  /// Maximum number of options requested per page.
  final int pageSize;

  /// Delay after search input before requesting options.
  final int debounceMilliseconds;

  /// Whether identical requests may reuse cached results.
  final bool cache;

  /// JSON path used to read an option label from response objects.
  final String labelField;

  /// JSON path used to read an option value from response objects.
  final String valueField;

  /// JSON path used to read optional option metadata.
  final String metadataField;

  /// Converts this configuration to its JSON-compatible representation.
  Map<String, Object?> toJson() => {
    'handler': handler,
    if (!search) 'search': false,
    if (pageSize != 20) 'pageSize': pageSize,
    if (debounceMilliseconds != 300)
      'debounceMilliseconds': debounceMilliseconds,
    if (!cache) 'cache': false,
    if (labelField != 'label' ||
        valueField != 'value' ||
        metadataField != 'metadata')
      'mapping': {
        'label': labelField,
        'value': valueField,
        'metadata': metadataField,
      },
  };
}
