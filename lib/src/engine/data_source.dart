import 'dart:async';

import '../schema/field_option.dart';
import '../utils/path_utils.dart';

/// Input supplied to an application-registered data-source handler.
final class SkyloomDataSourceRequest {
  const SkyloomDataSourceRequest({
    required this.fieldKey,
    required this.search,
    required this.page,
    required this.pageSize,
    required this.dependencyValues,
    required this.formValues,
    required this.fieldMetadata,
  });

  final String fieldKey;
  final String search;
  final int page;
  final int pageSize;
  final Map<String, Object?> dependencyValues;
  final Map<String, Object?> formValues;
  final Map<String, Object?> fieldMetadata;
}

/// One page returned by a data-source handler.
final class SkyloomDataSourceResult {
  SkyloomDataSourceResult({
    required List<FieldOption> options,
    this.hasMore = false,
  }) : options = List<FieldOption>.unmodifiable(options);

  final List<FieldOption> options;
  final bool hasMore;

  /// Converts a list or `{items, hasMore}` response using mapping paths.
  factory SkyloomDataSourceResult.fromResponse(
    Object? response, {
    String labelField = 'label',
    String valueField = 'value',
    String metadataField = 'metadata',
  }) {
    if (response is SkyloomDataSourceResult) return response;
    final Object? rawItems;
    final bool hasMore;
    if (response is List<Object?>) {
      rawItems = response;
      hasMore = false;
    } else if (response is Map<Object?, Object?>) {
      rawItems = response['items'];
      hasMore = response['hasMore'] == true;
    } else {
      throw const FormatException(
        'A data source must return a list, an items response, or a result.',
      );
    }
    if (rawItems is! List<Object?>) {
      throw const FormatException('Data-source response items must be a list.');
    }
    return SkyloomDataSourceResult(
      hasMore: hasMore,
      options: [
        for (final item in rawItems)
          if (item is FieldOption)
            item
          else if (item is Map<Object?, Object?>)
            FieldOption(
              label: PathUtils.getValue(item, labelField)?.toString() ?? '',
              value: PathUtils.getValue(item, valueField),
              metadata: switch (PathUtils.getValue(item, metadataField)) {
                Map<String, Object?> metadata => metadata,
                _ => const {},
              },
            )
          else
            FieldOption(label: item.toString(), value: item),
      ],
    );
  }
}

typedef SkyloomDataSource =
    FutureOr<Object?> Function(SkyloomDataSourceRequest request);

/// Observable snapshot of an asynchronous field's option-loading state.
final class SkyloomDataSourceState {
  const SkyloomDataSourceState({
    this.options = const [],
    this.loading = false,
    this.error,
    this.search = '',
    this.page = 0,
    this.hasMore = false,
  });

  final List<FieldOption> options;
  final bool loading;
  final Object? error;
  final String search;
  final int page;
  final bool hasMore;

  SkyloomDataSourceState copyWith({
    List<FieldOption>? options,
    bool? loading,
    Object? error,
    bool clearError = false,
    String? search,
    int? page,
    bool? hasMore,
  }) => SkyloomDataSourceState(
    options: options ?? this.options,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    search: search ?? this.search,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
  );
}
