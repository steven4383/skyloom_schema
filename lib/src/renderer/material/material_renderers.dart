import 'package:flutter/material.dart';

import '../../registry/renderer_registry.dart';
import '../../schema/form_type.dart';
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
      ...overrides,
    });
  }
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
    if (!_focusNode.hasFocus) {
      widget.rendererContext.formController.validateField(field.key);
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
    final options = schema.options ?? const [];
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
          child: Column(
            children: [
              for (final option in options)
                RadioListTile<Object?>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                  value: option.value,
                  enabled: field.enabled && !field.readOnly,
                ),
            ],
          ),
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
