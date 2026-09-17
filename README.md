# skyloom_schema

A headless-first, schema-driven Flutter form engine. Define the form once and
render it anywhere in Flutter.

The package is currently at its architecture-foundation stage. Version 0.0.1
provides immutable schema models, JSON parsing, extension preservation, and
nested value-path utilities. Flutter form rendering and controllers are the
next milestone.

## Basic usage

```dart
import 'package:skyloom_schema/skyloom_schema.dart';

const parser = SchemaParser();

final schema = parser.parse({
  'schemaVersion': '1.0',
  'id': 'create_employee',
  'title': 'Create Employee',
  'fields': [
    {
      'key': 'name',
      'type': 'text',
      'label': 'Name',
      'required': true,
    },
  ],
});

print(schema.fields.first.key); // name
print(schema.toJson());
```

Read the [schema 1.0 specification](docs/schema-v1.md) for the complete
foundation contract.

## Package boundaries

`skyloom_schema` owns schema parsing, form behavior, state, validation,
conditions, dependencies, and serialization. A future `skyloom_ui` package will
own premium visual design, themes, and animations.
