import 'dart:async';

import 'package:flutter/material.dart';

import '../../registry/renderer_registry.dart';
import '../../schema/field_schema.dart';
import '../../schema/form_type.dart';
import '../../schema/ui_schema.dart';
import '../../utils/json_value_utils.dart';
import '../../utils/path_utils.dart';
import '../field_renderer.dart';
import '../renderer_context.dart';

/// Creates the basic, theme-aware Material renderer collection.
final class MaterialSkyloomRenderers {
  const MaterialSkyloomRenderers._();

  static SkyloomRendererRegistry defaults({
    Map<String, SkyloomFieldRenderer> overrides = const {},
  }) {
    return SkyloomRendererRegistry({
      FormType.text: const MaterialTextFieldRenderer(),
      FormType.email: const MaterialTextFieldRenderer(),
      FormType.password: const MaterialTextFieldRenderer(),
      FormType.number: const MaterialTextFieldRenderer(),
      FormType.textarea: const MaterialTextFieldRenderer(),
      FormType.checkbox: const MaterialCheckboxFieldRenderer(),
      FormType.switchField: const MaterialSwitchFieldRenderer(),
      FormType.radio: const MaterialRadioFieldRenderer(),
      FormType.select: const MaterialSelectFieldRenderer(),
      FormType.date: const MaterialDateFieldRenderer(),
      FormType.chip: const MaterialChipFieldRenderer(),
      FormType.object: const MaterialObjectFieldRenderer(),
      FormType.array: const MaterialArrayFieldRenderer(),
      ...overrides,
    });
  }
}

/// Renders a nested object as a quiet Material 3 surface.
final class MaterialObjectFieldRenderer implements SkyloomFieldRenderer {
  const MaterialObjectFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    final schema = rendererContext.fieldSchema;
    final fields = schema.fields ?? const <FieldSchema>[];
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (schema.label != null)
              Text(
                schema.label!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            if (schema.description != null) ...[
              const SizedBox(height: 4),
              Text(schema.description!),
            ],
            if (schema.label != null || schema.description != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
            for (var index = 0; index < fields.length; index++) ...[
              rendererContext.buildChild(
                fields[index],
                rendererContext.fieldPath,
              ),
            ],
            if (rendererContext.error != null)
              _ErrorText(rendererContext.error!),
          ],
        ),
      ),
    );
  }
}

/// Renders repeatable primitive, object, and nested-array items.
final class MaterialArrayFieldRenderer implements SkyloomFieldRenderer {
  const MaterialArrayFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    return _SkyloomArrayField(rendererContext: rendererContext);
  }
}

final class _SkyloomArrayField extends StatelessWidget {
  const _SkyloomArrayField({required this.rendererContext});

  final SkyloomRendererContext rendererContext;

  @override
  Widget build(BuildContext context) {
    final schema = rendererContext.fieldSchema;
    final field = rendererContext.fieldController;
    final values = field.value is List<Object?>
        ? field.value! as List<Object?>
        : const <Object?>[];
    final editable = field.enabled && !field.readOnly;
    final canAdd =
        editable &&
        (schema.maxItems == null || values.length < schema.maxItems!);

    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schema.label ?? schema.key,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (schema.description != null) Text(schema.description!),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: canAdd
                      ? () => rendererContext.formController.addArrayItem(
                          rendererContext.fieldPath,
                        )
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            if (values.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No items yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            for (var index = 0; index < values.length; index++) ...[
              const SizedBox(height: 16),
              _ArrayItemCard(
                key: ValueKey('${rendererContext.fieldPath}[$index]'),
                index: index,
                count: values.length,
                schema: schema.items!,
                value: values[index],
                enabled: editable,
                canRemove: values.length > (schema.minItems ?? 0),
                canDuplicate:
                    schema.maxItems == null || values.length < schema.maxItems!,
                onChanged: (value) => _replace(values, index, value),
                onRemove: () => rendererContext.formController.removeArrayItem(
                  rendererContext.fieldPath,
                  index,
                ),
                onDuplicate: () => rendererContext.formController
                    .duplicateArrayItem(rendererContext.fieldPath, index),
                onMoveUp: index == 0
                    ? null
                    : () => rendererContext.formController.reorderArrayItem(
                        rendererContext.fieldPath,
                        index,
                        index - 1,
                      ),
                onMoveDown: index == values.length - 1
                    ? null
                    : () => rendererContext.formController.reorderArrayItem(
                        rendererContext.fieldPath,
                        index,
                        index + 1,
                      ),
              ),
            ],
            if (rendererContext.error != null) ...[
              const SizedBox(height: 8),
              _ErrorText(rendererContext.error!),
            ],
          ],
        ),
      ),
    );
  }

  void _replace(List<Object?> current, int index, Object? value) {
    final next = thawJsonValue(current)! as List<Object?>;
    next[index] = value;
    rendererContext.setValue(next);
  }
}

