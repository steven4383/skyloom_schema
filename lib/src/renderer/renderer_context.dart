import 'package:flutter/widgets.dart';

import '../controller/field_controller.dart';
import '../controller/form_controller.dart';
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
    required this.validateOnBlur,
  });

  final FieldSchema fieldSchema;
  final String fieldPath;
  final SkyloomFieldController fieldController;
  final SkyloomFormController formController;
  final SkyloomChildFieldBuilder buildChild;
  final bool validateOnChange;
  final bool validateOnBlur;

  Object? get value => fieldController.value;
  String? get error => fieldController.error;

  void setValue(Object? value) {
    formController.setValue(fieldPath, value);
    if (validateOnChange) {
      formController.validateField(fieldPath);
    }
  }
}
