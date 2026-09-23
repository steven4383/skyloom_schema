<p align="center">
  <img src="assets/branding/skyloom-logo-mark.png" width="160" alt="Skyloom logo: a woven-thread S monogram in green">
</p>

# skyloom_schema

`skyloom_schema` is a headless-first, schema-driven Flutter form engine.
It converts JSON-compatible definitions into validated, reactive Flutter forms
while keeping rendering replaceable.

> Define the form once. Render it anywhere in Flutter.

## Project status

The package is currently at version `0.10.0-dev.1`.

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
- Required, length, numeric, email, URL, pattern, regex, and cross-field
  validation
- Change, blur, submit, and manual validation modes
- Named custom validators
- Backend field-error APIs
- A replaceable field-renderer registry
- `SkyloomForm` and `SkyloomForm.fromJson`
- Theme-aware Material renderers for all initial field types
- Built-in scrolling, padding, and local input-decoration styling
- Conditional visibility, required, enabled, disabled, and read-only state
- Nested `all`, `any`, and `not` condition groups
- Recursive object fields with deep Material 3 rendering
- Primitive, object, and nested arrays with add, remove, duplicate, and reorder
- Array bounds, default items, recursive validation, and JSON output
- Dependency graphs with clear, preserve, revalidate, and reload hooks
- Registered async option sources with search, pagination, mapping, and cache
- Debounced async validation with cancellation and latest-value protection
- Responsive mobile, tablet, and desktop field spans
- Ordered and collapsible form sections
- Collapsed-section validation summaries
- Horizontal or vertical radio layouts and choice/filter chips
- Ordered and conditional multi-step workflows with per-step validation
- Next, back, and programmatic step navigation
- JSON-compatible workflow save and restore snapshots
- Unified field, server, and form-level error summaries
- Automatic invalid-field navigation across steps and collapsed sections
- Lazy top-level rendering and isolated field repaints for large forms
- Accessible step progress and live validation announcements
- Controller-driven reveal/focus navigation across steps and sections
- Structured backend error mapping with unknown-field policies
- Guarded step transitions and completed-step tracking
- Structured validation errors with stable codes and localizable messages
- Multi-error schema diagnostics with configurable complexity limits
- Provider-neutral single and multiple file-upload fields

See [CHANGELOG.md](CHANGELOG.md) for release history and compatibility notes.

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
  `-- application-defined renderers
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
default Material interface or application-specific renderers.

## Parsing a schema

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

### Dart field-type constants

Use `FormType` when authoring a schema in Dart to avoid repeated magic strings
while keeping the resulting data JSON-compatible:

```dart
const field = {
  'key': 'email',
  'type': FormType.email,
  'validation': {
    ValidationRule.required: true,
    ValidationRule.email: true,
  },
};
```

`FormType.switchField` represents the JSON value `"switch"`; the longer Dart
name is necessary because `switch` is a language keyword. JSON received from a
server continues to use ordinary strings such as `"text"` and `"select"`.

### Typed Dart schemas with autocomplete

For schemas authored inside a Flutter application, use the typed builder API
instead of a large `Map<String, Object?>`. Field factories expose named Dart
parameters and still produce the same validated `FormSchema`:

```dart
final employeeSchema = SkyloomSchema.form(
  id: 'employee_registration',
  title: 'Employee Registration',
  fields: [
    SkyloomField.text(
      key: 'name',
      label: 'Full name',
      placeholder: 'Enter the employee name',
      validation: SkyloomValidation.rules(
        required: true,
        minLength: 2,
        maxLength: 80,
      ),
    ),
    SkyloomField.email(
      key: 'email',
      label: 'Email address',
      validation: SkyloomValidation.rules(required: true, email: true),
    ),
    SkyloomField.select(
      key: 'role',
      label: 'Role',
      options: [
        FieldOption(label: 'Developer', value: 'developer'),
        FieldOption(label: 'Manager', value: 'manager'),
      ],
      validation: SkyloomValidation.rules(required: true),
    ),
    SkyloomField.object(
      key: 'address',
      label: 'Address',
      fields: [
        SkyloomField.text(key: 'city', label: 'City'),
      ],
    ),
  ],
);

SkyloomForm(
  schema: employeeSchema,
  onSubmit: (values) => debugPrint('$values'),
);
```

Use this API for locally authored forms and `SkyloomForm.fromJson` or
`SchemaParser.parse` for schemas received from JSON. `employeeSchema.toJson()`
converts the typed definition back to the same JSON-compatible representation.

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

For editors, CI, remote schemas, and AI-generated schemas, use `validate` to
collect independent problems instead of stopping at the first one:

```dart
const parser = SchemaParser(
  unknownFieldTypePolicy: SchemaUnknownFieldTypePolicy.warning,
  limits: SchemaLimits(maxFields: 200, maxNestingDepth: 8),
);

