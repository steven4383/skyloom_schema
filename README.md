<p align="center">
  <img src="assets/branding/skyloom-logo-mark.png" width="150" alt="Skyloom woven-thread S logo">
</p>

# skyloom_schema

Build validated Flutter forms from typed Dart models or JSON-compatible
schemas. Skyloom keeps parsing, state, validation, and rendering separate, so
the same form definition can be stored remotely, authored in Dart, or rendered
with custom widgets.

## What you get

- Typed Dart builders with autocomplete
- JSON parsing and serialization
- Material 3 rendering for 14 field types
- Nested objects and repeatable arrays
- Validation, localization, and structured errors
- Conditional visibility, enabled, required, and read-only state
- Async options and async validation
- Responsive sections and multi-step workflows
- Provider-neutral file upload state
- Standard and brutalism themes with true-black dark mode
- Replaceable field renderers

## Install

```console
flutter pub add skyloom_schema
```

```dart
import 'package:flutter/material.dart';
import 'package:skyloom_schema/skyloom_schema.dart';
```

## Quick start

Use the typed API when the form is authored inside your Flutter application:

```dart
final employeeSchema = SkyloomSchema.form(
  id: 'employee',
  title: 'Employee registration',
  fields: [
    SkyloomField.text(
      key: 'name',
      label: 'Full name',
      validation: SkyloomValidation.rules(
        required: true,
        minLength: 2,
      ),
    ),
    SkyloomField.email(
      key: 'email',
      label: 'Email address',
      validation: SkyloomValidation.rules(
        required: true,
        email: true,
      ),
    ),
    SkyloomField.select(
      key: 'role',
      label: 'Role',
      options: const [
        FieldOption(label: 'Developer', value: 'developer'),
        FieldOption(label: 'Designer', value: 'designer'),
      ],
    ),
  ],
);
```

Render it with `SkyloomForm`:

```dart
SkyloomForm(
  schema: employeeSchema,
  initialValues: const {'role': 'developer'},
  onChanged: (values) => debugPrint('$values'),
  onSubmit: (values) async {
    await saveEmployee(values);
  },
)
```

Skyloom validates before submission and returns JSON-compatible nested values.

## JSON schemas

Use `SkyloomForm.fromJson` for schemas loaded from an API, asset, database, or
configuration file:

```dart
const schema = <String, Object?>{
  'schemaVersion': '1.0',
  'id': 'contact',
  'title': 'Contact details',
  'fields': [
    {
      'key': 'name',
      'type': 'text',
      'label': 'Name',
      'validation': {'required': true},
    },
    {
      'key': 'email',
      'type': 'email',
      'label': 'Email',
      'validation': {'required': true, 'email': true},
    },
  ],
};

SkyloomForm.fromJson(
  schema: schema,
  onSubmit: (values) => debugPrint('$values'),
)
```

In Dart maps you may use `FormType.text`, `FormType.email`, and the other
constants for autocomplete. Real JSON uses strings such as `"text"`.

To parse without rendering:

```dart
final form = const SchemaParser().parse(schema);
final json = form.toJson();
```

Invalid definitions throw `SchemaParseException` with a schema path. Use
`SchemaParser.validate` when an editor needs multiple diagnostics in one pass.
The parser also supports configurable complexity limits.

The complete contract is documented in [Schema 1.0](doc/schema-v1.md).

## Built-in fields

| Type | Purpose |
| --- | --- |
| `text` | Single-line text |
| `email` | Email input and validation |
| `password` | Obscured text |
| `number` | Numeric input |
| `textarea` | Multi-line text |
| `checkbox` | Boolean confirmation |
| `switch` | Boolean setting |
| `radio` | Single choice, row or column |
| `select` | Local or remotely loaded choice |
| `chip` | Single or multiple chip choices |
| `date` | Calendar date selection |
| `file` | Single or multiple uploaded-file references |
| `object` | Nested fields |
| `array` | Repeatable primitive, object, or nested items |

Unknown type names can be preserved for application-provided renderers.

## Validation and errors

Built-in validation covers required values, length, numeric ranges, date
ranges, email, URL, pattern/regex, array counts, file constraints, and
cross-field comparisons.

Choose when validation runs:

```dart
SkyloomForm.fromJson(
  schema: schema,
  validationMode: SkyloomValidationMode.onBlur,
  onSubmit: submit,
)
```

Available modes are `onChange`, `onBlur`, `onSubmit`, and `manual`.

Register application validation by name:

```dart
SkyloomForm.fromJson(
  schema: schema,
  validators: {
    'reservedName': (value, values) =>
        value == 'admin' ? 'This name is reserved.' : null,
  },
)
```

Use `SkyloomFormController.applyErrors` for backend errors. Errors retain
stable `SkyloomValidationCode` values, while `SkyloomMessages` controls visible
validation and interface text.

```dart
final controller = SkyloomFormController(schema: parsedSchema);

controller.applyErrors(
  fieldErrors: {
    'email': ['This address is already registered.'],
  },
);

controller.focusField('email');
```

## Dynamic forms

Conditions can change whether a field is visible, enabled, required, or
read-only. Dependencies can clear values and reload options when another field
changes.

