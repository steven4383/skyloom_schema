# Skyloom Schema example

The package example is an interactive documentation studio for every built-in
field renderer and the Schema 1.0 contract.

Run it from the package root:

```sh
flutter run example/main.dart
```

The component explorer includes:

- Live previews for all 14 built-in field types
- Expandable, copyable JSON schemas
- Common and type-specific property notes
- Form, field, and validation API reference tables
- Guides for responsive layouts, conditions, dependencies, remote options,
  workflows, and controller integration

## Minimal form

```dart
import 'package:flutter/material.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

class ProfileForm extends StatelessWidget {
  const ProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return SkyloomForm.fromJson(
      schema: const {
        'id': 'profile',
        'fields': [
          {
            'key': 'name',
            'type': FormType.text,
            'label': 'Name',
            'validation': {'required': true},
          },
          {
            'key': 'email',
            'type': FormType.email,
            'label': 'Email',
            'validation': {'required': true, 'email': true},
          },
        ],
      },
      onSubmit: (values) => debugPrint('$values'),
    );
  }
}
```

See the package `README.md` for integration documentation and
`doc/schema-v1.md` for the complete schema contract.
