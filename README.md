# skyloom_schema

`skyloom_schema` is a headless-first, schema-driven Flutter form engine.
It converts JSON-compatible definitions into validated, reactive Flutter forms
while keeping rendering replaceable.

> Define the form once. Render it anywhere in Flutter.

## Project status

The package is currently at version `0.1.0`, the first usable form-rendering
milestone.

Available now:

- Immutable form, field, option, and validation schema models
- JSON-compatible schema parsing
- Path-aware parsing errors
- Duplicate field-key detection
- Preservation of unknown properties for forward compatibility
- Nested object and array paths such as `address.city` and
  `employees[0].name`
- JSON serialization
- Reactive `SkyloomFormController` and `SkyloomFieldController` state
- Required, length, numeric, email, pattern, and regex validation
- Backend field-error APIs
- A replaceable field-renderer registry
- `SkyloomForm` and `SkyloomForm.fromJson`
- Theme-aware Material renderers for all initial field types

Conditional logic, arrays, async data, async validation, sections, and
multi-step workflows remain on the roadmap.

## How the complete system works

```text
JSON definition
      |
      v
SchemaParser
      |
      v
FormSchema and FieldSchema
      |
      v
Form engine
  |-- form and field controllers
  |-- validation
  |-- conditions and dependencies
  |-- async data and validation
  `-- serialization
      |
      v
Renderer registry
  |-- default Material 3 renderers
  `-- application or skyloom_ui renderers
      |
      v
Flutter form
      |
      v
JSON-compatible values
```

The engine owns form behavior. Renderers receive the current schema and
controller state, display the appropriate widget, and send user changes back
to the controller. This separation allows the same form definition to use the
default Material interface, an application-specific renderer, or the future
`skyloom_ui` component library.

## Using the foundation API

Parse a JSON-compatible Dart map with `SchemaParser`:

```dart
import 'package:skyloom_schema/skyloom_schema.dart';

const parser = SchemaParser();

final schema = parser.parse({
  'schemaVersion': '1.0',
  'id': 'create_employee',
  'title': 'Create Employee',
  'description': 'Employee onboarding form',
  'fields': [
    {
      'key': 'name',
      'type': FormType.text,
      'label': 'Name',
      'placeholder': 'Enter your name',
      'required': true,
    },
    {
      'key': 'role',
      'type': FormType.select,
      'label': 'Role',
      'options': [
        {'label': 'Developer', 'value': 'developer'},
        {'label': 'QA', 'value': 'qa'},
      ],
    },
  ],
});

print(schema.id); // create_employee
print(schema.fields.first.key); // name
```

`SchemaParser.parse` accepts decoded JSON data, validates its structure, and
returns an immutable `FormSchema`. Field types remain strings instead of a
closed enum so custom renderer types can be introduced later.

### Reading JSON text

```dart
import 'dart:convert';

final decoded = jsonDecode(jsonText);
final schema = const SchemaParser().parse(decoded);
```

### Serializing a schema

```dart
final jsonMap = schema.toJson();
final jsonText = jsonEncode(jsonMap);
```

`toJson()` returns a mutable, JSON-encodable copy. Parsed schema collections
remain immutable.

### Nested values

`PathUtils` reads and writes values using the same path format as field keys:

```dart
final values = <String, Object?>{};

PathUtils.setValue(values, 'address.city', 'Chennai');
PathUtils.setValue(values, 'employees[0].name', 'Steven');

final city = PathUtils.getValue(values, 'address.city');
final hasName = PathUtils.contains(values, 'employees[0].name');
```

`contains` distinguishes an absent path from a path whose value is explicitly
`null`.

### Schema errors

Invalid definitions throw `SchemaParseException` with the exact JSON path:

```dart
try {
  const SchemaParser().parse(invalidSchema);
} on SchemaParseException catch (error) {
  print(error.path);    // $.fields[1].key
  print(error.message); // Field key "email" is duplicated.
}
```

The full foundation contract is documented in the
[schema 1.0 specification](docs/schema-v1.md).

## Complete schema and values example

The following example uses APIs available in `0.1.0`. It defines a form,
parses it, creates nested values, and produces JSON-compatible output.

Validation definitions are parsed with the schema and executed when the schema
is attached to a `SkyloomFormController` or `SkyloomForm`.

