import '../utils/json_value_utils.dart';

/// A label/value choice for fields such as select and radio.
final class FieldOption {
  FieldOption({
    required this.label,
    required Object? value,
    Map<String, Object?> metadata = const {},
    Map<String, Object?> additionalProperties = const {},
  }) : value = freezeJsonValue(value, path: r'$.option.value'),
       metadata = _freezeMap(metadata, r'$.option.metadata'),
       additionalProperties = _freezeMap(additionalProperties, r'$.option');

  final String label;
  final Object? value;
  final Map<String, Object?> metadata;

  /// Properties not interpreted by this version of the package.
  final Map<String, Object?> additionalProperties;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      ..._thawMap(additionalProperties),
      'label': label,
      'value': thawJsonValue(value),
      if (metadata.isNotEmpty) 'metadata': _thawMap(metadata),
    };
  }
}

Map<String, Object?> _freezeMap(Map<String, Object?> value, String path) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, child) => MapEntry(key, freezeJsonValue(child, path: '$path.$key')),
    ),
  );
}

Map<String, Object?> _thawMap(Map<String, Object?> value) {
  return value.map((key, child) => MapEntry(key, thawJsonValue(child)));
}
