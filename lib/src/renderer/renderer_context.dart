import 'package:flutter/widgets.dart';

import '../controller/field_controller.dart';
import '../controller/form_controller.dart';
import '../engine/skyloom_messages.dart';
import '../schema/field_schema.dart';

typedef SkyloomChildFieldBuilder =
    Widget Function(FieldSchema fieldSchema, String parentPath);

/// State and callbacks made available to a field renderer.
final class SkyloomRendererContext {
  const SkyloomRendererContext({
    required this.fieldSchema,
    required this.fieldPath,
    required this.fieldController,
    required this.formController,
    required this.buildChild,
    required this.validateOnChange,
    this.messages = const EnglishSkyloomMessages(),
    this.revalidateInvalidOnChange = false,
    required this.validateOnBlur,
  });

  final FieldSchema fieldSchema;
  final String fieldPath;
  final SkyloomFieldController fieldController;
  final SkyloomFormController formController;
  final SkyloomChildFieldBuilder buildChild;
  final bool validateOnChange;
  final SkyloomMessages messages;

  /// Revalidates a field on edit only after it already has an error.
  ///
  /// This lets submit- and blur-mode forms remove stale errors without making
  /// every untouched field validate on each change.
  final bool revalidateInvalidOnChange;
  final bool validateOnBlur;

  Object? get value => fieldController.value;
  String? get error => fieldController.error;

  void setValue(Object? value) {
    final hadError = fieldController.error != null;
    formController.setValue(fieldPath, value);
    if (validateOnChange || (revalidateInvalidOnChange && hadError)) {
      formController.validateField(fieldPath);
      formController.scheduleAsyncValidation(fieldPath);
    }
  }
}