```dart
import 'dart:convert';

import 'package:skyloom_schema/skyloom_schema.dart';

const employeeSchemaJson = <String, Object?>{
    'schemaVersion': '1.0',
    'id': 'employee_registration',
    'title': 'Employee Registration',
    'description': 'Create an employee profile.',
    'metadata': {
      'department': 'engineering',
    },
    'fields': [
      {
        'key': 'name',
        'type': 'text',
        'label': 'Full name',
        'placeholder': 'Enter the employee name',
        'validation': {
          'required': true,
          'minLength': 2,
          'maxLength': 80,
        },
      },
      {
        'key': 'email',
        'type': 'email',
        'label': 'Email address',
        'placeholder': 'employee@example.com',
        'validation': {
          'required': true,
          'email': true,
        },
      },
      {
        'key': 'age',
        'type': 'number',
        'label': 'Age',
        'validation': {
          'min': 18,
          'max': 100,
        },
      },
      {
        'key': 'password',
        'type': 'password',
        'label': 'Temporary password',
        'validation': {
          'required': true,
          'minLength': 8,
        },
      },
      {
        'key': 'notes',
        'type': 'textarea',
        'label': 'Notes',
        'helperText': 'Optional onboarding information',
      },
      {
        'key': 'role',
        'type': 'select',
        'label': 'Role',
        'options': [
          {'label': 'Developer', 'value': 'developer'},
          {'label': 'Quality Analyst', 'value': 'qa'},
          {'label': 'Manager', 'value': 'manager'},
        ],
        'validation': {
          'required': true,
        },
      },
      {
        'key': 'contactPreference',
        'type': 'radio',
        'label': 'Preferred contact method',
        'options': [
          {'label': 'Email', 'value': 'email'},
          {'label': 'Phone', 'value': 'phone'},
        ],
      },
      {
        'key': 'notificationsEnabled',
        'type': 'switch',
        'label': 'Enable notifications',
        'defaultValue': true,
      },
      {
        'key': 'acceptedTerms',
        'type': 'checkbox',
        'label': 'Accept the terms',
        'defaultValue': false,
        'validation': {
          'required': true,
        },
      },
      {
        'key': 'dateOfBirth',
        'type': 'date',
        'label': 'Date of birth',
        'metadata': {
          'dateFormat': 'yyyy-MM-dd',
        },
      },
      {
        'key': 'address.city',
        'type': 'text',
        'label': 'City',
      },
      {
        'key': 'address.country',
        'type': 'select',
        'label': 'Country',
        'options': [
          {'label': 'India', 'value': 'IN'},
          {'label': 'United States', 'value': 'US'},
        ],
      },
    ],
};

void main() {

  final schema = const SchemaParser().parse(employeeSchemaJson);

  final values = <String, Object?>{};

  // Apply defaults. A later FormController will do this automatically.
  for (final field in schema.fields) {
    if (field.hasDefaultValue) {
      PathUtils.setValue(values, field.key, field.defaultValue);
    }
  }

  // Simulate values that will eventually come from Flutter field renderers.
  PathUtils.setValue(values, 'name', 'Steven');
  PathUtils.setValue(values, 'email', 'steven@example.com');
  PathUtils.setValue(values, 'age', 27);
  PathUtils.setValue(values, 'password', 'temporary-password');
  PathUtils.setValue(values, 'notes', 'Remote employee');
  PathUtils.setValue(values, 'role', 'developer');
  PathUtils.setValue(values, 'contactPreference', 'email');
  PathUtils.setValue(values, 'acceptedTerms', true);
  PathUtils.setValue(values, 'dateOfBirth', '1999-05-14');
  PathUtils.setValue(values, 'address.city', 'Chennai');
  PathUtils.setValue(values, 'address.country', 'IN');

  print('Form: ${schema.title}');
  print(const JsonEncoder.withIndent('  ').convert(values));
}
```

The printed values above are demonstration data. Do not log passwords or other
sensitive form values in production applications.

The resulting value object is:

```json
{
  "notificationsEnabled": true,
  "acceptedTerms": true,
  "name": "Steven",
  "email": "steven@example.com",
  "age": 27,
  "password": "temporary-password",
  "notes": "Remote employee",
  "role": "developer",
  "contactPreference": "email",
  "dateOfBirth": "1999-05-14",
  "address": {
    "city": "Chennai",
    "country": "IN"
  }
}
```

Once the controller and default Material renderer are implemented, the same
schema will be passed directly to the form widget:

