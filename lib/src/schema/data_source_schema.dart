/// Describes an application-registered asynchronous option source.
final class DataSourceSchema {
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

  final String handler;
  final bool search;
  final int pageSize;
  final int debounceMilliseconds;
  final bool cache;
  final String labelField;
  final String valueField;
  final String metadataField;

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