final class _ArrayItemCard extends StatelessWidget {
  const _ArrayItemCard({
    required this.index,
    required this.count,
    required this.schema,
    required this.value,
    required this.enabled,
    required this.canRemove,
    required this.canDuplicate,
    required this.onChanged,
    required this.onRemove,
    required this.onDuplicate,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
  });

  final int index;
  final int count;
  final FieldSchema schema;
  final Object? value;
  final bool enabled;
  final bool canRemove;
  final bool canDuplicate;
  final ValueChanged<Object?> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    schema.label ?? 'Item ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Move item up',
                  onPressed: enabled ? onMoveUp : null,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: 'Move item down',
                  onPressed: enabled ? onMoveDown : null,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<_ArrayItemAction>(
                  tooltip: 'More item actions',
                  enabled: enabled,
                  onSelected: (action) {
                    switch (action) {
                      case _ArrayItemAction.duplicate:
                        onDuplicate();
                      case _ArrayItemAction.remove:
                        onRemove();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ArrayItemAction.duplicate,
                      enabled: canDuplicate,
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.copy_outlined),
                        title: Text('Duplicate'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ArrayItemAction.remove,
                      enabled: canRemove,
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            if (count == 1) ...[
              const SizedBox(height: 6),
              Text(
                'Add another item to enable reordering.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _ArrayItemEditor(
              schema: schema,
              value: value,
              enabled: enabled,
              path: 'item-$index',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ArrayItemAction { duplicate, remove }

final class _ArrayItemEditor extends StatelessWidget {
  const _ArrayItemEditor({
    required this.schema,
    required this.value,
    required this.enabled,
    required this.path,
    required this.onChanged,
  });

  final FieldSchema schema;
  final Object? value;
  final bool enabled;
  final String path;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (schema.type == FormType.object) {
      final object = value is Map<String, Object?>
          ? value! as Map<String, Object?>
          : <String, Object?>{};
      final fields = schema.fields ?? const <FieldSchema>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < fields.length; index++) ...[
            _ArrayItemEditor(
              schema: fields[index],
              value: PathUtils.getValue(object, fields[index].key),
              enabled:
                  enabled && !fields[index].disabled && !fields[index].readOnly,
              path: '$path.${fields[index].key}',
              onChanged: (childValue) {
                final next = thawJsonValue(object)! as Map<String, Object?>;
                PathUtils.setValue(next, fields[index].key, childValue);
                onChanged(next);
              },
            ),
            if (index < fields.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    if (schema.type == FormType.array) {
      final items = value is List<Object?>
          ? value! as List<Object?>
          : const <Object?>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (schema.label != null)
            Text(schema.label!, style: Theme.of(context).textTheme.titleSmall),
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ArrayItemEditor(
                      schema: schema.items!,
                      value: items[index],
                      enabled: enabled,
                      path: '$path[$index]',
                      onChanged: (itemValue) {
                        final next = thawJsonValue(items)! as List<Object?>;
                        next[index] = itemValue;
                        onChanged(next);
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove nested item',
                    onPressed: enabled && items.length > (schema.minItems ?? 0)
                        ? () {
                            final next = thawJsonValue(items)! as List<Object?>;
                            next.removeAt(index);
                            onChanged(next);
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed:
                  enabled &&
                      (schema.maxItems == null ||
                          items.length < schema.maxItems!)
                  ? () => onChanged([
                      ...items.map(thawJsonValue),
                      _defaultValue(schema.items!),
                    ])
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Add nested item'),
            ),
          ),
        ],
      );
    }
    if (schema.type == FormType.checkbox ||
        schema.type == FormType.switchField) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(schema.label ?? schema.key),
        value: value == true,
        onChanged: enabled ? onChanged : null,
      );
    }
    if (schema.type == FormType.select || schema.type == FormType.radio) {
      final options = schema.options ?? const [];
      return DropdownButtonFormField<Object?>(
        key: ValueKey('$path:$value'),
        initialValue: options.any((option) => option.value == value)
            ? value
            : null,
        decoration: InputDecoration(
          labelText: schema.label,
          helperText: schema.helperText ?? schema.description,
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option.value, child: Text(option.label)),
        ],
        onChanged: enabled ? onChanged : null,
      );
    }
    return _InlineTextEditor(
      key: ValueKey(path),
      schema: schema,
      value: value,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

final class _InlineTextEditor extends StatefulWidget {
  const _InlineTextEditor({
    required this.schema,
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final FieldSchema schema;
  final Object? value;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  @override
  State<_InlineTextEditor> createState() => _InlineTextEditorState();
}

final class _InlineTextEditorState extends State<_InlineTextEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _InlineTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value?.toString() ?? '';
    if (_controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textarea = widget.schema.type == FormType.textarea;
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      obscureText: widget.schema.type == FormType.password,
      keyboardType: widget.schema.type == FormType.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : widget.schema.type == FormType.email
          ? TextInputType.emailAddress
          : textarea
          ? TextInputType.multiline
          : TextInputType.text,
      minLines: textarea ? 3 : 1,
      maxLines: textarea ? 6 : 1,
      decoration: InputDecoration(
        labelText: widget.schema.label,
        hintText: widget.schema.placeholder,
        helperText: widget.schema.helperText ?? widget.schema.description,
      ),
      onChanged: (text) {
        if (widget.schema.type == FormType.number) {
          widget.onChanged(
            text.trim().isEmpty
                ? null
                : int.tryParse(text) ?? double.tryParse(text) ?? text,
          );
        } else {
          widget.onChanged(text);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

Object? _defaultValue(FieldSchema schema) {
  if (schema.hasDefaultValue) return thawJsonValue(schema.defaultValue);
  if (schema.type == FormType.object) {
    final result = <String, Object?>{};
    for (final child in schema.fields ?? const <FieldSchema>[]) {
      PathUtils.setValue(result, child.key, _defaultValue(child));
    }
    return result;
  }
  if (schema.type == FormType.array) {
    return <Object?>[
      for (var index = 0; index < (schema.minItems ?? 0); index++)
        schema.hasDefaultItem
            ? thawJsonValue(schema.defaultItem)
            : _defaultValue(schema.items!),
    ];
  }
  return null;
}

final class MaterialTextFieldRenderer implements SkyloomFieldRenderer {
  const MaterialTextFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    return _SkyloomTextField(rendererContext: rendererContext);
  }
}

final class _SkyloomTextField extends StatefulWidget {
  const _SkyloomTextField({required this.rendererContext});

  final SkyloomRendererContext rendererContext;

  @override
  State<_SkyloomTextField> createState() => _SkyloomTextFieldState();
}

final class _SkyloomTextFieldState extends State<_SkyloomTextField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _displayValue);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    widget.rendererContext.fieldController.addListener(_syncValue);
  }

  @override
  void didUpdateWidget(covariant _SkyloomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rendererContext.fieldController !=
        widget.rendererContext.fieldController) {
      oldWidget.rendererContext.fieldController.removeListener(_syncValue);
      widget.rendererContext.fieldController.addListener(_syncValue);
      _syncValue();
    }
  }

  String get _displayValue =>
      widget.rendererContext.fieldController.value?.toString() ?? '';

  void _syncValue() {
    final text = _displayValue;
    if (_textController.text == text) return;
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleFocusChanged() {
    final field = widget.rendererContext.fieldController;
    field.setFocused(_focusNode.hasFocus);
    if (!_focusNode.hasFocus && widget.rendererContext.validateOnBlur) {
      widget.rendererContext.formController.validateField(field.key);
      unawaited(
        widget.rendererContext.formController.validateFieldAsync(field.key),
      );
    }
  }

  Object? _parseValue(String text) {
    if (widget.rendererContext.fieldSchema.type != FormType.number) {
      return text;
    }
    if (text.trim().isEmpty) return null;
    return int.tryParse(text) ?? double.tryParse(text) ?? text;
  }

  @override
  Widget build(BuildContext context) {
    final schema = widget.rendererContext.fieldSchema;
    final field = widget.rendererContext.fieldController;
    final isTextarea = schema.type == FormType.textarea;
    final keyboardType = switch (schema.type) {
      FormType.email => TextInputType.emailAddress,
      FormType.number => const TextInputType.numberWithOptions(decimal: true),
      FormType.textarea => TextInputType.multiline,
      _ => TextInputType.text,
    };

    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      enabled: field.enabled,
      readOnly: field.readOnly,
      obscureText: schema.type == FormType.password,
      keyboardType: keyboardType,
      minLines: isTextarea ? 3 : 1,
      maxLines: isTextarea ? 6 : 1,
      textInputAction: isTextarea
          ? TextInputAction.newline
          : TextInputAction.next,
      autofillHints: switch (schema.type) {
        FormType.email => const [AutofillHints.email],
        FormType.password => const [AutofillHints.password],
        _ => null,
      },
      decoration: InputDecoration(
        labelText: schema.label,
        hintText: schema.placeholder,
        helperText: schema.helperText ?? schema.description,
        errorText: field.error,
        suffixIcon: field.loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      onChanged: (value) {
        widget.rendererContext.setValue(_parseValue(value));
      },
    );
  }

  @override
  void dispose() {
    widget.rendererContext.fieldController.removeListener(_syncValue);
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }
}

final class MaterialCheckboxFieldRenderer implements SkyloomFieldRenderer {
  const MaterialCheckboxFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    final schema = rendererContext.fieldSchema;
    final field = rendererContext.fieldController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(schema.label ?? schema.key),
          subtitle: _description(schema.description ?? schema.helperText),
          value: field.value == true,
          onChanged: field.enabled && !field.readOnly
              ? (value) => rendererContext.setValue(value ?? false)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (field.error != null) _ErrorText(field.error!),
      ],
    );
  }
}

final class MaterialSwitchFieldRenderer implements SkyloomFieldRenderer {
  const MaterialSwitchFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    final schema = rendererContext.fieldSchema;
    final field = rendererContext.fieldController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(schema.label ?? schema.key),
          subtitle: _description(schema.description ?? schema.helperText),
          value: field.value == true,
          onChanged: field.enabled && !field.readOnly
              ? rendererContext.setValue
              : null,
        ),
        if (field.error != null) _ErrorText(field.error!),
      ],
    );
  }
}

