# Skyloom form schema 1.0

This document defines the foundation schema supported by
`skyloom_schema` 0.0.1. Later releases may add interpreted properties without
breaking this contract.

## Form object

```json
{
  "schemaVersion": "1.0",
  "id": "create_employee",
  "title": "Create Employee",
  "description": "Employee onboarding form",
  "fields": [],
  "metadata": {}
}
```

- `id` is a required, non-empty string.
- `fields` is a required array. An empty form is valid.
- `schemaVersion` is an optional string and defaults to `1.0`.
- `title` and `description` are optional strings.
- `metadata` is an optional JSON object owned by the application.

## Field object

Every field requires a non-empty `key` and `type`. A type is a string, not a
closed enum, because applications can register custom field renderers.

Common optional properties are:

- `label`, `description`, `helperText`, and `placeholder` strings
- `defaultValue`, which may be any JSON value including explicit `null`
- `required`, `disabled`, `readOnly`, and `hidden` booleans (default `false`)
- `options`, an array of label/value objects
- `validation`, an open JSON object whose keys name validation rules
- `metadata`, an application-owned JSON object

The parser preserves unknown properties in `additionalProperties`. This lets a
0.0.1 consumer safely parse future properties such as `visibleWhen`, although
the current engine does not interpret them.

## Field keys and value paths

Keys use dot-separated identifiers with optional numeric array indexes:

```text
name
address.city
employees[0].name
matrix[0][1]
```

An identifier begins with a letter or underscore and may then contain letters,
digits, underscores, or hyphens. Dots are structural and cannot be escaped as
literal key characters. Field keys must be unique within a form.

## Options

Each option requires:

- `label`: a non-empty string
- `value`: any JSON-compatible value, including `null`

An option can also have `metadata`. Unknown option properties are preserved.

## JSON values

Accepted values are `null`, strings, booleans, finite numbers, arrays, and
objects with string keys. Dart-specific values such as `DateTime` are rejected.
Dates will be represented as ISO 8601 strings at the schema/value boundary.

Missing and explicit `null` are distinct. For example, omitting `defaultValue`
means there is no default, while `"defaultValue": null` defines a null default.

Parsed collections are immutable. `toJson()` returns a mutable,
JSON-encodable copy.

## Parser errors

Invalid input throws `SchemaParseException`. The exception contains a JSON path
such as `$.fields[1].key` so tooling can point to the failing definition.