```dart
{
  'key': 'state',
  'type': 'select',
  'label': 'State',
  'dependsOn': ['country'],
  'dataSource': {'handler': 'states'},
  'dependencyConfig': {
    'clearOnChange': true,
    'reloadDataOnChange': true,
  },
}
```

Register the application-owned callback in Dart:

```dart
SkyloomForm.fromJson(
  schema: schema,
  dataSources: {
    'states': (request) async {
      return api.states(request.dependencyValues['country']);
    },
  },
)
```

Named async validators support debouncing and optional result caching:

```dart
asyncValidators: {
  'emailAvailable': (value, context) async {
    return await api.emailExists('$value')
        ? 'This email is already registered.'
        : null;
  },
},
```

## Nested data, sections, and workflows

Object and array fields create values such as:

```json
{
  "address": {"city": "Chennai"},
  "contacts": [
    {"name": "Asha", "phone": "+91 90000 00000"}
  ]
}
```

`uiSchema` provides ordering and twelve-column mobile, tablet, and desktop
spans. Sections group or collapse fields. Steps add Back, Next, per-step
validation, conditional pages, progress, and final submission.

Large forms can use `SkyloomFormLayout.lazy`; nested paths, focus requests,
error summaries, and hidden/collapsed invalid fields remain controller-aware.

See the runnable [example application](example/main.dart) for complete nested,
responsive, and workflow definitions.

## File uploads

Skyloom does not choose a storage provider or file picker. A file field calls a
registered handler; your application picks/uploads files and returns portable
`SkyloomUploadedFile` references.

```dart
SkyloomForm.fromJson(
  schema: schema,
  fileUploadHandlers: {
    'resumeUpload': (request) async {
      final uploaded = await uploadResume();
      return [
        SkyloomUploadedFile(
          id: uploaded.id,
          name: uploaded.name,
          url: uploaded.url,
          mimeType: uploaded.mimeType,
          size: uploaded.size,
        ),
      ];
    },
  },
)
```

## Themes

Skyloom follows the host application's `ThemeData` by default. The optional
`SkyloomTheme` helper provides coordinated application and form styling.

```dart
const appearance = SkyloomTheme(
  seedColor: Colors.teal,
  visualStyle: SkyloomVisualStyle.standard,
  pureBlackDark: true,
);

MaterialApp(
  theme: appearance.lightTheme,
  darkTheme: appearance.darkTheme,
  themeMode: ThemeMode.system,
  home: const MyPage(),
)
```

Two built-in styles are available:

- `SkyloomVisualStyle.standard`: rounded Material 3 surfaces
- `SkyloomVisualStyle.brutalism`: square corners, heavy outlines, strong type,
  and harder elevation

Provide `lightColorScheme` and `darkColorScheme` for complete brand control.
`SkyloomThemeController` can switch brightness, style, and seed color at
runtime:

```dart
controller.toggleBrightness(Theme.of(context).brightness);
controller.toggleVisualStyle();
controller.setSeedColor(Colors.orange);
controller.setThemeMode(ThemeMode.system);
```

The example's **Themes** screen compares both styles using the same live form.

## Material, Cupertino, and custom UI

The schema parser, controllers, validation engine, and renderer contract are
UI-independent. The ready-to-use `SkyloomForm` shell and its built-in renderers
use Material 3.

Custom `SkyloomFieldRenderer` implementations may return any Flutter widget,
including Cupertino or widgets from another UI library:

```dart
import 'package:flutter/cupertino.dart';

final class CupertinoSwitchRenderer implements SkyloomFieldRenderer {
  const CupertinoSwitchRenderer();

  @override
  Widget build(BuildContext context, SkyloomRendererContext field) {
    return Row(
      children: [
        Expanded(child: Text(field.fieldSchema.label ?? field.fieldPath)),
        CupertinoSwitch(
          value: field.value == true,
          onChanged: field.fieldController.enabled
              ? (value) => field.setValue(value)
              : null,
        ),
      ],
    );
  }
}

SkyloomForm(
  schema: employeeSchema,
  renderers: const {
    FormType.switchField: CupertinoSwitchRenderer(),
  },
)
```

This supports mixed or field-level Cupertino rendering today. A complete
Cupertino form shell—including Cupertino sections, actions, progress, dialogs,
and error presentation—is not bundled yet.

## Controller API

Use `SkyloomFormController` when code outside the widget must manage the form:

```dart
final controller = SkyloomFormController(schema: employeeSchema);

controller.setValue('name', 'Asha');
controller.value('name');
controller.values;
controller.validate();
controller.reset();

SkyloomForm(
  schema: employeeSchema,
  controller: controller,
  onSubmit: saveEmployee,
)
```

The controller also manages arrays, async state, step navigation, server
errors, focus/reveal requests, and JSON-safe submitted values.

## Run the example

The example is an interactive component and schema explorer with live previews
for all built-in fields and both visual styles.

```console
flutter run -t example/main.dart -d chrome
```

Use any available Flutter device instead of `chrome` when preferred.

## More documentation

- [Schema 1.0 reference](doc/schema-v1.md)
- [Example overview](example/example.md)
- [Changelog](CHANGELOG.md)
- [API documentation](https://pub.dev/documentation/skyloom_schema/latest/)

## Development checks

```console
dart analyze
flutter test
flutter pub publish --dry-run
```

## License

MIT. See [LICENSE](LICENSE).
