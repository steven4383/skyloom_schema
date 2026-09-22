import 'validation_error.dart';

/// Resolves machine-readable validation errors into user-facing text.
abstract class SkyloomMessages {
  const SkyloomMessages();

  String validationMessage(
    String code, {
    required String label,
    Map<String, Object?> arguments = const {},
  });

  String get add => 'Add';
  String get noItems => 'No items yet.';
  String item(int number) => 'Item $number';
  String get moveItemUp => 'Move item up';
  String get moveItemDown => 'Move item down';
  String get moreItemActions => 'More item actions';
  String get duplicate => 'Duplicate';
  String get remove => 'Remove';
  String get addAnotherItemToReorder =>
      'Add another item to enable reordering.';
  String get removeNestedItem => 'Remove nested item';
  String get addNestedItem => 'Add nested item';
  String get search => 'Search';
  String get retry => 'Retry';
  String get noOptionsFound => 'No options found.';
  String get loadMore => 'Load more';
  String get close => 'Close';
  String get uploading => 'Uploading…';
  String get replaceFile => 'Replace file';
  String get chooseFiles => 'Choose files';
  String get chooseFile => 'Choose file';
  String get noSelectableDates => 'No selectable dates are available.';
  String get submit => 'Submit';
  String get next => 'Next';
  String get back => 'Back';
  String stepProgress(int current, int total) => 'Step $current of $total';
  String errorCount(int count) =>
      '$count form ${count == 1 ? 'error' : 'errors'}';
  String reviewErrors(int count) =>
      'Please review $count ${count == 1 ? 'error' : 'errors'}';
  String unsupportedField(String type, String key) =>
      'Unsupported field type $type for $key';
  String missingRenderer(String type, String key) =>
      'No renderer is registered for "$type" ($key).';
}

/// Default English validation messages.
final class EnglishSkyloomMessages extends SkyloomMessages {
  const EnglishSkyloomMessages();

  @override
  String validationMessage(
    String code, {
    required String label,
    Map<String, Object?> arguments = const {},
  }) {
    final limit = arguments['limit'];
    final path = arguments['path'];
    return switch (code) {
      SkyloomValidationCode.required => '$label is required.',
      SkyloomValidationCode.expectedObject => '$label must be an object.',
      SkyloomValidationCode.expectedArray => '$label must be an array.',
      SkyloomValidationCode.minItems =>
        '$label must contain at least $limit ${limit == 1 ? 'item' : 'items'}.',
      SkyloomValidationCode.maxItems =>
        '$label must contain at most $limit ${limit == 1 ? 'item' : 'items'}.',
      SkyloomValidationCode.minLength =>
        '$label must contain at least $limit characters.',
      SkyloomValidationCode.maxLength =>
        '$label must contain at most $limit characters.',
      SkyloomValidationCode.invalidNumber => '$label must be a valid number.',
      SkyloomValidationCode.min => '$label must be at least $limit.',
      SkyloomValidationCode.max => '$label must be at most $limit.',
      SkyloomValidationCode.invalidDate => '$label must be a valid date.',
      SkyloomValidationCode.minDate => '$label must be on or after $limit.',
      SkyloomValidationCode.maxDate => '$label must be on or before $limit.',
      SkyloomValidationCode.invalidEmail => 'Enter a valid email address.',
      SkyloomValidationCode.invalidUrl => 'Enter a valid URL.',
      SkyloomValidationCode.sameAs => '$label must match $path.',
      SkyloomValidationCode.notSameAs => '$label must not match $path.',
      SkyloomValidationCode.greaterThan => '$label must be greater than $path.',
      SkyloomValidationCode.greaterThanOrEqual =>
        '$label must be greater than or equal to $path.',
      SkyloomValidationCode.lessThan => '$label must be less than $path.',
      SkyloomValidationCode.lessThanOrEqual =>
        '$label must be less than or equal to $path.',
      SkyloomValidationCode.invalidPattern => '$label has an invalid format.',
      SkyloomValidationCode.uploadMaxFiles =>
        '$label accepts at most $limit ${limit == 1 ? 'file' : 'files'}.',
      SkyloomValidationCode.uploadMaxBytes =>
        '$label contains a file larger than $limit bytes.',
      SkyloomValidationCode.uploadInvalidType =>
        '$label contains a file type that is not accepted.',
      SkyloomValidationCode.uploadInvalidValue =>
        '$label contains an invalid uploaded-file value.',
      SkyloomValidationCode.uploadHandlerMissing =>
        'No file-upload handler is registered for $label.',
      SkyloomValidationCode.uploadFailed => '$label could not be uploaded.',
      _ => '$label is invalid.',
    };
  }
}