final result = parser.validate(candidateSchema);
for (final diagnostic in result.diagnostics) {
  print('${diagnostic.severity.name} ${diagnostic.code} '
      '${diagnostic.path}: ${diagnostic.message}');
}

if (result.isValid) {
  final schema = result.schema!;
}
```

`parse` remains the fail-fast runtime API. It also enforces the configured
field, nesting, array, option, and condition limits before building a schema.
Unknown custom field types remain allowed by default; warning and error modes
are opt-in because applications can register their own renderers.

The full foundation contract is documented in the
[schema 1.0 specification](doc/schema-v1.md).

## Complete schema and values example

The following example uses APIs available in `0.10.0-dev.1`. It defines a form,
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
        'key': 'address',
        'type': FormType.object,
        'label': 'Address',
        'fields': [
          {'key': 'city', 'type': FormType.text, 'label': 'City'},
          {
            'key': 'country',
            'type': FormType.select,
            'label': 'Country',
            'options': [
              {'label': 'India', 'value': 'IN'},
              {'label': 'United States', 'value': 'US'},
            ],
          },
        ],
      },
      {
        'key': 'emergencyContacts',
        'type': FormType.array,
        'label': 'Emergency contacts',
        'minItems': 1,
        'items': {
          'type': FormType.object,
          'fields': [
            {'key': 'name', 'type': FormType.text, 'label': 'Name'},
            {'key': 'phone', 'type': FormType.text, 'label': 'Phone'},
          ],
        },
      },
    ],
};

void main() {

  final schema = const SchemaParser().parse(employeeSchemaJson);

  final controller = SkyloomFormController(schema: schema);
  controller.patchValues({
    'name': 'Steven',
    'email': 'steven@example.com',
    'age': 27,
    'password': 'temporary-password',
    'notes': 'Remote employee',
    'role': 'developer',
    'contactPreference': 'email',
    'acceptedTerms': true,
    'dateOfBirth': '1999-05-14',
    'address': {'city': 'Chennai', 'country': 'IN'},
  });
  controller.setValue('emergencyContacts', [
    {'name': 'Alex', 'phone': '+91 90000 00000'},
  ]);

  print('Form: ${schema.title}');
  print(const JsonEncoder.withIndent('  ').convert(controller.values));
  controller.dispose();
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
  },
  "emergencyContacts": [
    {"name": "Alex", "phone": "+91 90000 00000"}
  ]
}
```

The same schema can be passed directly to the form widget:

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
  padding: const EdgeInsets.all(16),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
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
controller.loadJson(existingEmployee); // New pristine edit baseline.
controller.clear();
controller.submit();

// Multi-step workflow control and persistence.
controller.validateCurrentStep();
await controller.validateCurrentStepAsync();
await controller.nextStep();
await controller.previousStep();
await controller.goToStep('contact');
final savedState = controller.saveState();
controller.restoreState(savedState);

// Server and form-level errors.
controller.setError('email', 'Email already exists.');
controller.setFormErrors(['The request could not be completed.']);
```

Each field controller tracks its value, initial value, dirty, touched, focused,
valid, loading, visible, enabled, and read-only states. Controllers use Flutter
listenable primitives internally without requiring Riverpod,
Bloc, Provider, GetX, or another state-management framework.

### Validation timing

```dart
SkyloomForm.fromJson(
  schema: employeeSchemaJson,
  validationMode: SkyloomValidationMode.onBlur,
);
```

Available modes are `onChange`, `onBlur`, `onSubmit`, and `manual`. Manual mode
leaves validation entirely under controller control. In `onBlur` and
`onSubmit` modes, a field that already displays an error is revalidated as the
user corrects it, so field and summary errors do not remain stale.

### Custom validators

Reference validators by name in JSON and register their Dart implementations
on the form:

```dart
const employeeIdField = {
  'key': 'employeeId',
  'type': FormType.text,
  'validation': {
    ValidationRule.custom: ['employeeIdFormat'],
  },
};