final class MaterialRadioFieldRenderer implements SkyloomFieldRenderer {
  const MaterialRadioFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    final schema = rendererContext.fieldSchema;
    final field = rendererContext.fieldController;
    final options = rendererContext.formController.optionsFor(
      rendererContext.fieldPath,
    );
    final visualHints = rendererContext
        .formController
        .schema
        .uiSchema[rendererContext.fieldPath]
        ?.visualHints;
    final horizontal =
        visualHints?[FormUiHint.radioDirection] == FormUiDirection.row;
    final tiles = [
      for (final option in options)
        RadioListTile<Object?>(
          dense: horizontal,
          contentPadding: EdgeInsets.zero,
          title: Text(option.label),
          value: option.value,
          enabled: field.enabled && !field.readOnly,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (schema.label != null)
          Text(schema.label!, style: Theme.of(context).textTheme.titleSmall),
        if (schema.description != null) Text(schema.description!),
        RadioGroup<Object?>(
          groupValue: field.value,
          onChanged: field.enabled && !field.readOnly
              ? rendererContext.setValue
              : (_) {},
          child: horizontal
              ? Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tile in tiles) SizedBox(width: 180, child: tile),
                  ],
                )
              : Column(children: tiles),
        ),
        if (field.error != null) _ErrorText(field.error!),
      ],
    );
  }
}

