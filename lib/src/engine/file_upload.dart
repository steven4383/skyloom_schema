import 'dart:async';

import '../schema/file_upload_schema.dart';
import '../utils/json_value_utils.dart';

/// A completed upload reference stored in form values instead of file bytes.
final class SkyloomUploadedFile {
  SkyloomUploadedFile({
    required String id,
    required String name,
    this.url,
    this.mimeType,
    int? size,
    Map<String, Object?> metadata = const {},
  }) : id = _requiredUploadText(id, 'id'),
       name = _requiredUploadText(name, 'name'),
       size = _uploadSize(size),
       metadata = Map<String, Object?>.unmodifiable(
         freezeJsonValue(metadata, path: r'$.uploadedFile.metadata')!
             as Map<String, Object?>,
       );

  final String id;
  final String name;
  final String? url;
  final String? mimeType;
  final int? size;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    if (url != null) 'url': url,
    if (mimeType != null) 'mimeType': mimeType,
    if (size != null) 'size': size,
    if (metadata.isNotEmpty) 'metadata': thawJsonValue(metadata),
  };

  static SkyloomUploadedFile? tryParse(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final id = value['id'];
    final name = value['name'];
    final url = value['url'];
    final mimeType = value['mimeType'];
    final size = value['size'];
    final metadata = value['metadata'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        url != null && url is! String ||
        mimeType != null && mimeType is! String ||
        size != null && size is! int ||
        metadata != null && metadata is! Map<Object?, Object?>) {
      return null;
    }
    final normalizedMetadata = <String, Object?>{};
    if (metadata is Map<Object?, Object?>) {
      for (final entry in metadata.entries) {
        if (entry.key is! String) return null;
        normalizedMetadata[entry.key! as String] = entry.value;
      }
    }
    try {
      return SkyloomUploadedFile(
        id: id,
        name: name,
        url: url as String?,
        mimeType: mimeType as String?,
        size: size as int?,
        metadata: normalizedMetadata,
      );
    } on Object {
      return null;
    }
  }
}

final class SkyloomFileUploadRequest {
  SkyloomFileUploadRequest({
    required this.fieldKey,
    required this.configuration,
    required Iterable<SkyloomUploadedFile> currentFiles,
    required Map<String, Object?> formValues,
  }) : currentFiles = List<SkyloomUploadedFile>.unmodifiable(currentFiles),
       formValues =
           freezeJsonValue(formValues, path: r'$.fileUploadRequest.formValues')!
               as Map<String, Object?>;

  final String fieldKey;
  final FileUploadSchema configuration;
  final List<SkyloomUploadedFile> currentFiles;
  final Map<String, Object?> formValues;
}

typedef SkyloomFileUploadHandler =
    FutureOr<List<SkyloomUploadedFile>> Function(
      SkyloomFileUploadRequest request,
    );

String _requiredUploadText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be empty.');
  }
  return value;
}

int? _uploadSize(int? value) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, 'size', 'Must not be negative.');
  }
  return value;
}