SkyloomForm.fromJson(
  schema: employeeSchemaJson,
  validators: {
    'employeeIdFormat': (value, context) {
      return value is String && value.startsWith('EMP-')
          ? null
          : 'Employee IDs must start with EMP-.';
    },
  },
);
```

### Structured errors and localization

The existing string error API remains available as `field.error`. For logic,
analytics, accessibility, and translated interfaces, use the structured form:

```dart
final failure = controller.field('email').validationError;
print(failure?.code);      // invalidEmail
print(failure?.arguments); // Rule-specific interpolation values.
print(failure?.message);   // Localized display text.
```

Provide validation and package-owned Material copy without changing behavior
by extending `SkyloomMessages`. English defaults are inherited for members you
do not override:

```dart
final class AppMessages extends SkyloomMessages {
  const AppMessages();

  @override
  String validationMessage(
    String code, {
    required String label,
    Map<String, Object?> arguments = const {},
  }) {
    return switch (code) {
      SkyloomValidationCode.required => '$label is mandatory.',
      _ => '$label is invalid.',
    };
  }

  @override
  String get chooseFile => 'Select a document';
}

SkyloomForm.fromJson(
  schema: schemaJson,
  messages: const AppMessages(),
);
```

Rule-level `message` values still take precedence. When supplying an existing
controller, configure its `ValidationEngine(messages: ...)` directly.

### Conditional fields

```dart
{
  'key': 'companyName',
  'type': FormType.text,
  'visibleWhen': {
    'field': 'accountType',
    'equals': 'business',
  },
  'requiredWhen': {
    'field': 'accountType',
    'equals': 'business',
  },
}
```

Conditions support `equals`, `notEquals`, `contains`, `notContains`, `in`,
`notIn`, `empty`, `notEmpty`, numeric/date comparisons, and nested `all`, `any`,
and `not` groups. They can control visibility, required, enabled, disabled, and
read-only state.

### Cross-field validation

Comparison rules reference another field path and work with numbers, numeric
strings, ISO dates, and nested paths:

```dart
{
  'key': 'startDate',
  'type': FormType.date,
},
{
  'key': 'endDate',
  'type': FormType.date,
  'dependsOn': ['startDate'],
  'validation': {
    ValidationRule.greaterThan: 'startDate',
    ValidationRule.maxDate: '2027-12-31',
  },
}
```

Available rules are `sameAs`, `notSameAs`, `greaterThan`,
`greaterThanOrEqual`, `lessThan`, and `lessThanOrEqual`. Custom validators can
read the complete value tree from `context.values`. Date fields also support
inclusive ISO `minDate` and `maxDate` rules. The Material date picker combines
those static limits with date comparison rules, disabling dates outside the
valid range. Declare the referenced field in `dependsOn` to revalidate an
existing end date when its start date changes.

### Nested object fields

Objects can be nested to any depth. Child controllers use full paths such as
`company.address.city`, while submitted values retain their object shape:

```dart
{
  'key': 'address',
  'type': FormType.object,
  'label': 'Address',
  'fields': [
    {'key': 'city', 'type': FormType.text, 'label': 'City'},
    {'key': 'country', 'type': FormType.text, 'label': 'Country'},
  ],
}
```

### Repeatable arrays

Arrays support primitive items, object groups, and nested arrays:

```dart
{
  'key': 'employees',
  'type': FormType.array,
  'label': 'Employees',
  'minItems': 1,
  'maxItems': 10,
  'defaultItem': {'name': '', 'email': ''},
  'items': {
    'type': FormType.object,
    'fields': [
      {'key': 'name', 'type': FormType.text, 'label': 'Name'},
      {'key': 'email', 'type': FormType.email, 'label': 'Email'},
    ],
  },
}
```

The default Material renderer includes item controls. Controller APIs are
also available directly: `addArrayItem`, `removeArrayItem`,
`duplicateArrayItem`, and `reorderArrayItem`.

### Field dependencies

Declare dependency edges in the schema:

```dart
{
  'key': 'state',
  'type': FormType.select,
  'dependsOn': ['country'],
  'dependencyConfig': {
    'clearOnChange': true,
    'revalidateOnChange': true,
    'reloadDataOnChange': true,
    'preserveValueIfValid': false,
  },
}
```

When `country` changes, the controller processes `state` and then any fields
that depend on `state`. Circular graphs and unknown dependency paths are
rejected. Use `SkyloomForm.onDependencyChanged` or the corresponding
controller callback for application-specific side effects. Fields with a
registered `dataSource` reload automatically when `reloadDataOnChange` is true.

### Async data sources

Reference an application handler without placing network code in JSON:

```dart
const stateField = {
  'key': 'state',
  'type': FormType.select,
  'dependsOn': ['country'],
  'dataSource': {
    'handler': 'states',
    'pageSize': 20,
    'debounceMilliseconds': 300,
    'mapping': {
      'label': 'displayName',
      'value': 'code',
      'metadata': 'metadata',
    },
  },
};