/// Renders single-choice or multi-choice options as Material chips.
final class MaterialChipFieldRenderer implements SkyloomFieldRenderer {
  const MaterialChipFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    final schema = rendererContext.fieldSchema;
    final field = rendererContext.fieldController;
    final options = rendererContext.formController.optionsFor(
      rendererContext.fieldPath,
    );
    final visualHints = rendererContext
        .formController
        .schema
        .uiSchema[rendererContext.fieldPath]
        ?.visualHints;
    final multiSelect = visualHints?[FormUiHint.multiSelect] == true;
    final selectedValues = field.value is List<Object?>
        ? field.value! as List<Object?>
        : const <Object?>[];
    final editable = field.enabled && !field.readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (schema.label != null)
          Text(schema.label!, style: Theme.of(context).textTheme.titleSmall),
        if (schema.description != null) ...[
          const SizedBox(height: 4),
          Text(schema.description!),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              if (multiSelect)
                FilterChip(
                  label: Text(option.label),
                  selected: selectedValues.contains(option.value),
                  onSelected: editable
                      ? (selected) {
                          final current = field.value is List<Object?>
                              ? field.value! as List<Object?>
                              : const <Object?>[];
                          final next = [...current];
                          if (selected) {
                            if (!next.contains(option.value)) {
                              next.add(thawJsonValue(option.value));
                            }
                          } else {
                            next.remove(option.value);
                          }
                          rendererContext.setValue(next);
                        }
                      : null,
                )
              else
                ChoiceChip(
                  label: Text(option.label),
                  selected: field.value == option.value,
                  onSelected: editable
                      ? (selected) => rendererContext.setValue(
                          selected ? thawJsonValue(option.value) : null,
                        )
                      : null,
                ),
          ],
        ),
        if (field.error != null) _ErrorText(field.error!),
      ],
    );
  }
}

