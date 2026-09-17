import 'dart:convert';

import 'package:flutter/material.dart';

import '../controller/form_controller.dart';
import '../parser/schema_parser.dart';
import '../registry/renderer_registry.dart';
import '../schema/form_schema.dart';
import 'field_renderer.dart';
import 'material/material_renderers.dart';
import 'renderer_context.dart';

/// Controls how a [SkyloomForm] participates in vertical layout.
enum SkyloomFormLayout {
  /// Render only the content column. The parent owns scrolling.
  column,

  /// Wrap the form in a scroll view to prevent large-form overflow.
  scrollable,
}

/// Builds a reactive Flutter form from a parsed [FormSchema].
final class SkyloomForm extends StatefulWidget {
  const SkyloomForm({
    required this.schema,
    this.controller,
    this.initialValues = const {},
    this.onChanged,
    this.onSubmit,
    this.renderers = const {},
    this.validators = const {},
    this.validateOnChange = true,
    this.showSubmitButton = true,
    this.submitButtonLabel = 'Submit',
    this.fieldSpacing = 16,
    this.layout = SkyloomFormLayout.scrollable,
    this.padding = EdgeInsets.zero,
    this.inputDecorationTheme,
    super.key,
  });

  /// Parses [schema] and creates a form using the default Material renderers.
  factory SkyloomForm.fromJson({
    required Object? schema,
    SkyloomFormController? controller,
    Map<String, Object?> initialValues = const {},
    ValueChanged<Map<String, Object?>>? onChanged,
    SkyloomSubmitCallback? onSubmit,
    Map<String, SkyloomFieldRenderer> renderers = const {},
    Map<String, SkyloomValidator> validators = const {},
    bool validateOnChange = true,
    bool showSubmitButton = true,
    String submitButtonLabel = 'Submit',
    double fieldSpacing = 16,
    SkyloomFormLayout layout = SkyloomFormLayout.scrollable,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    InputDecorationTheme? inputDecorationTheme,
    SchemaParser parser = const SchemaParser(),
    Key? key,
  }) {
    return SkyloomForm(
      key: key,
      schema: parser.parse(schema),
      controller: controller,
      initialValues: initialValues,
      onChanged: onChanged,
      onSubmit: onSubmit,
      renderers: renderers,
      validators: validators,
      validateOnChange: validateOnChange,
      showSubmitButton: showSubmitButton,
      submitButtonLabel: submitButtonLabel,
      fieldSpacing: fieldSpacing,
      layout: layout,
      padding: padding,
      inputDecorationTheme: inputDecorationTheme,
    );
  }

  final FormSchema schema;
  final SkyloomFormController? controller;
  final Map<String, Object?> initialValues;
  final ValueChanged<Map<String, Object?>>? onChanged;
  final SkyloomSubmitCallback? onSubmit;

  /// Renderer overrides keyed by schema field type.
  final Map<String, SkyloomFieldRenderer> renderers;
  final Map<String, SkyloomValidator> validators;
  final bool validateOnChange;
  final bool showSubmitButton;
  final String submitButtonLabel;
  final double fieldSpacing;
  final SkyloomFormLayout layout;
  final EdgeInsetsGeometry padding;

  /// Optional Material input styling applied only inside this form.
  ///
  /// For outlined inputs, pass an [InputDecorationTheme] whose `border` is an
  /// [OutlineInputBorder].
  final InputDecorationTheme? inputDecorationTheme;

  @override
  State<SkyloomForm> createState() => _SkyloomFormState();
}

final class _SkyloomFormState extends State<SkyloomForm> {
  late SkyloomFormController _controller;
  late SkyloomRendererRegistry _rendererRegistry;
  late bool _ownsController;
  late String _encodedValues;

  @override
  void initState() {
    super.initState();
    _attachController();
    _rendererRegistry = MaterialSkyloomRenderers.defaults(
      overrides: widget.renderers,
    );
  }

  @override
  void didUpdateWidget(covariant SkyloomForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final schemaChanged =
        jsonEncode(oldWidget.schema.toJson()) !=
        jsonEncode(widget.schema.toJson());
    final initialValuesChanged =
        jsonEncode(oldWidget.initialValues) != jsonEncode(widget.initialValues);
    if (oldWidget.controller != widget.controller ||
        schemaChanged ||
        initialValuesChanged) {
      _detachController();
      _attachController();
    }
    if (oldWidget.renderers != widget.renderers) {
      _rendererRegistry = MaterialSkyloomRenderers.defaults(
        overrides: widget.renderers,
      );
    }
  }

  void _attachController() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SkyloomFormController(
          schema: widget.schema,
          initialValues: widget.initialValues,
          validators: widget.validators,
        );
    if (_controller.schema.id != widget.schema.id) {
      throw ArgumentError(
        'The supplied controller belongs to schema '
        '"${_controller.schema.id}", not "${widget.schema.id}".',
      );
    }
    _encodedValues = jsonEncode(_controller.values);
    _controller.addListener(_handleControllerChanged);
  }

  void _detachController() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _handleControllerChanged() {
    final values = _controller.values;
    final encodedValues = jsonEncode(values);
    if (_encodedValues == encodedValues) return;
    _encodedValues = encodedValues;
    widget.onChanged?.call(values);
  }

  Future<void> _submit() async {
    await _controller.submit(widget.onSubmit);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final fieldSchema in widget.schema.fields)
            AnimatedBuilder(
              animation: _controller.field(fieldSchema.key),
              builder: (context, _) {
                final fieldController = _controller.field(fieldSchema.key);
                if (!fieldController.visible) {
                  return const SizedBox.shrink();
                }
                final renderer = _rendererRegistry.rendererFor(
                  fieldSchema.type,
                );
                if (renderer == null) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: widget.fieldSpacing),
                    child: _UnsupportedFieldType(
                      fieldKey: fieldSchema.key,
                      fieldType: fieldSchema.type,
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.only(bottom: widget.fieldSpacing),
                  child: renderer.build(
                    context,
                    SkyloomRendererContext(
                      fieldSchema: fieldSchema,
                      fieldController: fieldController,
                      formController: _controller,
                      validateOnChange: widget.validateOnChange,
                    ),
                  ),
                );
              },
            ),
          if (widget.showSubmitButton && widget.onSubmit != null)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return FilledButton(
                  onPressed: _controller.submitting ? null : _submit,
                  child: _controller.submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.submitButtonLabel),
                );
              },
            ),
        ],
      ),
    );

    if (widget.inputDecorationTheme != null) {
      content = Theme(
        data: Theme.of(
          context,
        ).copyWith(inputDecorationTheme: widget.inputDecorationTheme),
        child: content,
      );
    }
    if (widget.padding != EdgeInsets.zero) {
      content = Padding(padding: widget.padding, child: content);
    }
    if (widget.layout == SkyloomFormLayout.scrollable) {
      content = SingleChildScrollView(child: content);
    }
    return content;
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }
}

final class _UnsupportedFieldType extends StatelessWidget {
  const _UnsupportedFieldType({
    required this.fieldKey,
    required this.fieldType,
  });

  final String fieldKey;
  final String fieldType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Unsupported field type $fieldType for $fieldKey',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'No renderer is registered for "$fieldType" ($fieldKey).',
            style: TextStyle(color: colors.onErrorContainer),
          ),
        ),
      ),
    );
  }
}