SkyloomForm.fromJson(
  schema: schemaJson,
  dataSources: {
    'states': (request) async {
      final country = request.dependencyValues['country'];
      return api.searchStates(
        country: country,
        query: request.search,
        page: request.page,
        pageSize: request.pageSize,
      );
    },
  },
);
```

Handlers may return `SkyloomDataSourceResult`, a list of values/maps, or a map
containing `items` and `hasMore`. The Material select renderer supplies search,
debounce, pagination, infinite scrolling, retry, loading, empty, and error
states. The controller caches results and ignores cancelled or stale requests.

### Async validation

```dart
const usernameField = {
  'key': 'username',
  'type': FormType.text,
  'asyncValidation': {
    'handler': 'usernameAvailable',
    'debounceMilliseconds': 350,
    'cache': true,
  },
};

SkyloomForm.fromJson(
  schema: schemaJson,
  asyncValidators: {
    'usernameAvailable': (value, context) async {
      final available = await accountApi.isUsernameAvailable('$value');
      return available ? null : 'This username is already in use.';
    },
  },
);
```

Async validators expose idle, validating, success, and failure states. Change
and blur modes debounce validation, stale results cannot overwrite newer
values, results can be cached, and submission waits for validation to finish.

### File uploads

`FormType.file` renders a single or multiple upload field. The schema stores
constraints and a handler name; the application owns file picking, transport,
permissions, authentication, retries, and storage. This keeps the package
portable across mobile, desktop, and web without forcing a picker or backend.

```dart
const resumeField = {
  'key': 'documents',
  'type': FormType.file,
  'label': 'Documents',
  'upload': {
    'handler': 'documentUpload',
    'multiple': true,
    'accept': ['application/pdf', 'image/*', '.docx'],
    'maxBytes': 5000000,
    'maxFiles': 3,
  },
};