final class MaterialSelectFieldRenderer implements SkyloomFieldRenderer {
  const MaterialSelectFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    final schema = rendererContext.fieldSchema;
    if (schema.dataSource != null) {
      return _SkyloomAsyncSelectField(rendererContext: rendererContext);
    }
    final field = rendererContext.fieldController;
    final options = schema.options ?? const [];
    final selectedValue = options.any((option) => option.value == field.value)
        ? field.value
        : null;
    return DropdownButtonFormField<Object?>(
      key: ValueKey(selectedValue),
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: schema.label,
        hintText: schema.placeholder,
        helperText: schema.helperText ?? schema.description,
        errorText: field.error,
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<Object?>(
            value: option.value,
            child: Text(option.label),
          ),
      ],
      onChanged: field.enabled && !field.readOnly
          ? rendererContext.setValue
          : null,
    );
  }
}

final class _SkyloomAsyncSelectField extends StatelessWidget {
  const _SkyloomAsyncSelectField({required this.rendererContext});

  final SkyloomRendererContext rendererContext;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rendererContext.formController,
      builder: (context, _) {
        final schema = rendererContext.fieldSchema;
        final field = rendererContext.fieldController;
        final state = rendererContext.formController.dataSourceState(
          rendererContext.fieldPath,
        );
        final options = rendererContext.formController.optionsFor(
          rendererContext.fieldPath,
        );
        String? selectedLabel;
        for (final option in options) {
          if (option.value == field.value) selectedLabel = option.label;
        }
        return TextFormField(
          key: ValueKey('${rendererContext.fieldPath}:${field.value}'),
          initialValue: selectedLabel ?? field.value?.toString() ?? '',
          enabled: field.enabled,
          readOnly: true,
          decoration: InputDecoration(
            labelText: schema.label,
            hintText: schema.placeholder,
            helperText: schema.helperText ?? schema.description,
            errorText: field.error,
            suffixIcon: state.loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.arrow_drop_down),
          ),
          onTap: field.readOnly ? null : () => _showPicker(context),
        );
      },
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final controller = rendererContext.formController;
    final config = rendererContext.fieldSchema.dataSource!;
    Timer? debounce;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          rendererContext.fieldSchema.label ?? rendererContext.fieldPath,
        ),
        content: SizedBox(
          width: 420,
          height: 480,
          child: Column(
            children: [
              if (config.search)
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    debounce?.cancel();
                    debounce = Timer(
                      Duration(milliseconds: config.debounceMilliseconds),
                      () => unawaited(
                        controller.loadOptions(
                          rendererContext.fieldPath,
                          search: query,
                          force: true,
                        ),
                      ),
                    );
                  },
                ),
              if (config.search) const SizedBox(height: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final state = controller.dataSourceState(
                      rendererContext.fieldPath,
                    );
                    if (state.loading && state.options.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.error != null && state.options.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.error.toString()),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: () => unawaited(
                                controller.loadOptions(
                                  rendererContext.fieldPath,
                                  search: state.search,
                                  force: true,
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state.options.isEmpty) {
                      return const Center(child: Text('No options found.'));
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 100 &&
                            state.hasMore &&
                            !state.loading) {
                          unawaited(
                            controller.loadNextOptionsPage(
                              rendererContext.fieldPath,
                            ),
                          );
                        }
                        return false;
                      },
                      child: ListView(
                        children: [
                          for (final option in state.options)
                            ListTile(
                              title: Text(option.label),
                              selected:
                                  option.value ==
                                  rendererContext.fieldController.value,
                              onTap: () {
                                rendererContext.setValue(option.value);
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                          if (state.hasMore)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: FilledButton.tonal(
                                onPressed: state.loading
                                    ? null
                                    : () => unawaited(
                                        controller.loadNextOptionsPage(
                                          rendererContext.fieldPath,
                                        ),
                                      ),
                                child: state.loading
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Load more'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    debounce?.cancel();
  }
}

final class MaterialDateFieldRenderer implements SkyloomFieldRenderer {
  const MaterialDateFieldRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext rendererContext) {
    return _SkyloomDateField(rendererContext: rendererContext);
  }
}

final class _SkyloomDateField extends StatelessWidget {
  const _SkyloomDateField({required this.rendererContext});

  final SkyloomRendererContext rendererContext;

  DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final schema = rendererContext.fieldSchema;
    final field = rendererContext.fieldController;
    final selectedDate = _parseDate(field.value);
    return TextFormField(
      key: ValueKey(field.value),
      initialValue: selectedDate == null
          ? ''
          : selectedDate.toIso8601String().split('T').first,
      enabled: field.enabled,
      readOnly: true,
      decoration: InputDecoration(
        labelText: schema.label,
        hintText: schema.placeholder,
        helperText: schema.helperText ?? schema.description,
        errorText: field.error,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      onTap: field.readOnly
          ? null
          : () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? now,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                rendererContext.setValue(
                  picked.toIso8601String().split('T').first,
                );
              }
            },
    );
  }
}

Widget? _description(String? text) => text == null ? null : Text(text);

final class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
