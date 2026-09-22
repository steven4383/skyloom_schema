import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../controller/form_controller.dart';
import '../controller/field_navigation.dart';
import '../controller/step_navigation.dart';
import '../engine/data_source.dart';
import '../engine/validation_mode.dart';
import '../parser/schema_parser.dart';
import '../registry/renderer_registry.dart';
import '../schema/field_schema.dart';
import '../schema/form_schema.dart';
import '../schema/section_schema.dart';
import '../schema/step_schema.dart';
import 'field_renderer.dart';
import 'material/form_actions.dart';
import 'material/form_error_summary.dart';
import 'material/form_step_progress.dart';
import 'material/material_renderers.dart';
import 'renderer_context.dart';

/// Controls how a [SkyloomForm] participates in vertical layout.
enum SkyloomFormLayout {
  /// Render only the content column. The parent owns scrolling.
  column,

  /// Wrap the form in a scroll view to prevent large-form overflow.
  scrollable,

  /// Lazily builds top-level sections for very large forms.
  lazy,
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
    this.onStepChanging,
    bool? validateOnChange,
    this.validationMode = SkyloomValidationMode.onChange,
    this.showSubmitButton = true,
    this.submitButtonLabel = 'Submit',
    this.nextButtonLabel = 'Next',
    this.backButtonLabel = 'Back',
    this.showStepProgress = true,
    this.allowStepNavigation = false,
    this.showErrorSummary = true,
    this.autoFocusFirstError = true,
    this.onStepChanged,
    this.fieldSpacing = 16,
    this.layout = SkyloomFormLayout.scrollable,
    this.padding = EdgeInsets.zero,
    this.inputDecorationTheme,
    this.cacheExtent,
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
    SkyloomStepGuard? onStepChanging,
    bool? validateOnChange,
    SkyloomValidationMode validationMode = SkyloomValidationMode.onChange,
    bool showSubmitButton = true,
    String submitButtonLabel = 'Submit',
    String nextButtonLabel = 'Next',
    String backButtonLabel = 'Back',
    bool showStepProgress = true,
    bool allowStepNavigation = false,
    bool showErrorSummary = true,
    bool autoFocusFirstError = true,
    ValueChanged<StepSchema>? onStepChanged,
    double fieldSpacing = 16,
    SkyloomFormLayout layout = SkyloomFormLayout.scrollable,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    InputDecorationTheme? inputDecorationTheme,
    double? cacheExtent,
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
      onStepChanging: onStepChanging,
      validateOnChange: validateOnChange,
      validationMode: validationMode,
      showSubmitButton: showSubmitButton,
      submitButtonLabel: submitButtonLabel,
      nextButtonLabel: nextButtonLabel,
      backButtonLabel: backButtonLabel,
      showStepProgress: showStepProgress,
      allowStepNavigation: allowStepNavigation,
      showErrorSummary: showErrorSummary,
      autoFocusFirstError: autoFocusFirstError,
      onStepChanged: onStepChanged,
      fieldSpacing: fieldSpacing,
      layout: layout,
      padding: padding,
      inputDecorationTheme: inputDecorationTheme,
      cacheExtent: cacheExtent,
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
  final SkyloomStepGuard? onStepChanging;
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
  final String nextButtonLabel;
  final String backButtonLabel;
  final bool showStepProgress;
  final bool allowStepNavigation;
  final bool showErrorSummary;
  final bool autoFocusFirstError;
  final ValueChanged<StepSchema>? onStepChanged;
  final double fieldSpacing;
  final SkyloomFormLayout layout;
  final EdgeInsetsGeometry padding;
  final double? cacheExtent;

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
  String? _stepId;
  final Map<String, GlobalKey> _fieldKeys = {};
  final Map<String, ExpansibleController> _sectionControllers = {};
  int _handledFieldNavigationRequestId = 0;

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
        oldWidget.onDependencyChanged != widget.onDependencyChanged ||
        oldWidget.onStepChanging != widget.onStepChanging) {
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
          onStepChanging: widget.onStepChanging,
        );
    if (_controller.schema.id != widget.schema.id) {
      throw ArgumentError(
        'The supplied controller belongs to schema '
        '"${_controller.schema.id}", not "${widget.schema.id}".',
      );
    }
    _encodedValues = jsonEncode(_controller.values);
    _stepId = _controller.currentStep?.id;
    final request = _controller.fieldNavigationRequest;
    if (request != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleFieldNavigationRequest(request);
      });
    }
    _controller.addListener(_handleControllerChanged);
  }

  void _detachController() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _handleControllerChanged() {
    final navigationRequest = _controller.fieldNavigationRequest;
    if (navigationRequest != null &&
        navigationRequest.id > _handledFieldNavigationRequestId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleFieldNavigationRequest(navigationRequest);
      });
    }
    final step = _controller.currentStep;
    if (_stepId != step?.id) {
      _stepId = step?.id;
      if (mounted) setState(() {});
      if (step != null) widget.onStepChanged?.call(step);
    }
    final values = _controller.values;
    final encodedValues = jsonEncode(values);
    if (_encodedValues == encodedValues) return;
    _encodedValues = encodedValues;
    widget.onChanged?.call(values);
  }

  void _handleFieldNavigationRequest(SkyloomFieldNavigationRequest request) {
    if (!mounted || request.id <= _handledFieldNavigationRequestId) return;
    _handledFieldNavigationRequestId = request.id;
    unawaited(
      _revealError(request.fieldPath, requestFocus: request.requestsFocus),
    );
  }

  Future<void> _submit() async {
    final bool submitted;
    if (widget.validationMode == SkyloomValidationMode.manual) {
      submitted = await _controller.submitWithoutValidation(widget.onSubmit);
    } else {
      submitted = await _controller.submit(widget.onSubmit);
    }
    if (!submitted || _controller.errorEntries.isNotEmpty) {
      await _revealFirstError();
    }
  }

  Future<void> _nextStep() async {
    final moved = await _controller.nextStep(
      validateCurrent: widget.validationMode != SkyloomValidationMode.manual,
    );
    if (!moved && !_controller.isLastStep) await _revealFirstError();
  }

  void _previousStep() => unawaited(_controller.previousStep());

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
        return KeyedSubtree(
          key: _fieldKeys.putIfAbsent(fieldPath, GlobalKey.new),
          child: RepaintBoundary(
            child: Padding(
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
                  revalidateInvalidOnChange:
                      widget.validationMode != SkyloomValidationMode.manual,
                  validateOnBlur: widget.validateOnBlur,
                ),
              ),
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
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final errors = _sectionErrors(section);
          final errorSummary = errors.isEmpty
              ? null
              : errors.length == 1
              ? errors.first.value
              : '${errors.first.value} (+${errors.length - 1} more)';
          return Padding(
            padding: EdgeInsets.only(bottom: widget.fieldSpacing),
            child: DecoratedBox(
              decoration: decoration,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ExpansionTile(
                  controller: _sectionControllers.putIfAbsent(
                    section.id,
                    ExpansibleController.new,
                  ),
                  initiallyExpanded: section.defaultExpanded,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.title ?? section.id,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (errors.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${errors.length} ${errors.length == 1 ? 'error' : 'errors'}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.onErrorContainer),
                          ),
                        ),
                    ],
                  ),
                  subtitle: section.description == null && errorSummary == null
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (section.description != null)
                              Text(section.description!),
                            if (errorSummary != null)
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  errorSummary,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.error),
                                ),
                              ),
                          ],
                        ),
                  children: [const Divider(height: 1), content],
                ),
              ),
            ),
          );
        },
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

  List<MapEntry<String, String>> _sectionErrors(SectionSchema section) {
    return _controller.errors.entries.where((entry) {
      return section.fields.any(
        (field) =>
            entry.key == field ||
            entry.key.startsWith('$field.') ||
            entry.key.startsWith('$field['),
      );
    }).toList();
  }

  List<Widget> _buildSchemaContent() {
    final allowedKeys = _controller.currentStep?.fields.toSet();
    final visibleFields = allowedKeys == null
        ? widget.schema.fields
        : widget.schema.fields
              .where((field) => allowedKeys.contains(field.key))
              .toList();
    if (widget.schema.sections.isEmpty) {
      return [_buildResponsiveFields(visibleFields)];
    }
    final byKey = {for (final field in widget.schema.fields) field.key: field};
    final sections =
        widget.schema.sections
            .map(
              (section) => MapEntry(
                section,
                section.fields
                    .where(
                      (key) => allowedKeys == null || allowedKeys.contains(key),
                    )
                    .toList(),
              ),
            )
            .where((entry) => entry.value.isNotEmpty)
            .toList()
          ..sort((left, right) => left.key.order.compareTo(right.key.order));
    final assigned = sections.expand((entry) => entry.value).toSet();
    return [
      for (final entry in sections)
        _buildSection(entry.key, [for (final key in entry.value) byKey[key]!]),
      if (assigned.length < visibleFields.length)
        _buildResponsiveFields(
          visibleFields
              .where((field) => !assigned.contains(field.key))
              .toList(),
        ),
    ];
  }

  Widget _buildStepProgress() {
    return SkyloomMaterialStepProgress(
      controller: _controller,
      visible: widget.showStepProgress,
      allowNavigation: widget.allowStepNavigation,
      bottomSpacing: widget.fieldSpacing,
    );
  }

  Widget _buildErrorSummary() {
    return SkyloomMaterialErrorSummary(
      controller: _controller,
      visible: widget.showErrorSummary,
      bottomSpacing: widget.fieldSpacing,
      fieldLabel: (fieldPath) =>
          _controller.field(fieldPath).schema.label ?? fieldPath,
      onReveal: (fieldPath) => unawaited(_revealError(fieldPath)),
    );
  }

  Widget _buildActions() {
    return SkyloomMaterialFormActions(
      controller: _controller,
      visible: widget.showSubmitButton,
      canSubmit: widget.onSubmit != null,
      submitLabel: widget.submitButtonLabel,
      nextLabel: widget.nextButtonLabel,
      backLabel: widget.backButtonLabel,
      onSubmit: () => unawaited(_submit()),
      onNext: () => unawaited(_nextStep()),
      onBack: _previousStep,
    );
  }

  Future<void> _revealFirstError() async {
    if (!widget.autoFocusFirstError) return;
    final key = _controller.firstErrorFieldKey;
    if (key != null) await _revealError(key);
  }

  Future<void> _revealError(
    String fieldPath, {
    bool requestFocus = true,
  }) async {
    final root = fieldPath.split('.').first.split('[').first;
    for (final step in _controller.visibleSteps) {
      if (step.fields.contains(root)) {
        await _controller.goToStep(step.id);
        break;
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    for (final section in widget.schema.sections) {
      if (section.fields.contains(root) && section.collapsible) {
        _sectionControllers[section.id]?.expand();
        break;
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    final fieldContext =
        _fieldKeys[fieldPath]?.currentContext ??
        _fieldKeys[root]?.currentContext;
    if (fieldContext == null || !fieldContext.mounted) return;
    await Scrollable.ensureVisible(
      fieldContext,
      alignment: 0.15,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    if (!fieldContext.mounted) return;
    if (requestFocus) _requestDescendantFocus(fieldContext);
  }

  void _requestDescendantFocus(BuildContext context) {
    FocusNode? target;
    void visit(Element element) {
      if (target != null) return;
      final child = element.widget;
      if (child is EditableText) {
        target = child.focusNode;
        return;
      }
      if (child is Focus && child.focusNode != null) {
        target = child.focusNode;
        return;
      }
      element.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    target?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (_controller.hasSteps) _buildStepProgress(),
      _buildErrorSummary(),
      ..._buildSchemaContent(),
      _buildActions(),
    ];
    Widget content;
    if (widget.layout == SkyloomFormLayout.lazy) {
      content = FocusTraversalGroup(
        child: ListView.builder(
          padding: widget.padding,
          scrollCacheExtent: widget.cacheExtent == null
              ? null
              : ScrollCacheExtent.pixels(widget.cacheExtent!),
          itemCount: children.length,
          itemBuilder: (context, index) =>
              RepaintBoundary(child: children[index]),
        ),
      );
    } else {
      content = FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    if (widget.inputDecorationTheme != null) {
      content = Theme(
        data: Theme.of(
          context,
        ).copyWith(inputDecorationTheme: widget.inputDecorationTheme),
        child: content,
      );
    }
    if (widget.layout != SkyloomFormLayout.lazy &&
        widget.padding != EdgeInsets.zero) {
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
    for (final controller in _sectionControllers.values) {
      controller.dispose();
    }
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