SkyloomForm.fromJson(
  schema: schemaJson,
  fileUploadHandlers: {
    'documentUpload': (request) async {
      final uploaded = await pickAndUploadFiles(
        acceptedTypes: request.configuration.accept,
      );
      return [
        for (final item in uploaded)
          SkyloomUploadedFile(
            id: item.id,
            name: item.name,
            url: item.url,
            mimeType: item.mimeType,
            size: item.size,
          ),
      ];
    },
  },
);
```

Form values contain JSON-safe uploaded-file references, never binary bytes:

```json
{
  "documents": [
    {
      "id": "file_123",
      "name": "resume.pdf",
      "url": "https://cdn.example.com/file_123",
      "mimeType": "application/pdf",
      "size": 248312
    }
  ]
}
```

The engine validates value shape, file count, byte size, exact MIME types,
MIME wildcards such as `image/*`, and filename extensions such as `.pdf`.

### Responsive UI schema

Keep layout decisions separate from validation and value structure:

```dart
const schemaJson = {
  'id': 'profile',
  'fields': [
    {'key': 'firstName', 'type': FormType.text},
    {'key': 'lastName', 'type': FormType.text},
  ],
  'uiSchema': {
    'firstName': {
      'layout': {'mobile': 12, 'tablet': 6, 'desktop': 6},
      'order': 1,
    },
    'lastName': {
      'layout': {'mobile': 12, 'tablet': 6, 'desktop': 6},
      'order': 2,
    },
  },
};
```

Each device span uses a twelve-column grid. `widget` can override the renderer
type, while `group` and `visualHints` remain available to custom renderers and
application-specific presentation logic.

### Form sections

```dart
'sections': [
  {
    'id': 'identity',
    'title': 'Identity',
    'description': 'Basic employee information',
    'fields': ['firstName', 'lastName'],
    'collapsible': true,
    'defaultExpanded': true,
    'order': 1,
  },
]
```

Fields can belong to at most one section. Unknown field references and
duplicate section IDs are rejected during parsing. Fields omitted from all
sections are rendered after the ordered sections. When submission finds errors
inside a collapsed section, its header displays an error count and the first
message so validation is never hidden from the user.

### Multi-step workflows

Add `steps` to divide every root field into ordered pages. Each root field must
belong to exactly one step. A step can use any normal condition-engine
expression in `visibleWhen`; hidden steps are omitted from navigation and
validation while their values are preserved.

```dart
'steps': [
  {
    'id': 'identity',
    'title': 'Identity',
    'description': 'Tell us who you are.',
    'fields': ['name', 'accountType'],
    'order': 1,
  },
  {
    'id': 'business',
    'title': 'Business details',
    'fields': ['companyName'],
    'order': 2,
    'visibleWhen': {'field': 'accountType', 'equals': 'business'},
  },
  {
    'id': 'contact',
    'title': 'Contact',
    'fields': ['email'],
    'order': 3,
  },
]
```

`SkyloomForm` automatically renders progress plus Back, Next, and Submit
actions. Next validates only the current step, including asynchronous
validators. Customize the labels and progress as needed:

```dart
SkyloomForm.fromJson(
  schema: schemaJson,
  nextButtonLabel: 'Continue',
  backButtonLabel: 'Previous',
  showStepProgress: true,
  onStepChanged: (step) => print(step.id),
);
```

### Unified errors and invalid-field navigation

Field errors and form-level server errors are exposed together through
`controller.errorEntries`. The default Material renderer shows an accessible
summary. Selecting a field error moves to its step, expands its section,
scrolls it into view, and focuses it when possible.

```dart
controller.setErrors({
  'email': 'This email address is already registered.',
});
controller.setFormErrors([
  'The employee could not be saved.',
]);

controller.clearError('email');
controller.clearFormErrors();
controller.clearErrors(); // Clears both kinds.
```

Apply a complete backend response in one batched update. Multiple messages for
one field are retained in the displayed field error, and unknown backend keys
can become form errors, be ignored, or throw:

```dart
final result = controller.applyErrors(
  fieldErrors: {
    'email': ['Already registered.', 'Use another address.'],
  },
  formErrors: ['Unable to save the employee.'],
  unknownFieldPolicy: SkyloomUnknownFieldErrorPolicy.formError,
);
```

### Field navigation and guarded steps

Navigation requests remain controller-driven and renderer-independent. The
default Material form changes steps, expands collapsed sections, scrolls, and
focuses when appropriate:

```dart
controller.revealField('address.city');
controller.focusField('email');
```

Applications can guard asynchronous step transitions and optionally enable
direct navigation from the Material progress chips:

```dart
SkyloomForm.fromJson(
  schema: schemaJson,
  allowStepNavigation: true,
  onStepChanging: (change) async {
    return canLeaveStep(change.from.id);
  },
);
```

The controller exposes `navigatingSteps`, `completedStepIds`,
`isStepComplete`, and `stepErrorCount` for custom workflow interfaces.

### Radio direction and chips

Radio fields use a vertical column by default. Set a UI hint for a compact
horizontal layout:

```dart
'uiSchema': {
  'contactPreference': {
    'visualHints': {
      FormUiHint.radioDirection: FormUiDirection.row,
    },
  },
}
```

Use `FormType.chip` for a single-select choice-chip group. Set
`FormUiHint.multiSelect` to `true` to render filter chips whose value is a
JSON-compatible list:

```dart
{
  'key': 'skills',
  'type': FormType.chip,
  'label': 'Skills',
  'options': [
    {'label': 'Flutter', 'value': 'flutter'},
    {'label': 'Dart', 'value': 'dart'},
  ],
}

'uiSchema': {
  'skills': {
    'visualHints': {FormUiHint.multiSelect: true},
  },
}
```

## Default Material 3 interface

`skyloom_schema` includes a basic Material renderer so a schema produces a
usable form without installing another UI package. It covers the standard field
types:

- Text, email, password, number, and textarea
- Checkbox, radio, and switch
- Select
- Date
- Choice and filter chips
- Single and multiple file uploads through application callbacks
- Nested object groups
- Primitive, object, and nested repeatable arrays

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

`SkyloomFormLayout.scrollable` is the default, preventing large forms from
overflowing when the form receives a bounded height. Use
`SkyloomFormLayout.column` when a parent `ListView` or another scrollable widget
already owns scrolling. Use `SkyloomFormLayout.lazy` for large forms with many
top-level sections; it uses `ListView.builder`, accepts `cacheExtent`, and
builds section blocks on demand. Individual fields remain independently
reactive and are isolated with repaint boundaries.

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

Those capabilities are intentionally outside this package's public scope.

## Running checks

```console
flutter analyze
flutter test
flutter run -t example/main.dart
```

Every parser, controller, validation, condition, dependency, and serialization
feature should receive unit tests. Renderer behavior should receive Flutter
widget tests, and every fixed bug should receive a regression test.