```dart
class EmployeeFormPage extends StatelessWidget {
  const EmployeeFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SkyloomForm.fromJson(
          schema: employeeSchemaJson,
          initialValues: const {
            'address': {'country': 'IN'},
          },
          onChanged: (values) {
            debugPrint('$values');
          },
          onSubmit: (values) {
            debugPrint('Submitted: $values');
          },
        ),
      ),
    );
  }
}
```

## Flutter form API

Use `SkyloomForm.fromJson` to parse and render a schema in one step:

```dart
SkyloomForm.fromJson(
  schema: employeeSchemaJson,
  initialValues: const {
    'name': 'Steven',
  },
  onChanged: (values) {
    print(values);
  },
  onSubmit: (values) {
    print(values);
  },
);
```

Create a controller when the surrounding application needs programmatic access
to form state:

```dart
final schema = const SchemaParser().parse(employeeSchemaJson);
final controller = SkyloomFormController(
  schema: schema,
  initialValues: const {
    'name': 'Steven',
  },
);

controller.value('email');
controller.setValue('email', 'test@example.com');
controller.patchValues({'name': 'Steven'});
controller.validate();
controller.reset();
controller.clear();
controller.submit();
```

Each field controller tracks its value, initial value, dirty, touched, focused,
valid, loading, visible, enabled, and read-only states. Controllers use Flutter
listenable primitives internally without requiring Riverpod,
Bloc, Provider, GetX, or another state-management framework.

## Default Material 3 interface

`skyloom_schema` includes a basic Material renderer so a schema produces a
usable form without installing another UI package. It covers the standard field
types:

- Text, email, password, number, and textarea
- Checkbox, radio, and switch
- Select
- Date

The default renderer is functional, accessible, and theme-aware. It reads
`Theme.of(context)`, `ColorScheme`, and the application's component themes. It
does not install a theme, force colors, or own Skyloom's premium visual
identity.

The consuming application enables and configures Material 3:

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.indigo,
  ),
  home: const EmployeeFormPage(),
);
```

This keeps generated forms consistent with the host application's design.

## Relationship with skyloom_ui

The future `skyloom_ui` package will build on the renderer contract to provide
Skyloom's polished component library.

| Responsibility                    | `skyloom_schema` | `skyloom_ui` |
| --------------------------------- | ------------------ | -------------- |
| Schema parsing                    | Owns               | Uses           |
| Values and state                  | Owns               | Observes       |
| Validation and conditions         | Owns               | Displays       |
| Serialization                     | Owns               | Uses           |
| Basic Material widgets            | Provides           | Can replace    |
| Brand styling and themes          | Does not own       | Owns           |
| Animations and premium components | Does not own       | Owns           |

The dependency direction is always:

```text
skyloom_ui --> skyloom_schema
```

`skyloom_schema` must never depend on `skyloom_ui`. Applications will be able
to replace one renderer, register an application-specific field, or install a
complete renderer collection supplied by `skyloom_ui`.

```dart
// Illustrative future API.
SkyloomForm.fromJson(
  schema: schemaJson,
  renderers: SkyloomUiRenderers.defaults,
);
```

## Package boundaries

`skyloom_schema` owns:

- Schema parsing and versioning
- Form and field state
- Validation and errors
- Conditions and dependencies
- Async data and async validation
- Value serialization
- Renderer contracts
- A basic Material 3 renderer

It does not own:

- Premium visual design
- An opinionated application theme
- A visual drag-and-drop form builder
- A large data grid
- A cloud backend
- Application-specific widgets

Those capabilities belong in packages such as `skyloom_ui`, `skyloom_grid`,
`skyloom_builder`, and `skyloom_cloud`.

## Development order

The current implementation sequence is:

1. Schema specification and parser - complete
2. Nested value paths and JSON serialization - complete
3. `SkyloomFieldController` - complete
4. `SkyloomFormController` - complete
5. Basic validation engine - complete
6. Renderer contract and registry - complete
7. Material 3 text-field vertical slice - complete
8. Remaining basic Material fields - complete
9. Conditional logic and dynamic properties
10. Nested objects, arrays, and dependencies
11. Async data and async validation
12. Layout metadata, sections, and multi-step forms
13. Performance, accessibility, documentation, and examples
14. Stable `1.0.0` API

## Running checks

```console
flutter analyze
flutter test
flutter run -t example/main.dart
```

Every parser, controller, validation, condition, dependency, and serialization
feature should receive unit tests. Renderer behavior should receive Flutter
widget tests, and every fixed bug should receive a regression test.
