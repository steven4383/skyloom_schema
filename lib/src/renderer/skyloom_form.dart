import 'dart:convert';

import 'package:flutter/material.dart';

import '../controller/form_controller.dart';
import '../engine/data_source.dart';
import '../engine/validation_mode.dart';
import '../parser/schema_parser.dart';
import '../registry/renderer_registry.dart';
import '../schema/field_schema.dart';
import '../schema/form_schema.dart';
import '../schema/section_schema.dart';
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
    this.dataSources = const {},
    this.asyncValidators = const {},
    this.onDependencyChanged,
    bool? validateOnChange,
    this.validationMode = SkyloomValidationMode.onChange,
    this.showSubmitButton = true,
    this.submitButtonLabel = 'Submit',
    this.fieldSpacing = 16,
    this.layout = SkyloomFormLayout.scrollable,
    this.padding = EdgeInsets.zero,
    this.inputDecorationTheme,
    super.key,
  }) : _validateOnChangeOverride = validateOnChange;

  /// Parses [schema] and creates a form using the default Material renderers.
  factory SkyloomForm.fromJson({
    required Object? schema,
    SkyloomFormController? controller,
    Map<String, Object?> initialValues = const {},
    ValueChanged<Map<String, Object?>>? onChanged,
    SkyloomSubmitCallback? onSubmit,
    Map<String, SkyloomFieldRenderer> renderers = const {},
    Map<String, SkyloomValidator> validators = const {},
    Map<String, SkyloomDataSource> dataSources = const {},
    Map<String, SkyloomAsyncValidator> asyncValidators = const {},
    SkyloomDependencyCallback? onDependencyChanged,
    bool? validateOnChange,
    SkyloomValidationMode validationMode = SkyloomValidationMode.onChange,
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
      dataSources: dataSources,
      asyncValidators: asyncValidators,
      onDependencyChanged: onDependencyChanged,
      validateOnChange: validateOnChange,
      validationMode: validationMode,
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
  final Map<String, SkyloomDataSource> dataSources;
  final Map<String, SkyloomAsyncValidator> asyncValidators;
  final SkyloomDependencyCallback? onDependencyChanged;
  final bool? _validateOnChangeOverride;
  final SkyloomValidationMode validationMode;
  bool get validateOnChange =>
      _validateOnChangeOverride ??
      validationMode == SkyloomValidationMode.onChange;
  bool get validateOnBlur =>
      validationMode == SkyloomValidationMode.onChange ||
      validationMode == SkyloomValidationMode.onBlur;
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
        initialValuesChanged ||
        oldWidget.onDependencyChanged != widget.onDependencyChanged) {
      _detachController();
      _attachController();
    } else if (_ownsController && oldWidget.validators != widget.validators) {
      _controller.setValidators(widget.validators);
    }
    if (_ownsController && oldWidget.dataSources != widget.dataSources) {
      _controller.setDataSources(widget.dataSources);
    }
    if (_ownsController &&
        oldWidget.asyncValidators != widget.asyncValidators) {
      _controller.setAsyncValidators(widget.asyncValidators);
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
          dataSources: widget.dataSources,
          asyncValidators: widget.asyncValidators,
          onDependencyChanged: widget.onDependencyChanged,
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
    if (widget.validationMode == SkyloomValidationMode.manual) {
      await _controller.submitWithoutValidation(widget.onSubmit);
    } else {
      await _controller.submit(widget.onSubmit);
    }
  }

  Widget _buildField(FieldSchema fieldSchema, String parentPath) {
    final fieldPath = parentPath.isEmpty
        ? fieldSchema.key
        : '$parentPath.${fieldSchema.key}';
    return AnimatedBuilder(
      animation: _controller.field(fieldPath),
      builder: (context, _) {
        final fieldController = _controller.field(fieldPath);
        if (!fieldController.visible) return const SizedBox.shrink();
        final rendererType =
            widget.schema.uiSchema[fieldPath]?.widget ?? fieldSchema.type;
        final renderer = _rendererRegistry.rendererFor(rendererType);
        if (renderer == null) {
          return Padding(
            padding: EdgeInsets.only(bottom: widget.fieldSpacing),
            child: _UnsupportedFieldType(
              fieldKey: fieldPath,
              fieldType: rendererType,
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: widget.fieldSpacing),
          child: renderer.build(
            context,
            SkyloomRendererContext(
              fieldSchema: fieldSchema,
              fieldPath: fieldPath,
              fieldController: fieldController,
              formController: _controller,
              buildChild: _buildField,
              validateOnChange: widget.validateOnChange,
              validateOnBlur: widget.validateOnBlur,
            ),
          ),
        );
      },
    );
  }

  List<FieldSchema> _orderedFields(Iterable<FieldSchema> fields) {
    final original = fields.toList();
    final positions = {
      for (var index = 0; index < original.length; index++)
        original[index].key: index,
    };
    final result = [...original];
    result.sort((left, right) {
      final leftOrder = widget.schema.uiSchema[left.key]?.order;
      final rightOrder = widget.schema.uiSchema[right.key]?.order;
      if (leftOrder == null && rightOrder == null) {
        return positions[left.key]!.compareTo(positions[right.key]!);
      }
      if (leftOrder == null) return 1;
      if (rightOrder == null) return -1;
      final orderComparison = leftOrder.compareTo(rightOrder);
      return orderComparison != 0
          ? orderComparison
          : positions[left.key]!.compareTo(positions[right.key]!);
    });
    return result;
  }

  Widget _buildResponsiveFields(List<FieldSchema> fields) {
    final ordered = _orderedFields(fields);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final device = width < 600
            ? _LayoutDevice.mobile
            : width < 1024
            ? _LayoutDevice.tablet
            : _LayoutDevice.desktop;
        return Wrap(
          spacing: widget.fieldSpacing,
          children: [
            for (final field in ordered)
              SizedBox(
                width: _fieldWidth(field, width, device),
                child: _buildField(field, ''),
              ),
          ],
        );
      },
    );
  }

  double _fieldWidth(
    FieldSchema field,
    double availableWidth,
    _LayoutDevice device,
  ) {
    final layout = widget.schema.uiSchema[field.key]?.layout;
    final span = switch (device) {
      _LayoutDevice.mobile => layout?.mobile ?? 12,
      _LayoutDevice.tablet => layout?.tablet ?? 12,
      _LayoutDevice.desktop => layout?.desktop ?? 12,
    };
    return ((availableWidth + widget.fieldSpacing) * span / 12) -
        widget.fieldSpacing;
  }

  Widget _buildSection(SectionSchema section, List<FieldSchema> fields) {
    final colors = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _buildResponsiveFields(fields),
    );
    final decoration = BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    );
    if (section.collapsible) {
      return Padding(
        padding: EdgeInsets.only(bottom: widget.fieldSpacing),
        child: DecoratedBox(
          decoration: decoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ExpansionTile(
              initiallyExpanded: section.defaultExpanded,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                section.title ?? section.id,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: section.description == null
                  ? null
                  : Text(section.description!),
              children: [const Divider(height: 1), content],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: widget.fieldSpacing),
      child: DecoratedBox(
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (section.title != null || section.description != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (section.title != null)
                      Text(
                        section.title!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (section.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            content,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSchemaContent() {
    if (widget.schema.sections.isEmpty) {
      return [_buildResponsiveFields(widget.schema.fields)];
    }
    final byKey = {for (final field in widget.schema.fields) field.key: field};
    final assigned = widget.schema.sections
        .expand((section) => section.fields)
        .toSet();
    final sections = widget.schema.sections.toList()
      ..sort((left, right) => left.order.compareTo(right.order));
    return [
      for (final section in sections)
        _buildSection(section, [for (final key in section.fields) byKey[key]!]),
      if (assigned.length < widget.schema.fields.length)
        _buildResponsiveFields(
          widget.schema.fields
              .where((field) => !assigned.contains(field.key))
              .toList(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget content = FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildSchemaContent(),
          if (widget.showSubmitButton && widget.onSubmit != null)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 160,
                      maxWidth: 240,
                    ),
                    child: FilledButton(
                      onPressed: _controller.submitting ? null : _submit,
                      child: _controller.submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.submitButtonLabel),
                    ),
                  ),
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

enum _LayoutDevice { mobile, tablet, desktop }

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
