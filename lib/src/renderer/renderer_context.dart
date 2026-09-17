import '../controller/field_controller.dart';
import '../controller/form_controller.dart';
import '../schema/field_schema.dart';

/// State and callbacks made available to a field renderer.
final class SkyloomRendererContext {
  const SkyloomRendererContext({
    required this.fieldSchema,
    required this.fieldController,
    required this.formController,
    required this.validateOnChange,
  });

  final FieldSchema fieldSchema;
  final SkyloomFieldController fieldController;
  final SkyloomFormController formController;
  final bool validateOnChange;

  Object? get value => fieldController.value;
  String? get error => fieldController.error;

  void setValue(Object? value) {
    formController.setValue(fieldSchema.key, value);
    if (validateOnChange) {
      formController.validateField(fieldSchema.key);
    }
  }
}
