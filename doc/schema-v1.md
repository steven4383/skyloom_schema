# Skyloom form schema 1.0

This document defines the foundation schema supported by
`skyloom_schema` 0.10.0-dev.1. The contract remains forward-compatible: unknown
properties are preserved during parsing and serialization.

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
- `steps` is an optional array defining a multi-step workflow.

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
- `fields`, required when `type` is `object`
- `items`, required when `type` is `array` (the item key may be omitted)
- `minItems`, `maxItems`, and `defaultItem` for arrays
- `dependsOn`, an array of field paths
- `dependencyConfig`, which configures dependency behavior
- `dataSource`, which names a registered async option handler
- `asyncValidation`, which names a registered async validator
- `upload`, required when `type` is `file`

The parser preserves unknown properties in `additionalProperties`. This lets a
consumer safely parse properties introduced by later releases.

## Validation

The built-in validation engine supports required, string length, numeric
bounds, email, URL, regular-expression, equality, and comparison rules. A rule
may be a direct value or an object containing `value` and a custom `message`.

Date fields use ISO 8601 date strings. `minDate` and `maxDate` are inclusive
static bounds. `greaterThan`, `greaterThanOrEqual`, `lessThan`, and
`lessThanOrEqual` may reference another date field. The Material date picker
uses both kinds of rules to restrict selectable dates.

```json
{
  "key": "endDate",
  "type": "date",
  "dependsOn": ["startDate"],
  "validation": {
    "greaterThanOrEqual": "startDate",
    "maxDate": "2027-12-31"
  }
}
```

Declare comparison sources in `dependsOn` when the target should revalidate
immediately after a source value changes.

## Object and array fields

Object fields recursively contain `fields` and serialize as nested JSON
objects. Array fields contain one `items` schema and serialize as JSON arrays.
Items may be primitives, objects, or other arrays.

```json
{
  "key": "employees",
  "type": "array",
  "minItems": 1,
  "items": {
    "type": "object",
    "fields": [
      {"key": "name", "type": "text"}
    ]
  }
}
```

`minItems` and `maxItems` are non-negative integers and `minItems` cannot
exceed `maxItems`. `defaultItem` may be any JSON-compatible value.

## Dependencies

`dependsOn` declares fields whose changes affect the current field. Relative
paths inside an object resolve against that object before root paths are tried.

`dependencyConfig` supports these booleans:

- `clearOnChange` (default `false`)
- `revalidateOnChange` (default `true`)
- `reloadDataOnChange` (default `false`)
- `preserveValueIfValid` (default `false`)

Dependency paths must exist and the resulting graph must not contain cycles.

## Async data and validation

`dataSource.handler` names a Dart callback registered on `SkyloomFormController`
or `SkyloomForm`. Optional properties are `search`, `pageSize`,
`debounceMilliseconds`, `cache`, and `mapping`. Mapping contains JSON paths for
`label`, `value`, and `metadata`.

`asyncValidation.handler` similarly names a Dart validation callback. Its
optional `debounceMilliseconds` and `cache` properties control request timing
and result reuse. Executable callbacks are never stored in the JSON schema.

## File uploads

A file field declares upload constraints and the name of an application-owned
handler. It never embeds a picker, callback, token, or binary content in the
schema.

```json
{
  "key": "documents",
  "type": "file",
  "label": "Documents",
  "upload": {
    "handler": "documentUpload",
    "multiple": true,
    "accept": ["application/pdf", "image/*", ".docx"],
    "maxBytes": 5000000,
    "maxFiles": 3
  }
}
```

- `handler` is a required non-empty string.
- `multiple` defaults to `false`.
- `accept` is an optional array of MIME types, MIME wildcards, or extensions.
- `maxBytes` is an optional positive per-file byte limit.
- `maxFiles` is positive, defaults to `1` for single uploads and `10` for
  multiple uploads, and must be `1` when `multiple` is false.

A single field value is an uploaded-file object; a multiple field value is an
array of those objects. Each object requires non-empty `id` and `name` strings
and may contain `url`, `mimeType`, non-negative `size`, and JSON-compatible
`metadata`. Values are upload references, not local paths or binary bytes.

## UI schema

The optional root `uiSchema` object is keyed by root field key. Each entry can
contain:

- `widget`: a renderer-type override
- `layout`: `mobile`, `tablet`, and `desktop` spans from 1 through 12
- `order`: an integer display order
- `group`: an optional group identifier
- `visualHints`: application or renderer-owned JSON metadata

UI metadata does not affect the form's value structure.

The default Material renderers currently interpret `radioDirection` (`row` or
`column`) for radio fields and `multiSelect` (boolean) for `chip` fields.

## Sections

The optional root `sections` array groups root fields. Each section requires a
unique `id` and a `fields` array. It can also define `title`, `description`,
`collapsible`, `defaultExpanded`, and `order`. A field cannot belong to more
than one section. Unassigned fields remain valid and render after sections.

## Steps

The optional root `steps` array divides the form into a workflow. When present,
it must be non-empty and every root field must belong to exactly one step. Each
step supports:

- `id`: required unique string
- `fields`: required non-empty array of root field keys
- `title` and `description`: optional strings
- `order`: optional integer, default `0`
- `visibleWhen`: optional condition-engine expression

Fields cannot belong to multiple steps. Unknown, duplicate, or unassigned
fields are rejected during parsing. Steps are sorted by `order` with schema
order used as a stable tie-breaker.

A false `visibleWhen` removes the step from navigation and validation while
preserving its values. Next-step navigation validates only the current step,
including asynchronous validators. Final submission validates all currently
visible steps.

```json
{
  "steps": [
    {
      "id": "identity",
      "title": "Identity",
      "fields": ["name", "accountType"],
      "order": 1
    },
    {
      "id": "business",
      "title": "Business",
      "fields": ["companyName"],
      "order": 2,
      "visibleWhen": {"field": "accountType", "equals": "business"}
    }
  ]
}
```

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

`SchemaParser.validate` provides the accumulating alternative. It returns a
`SchemaValidationResult` containing machine-readable `SchemaDiagnostic`
objects with `code`, `path`, `message`, and `severity`, plus the parsed schema
when no errors prevent parsing.

`SchemaLimits` protects remote and generated definitions by bounding total
fields, field nesting, declared array items, options per field, condition
nesting, and condition nodes. `SchemaUnknownFieldTypePolicy` can allow, warn,
or reject field types outside the parser's configurable known-type set.
