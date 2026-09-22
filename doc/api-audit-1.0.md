# Skyloom 1.0 public API audit

This audit records the public-contract decisions for the future `1.0.0`
release. It was completed against `0.10.0-dev.1`; publishing the stable version
still requires platform verification, benchmarks, release notes, and migration
checks.

## Stability decisions

- Schemas and submitted values remain JSON-compatible. Executable behavior is
  registered in Dart by a stable string handler name.
- Field types remain open strings. `FormType` provides typo-safe built-in
  constants without preventing application renderers.
- `SchemaParser.parse` remains the fail-fast runtime API.
  `SchemaParser.validate` is the accumulating diagnostics API for tooling and
  untrusted or generated definitions.
- Unknown schema properties continue to round-trip for forward compatibility.
  Unknown field types are allowed by default and can be warned about or
  rejected with `SchemaUnknownFieldTypePolicy`.
- Existing string validation APIs remain source-compatible. Structured errors
  add stable codes and arguments through `SkyloomValidationError` and
  `SkyloomErrorEntry`.
- `SkyloomMessages` owns package-provided validation and Material interface
  copy. A schema rule's explicit `message` continues to override the validation
  message resolver.
- File picking and transport remain application responsibilities. Skyloom
  stores only `SkyloomUploadedFile` JSON references and validates declarative
  upload constraints.
- Controller and engine behavior remains renderer-independent. The bundled
  Material 3 implementation is a default renderer, not a required visual
  identity.
- `skyloom_ui` may depend on this package; this package must not depend on
  `skyloom_ui`.

## Compatibility retained

- `SkyloomForm` and `SkyloomForm.fromJson` remain the primary widget APIs.
- `SkyloomFormController`, `SkyloomFieldController`, and their current string
  error members remain available.
- Existing schemas require no migration for structured errors, localization,
  diagnostics, limits, or uploads.
- Default parser behavior continues to accept custom renderer types.
- Existing custom validator callbacks continue to return `String?`.

## Public additions in the final pre-1.0 slice

- `SkyloomValidationCode`, `SkyloomValidationError`
- `SkyloomMessages`, `EnglishSkyloomMessages`
- `SchemaDiagnostic`, `SchemaDiagnosticSeverity`, `SchemaValidationResult`
- `SchemaLimits`, `SchemaUnknownFieldTypePolicy`
- `FileUploadSchema`, `SkyloomUploadedFile`, `SkyloomFileUploadRequest`, and
  `SkyloomFileUploadHandler`
- `FormType.file`

No public member was removed or renamed by this slice.

## Release gate after this audit

Before changing the package version to `1.0.0`, run analyzer and the full test
suite on supported Flutter channels and target platforms, capture large-schema
benchmarks, verify the example application, and write release/migration notes.
Any API change discovered during that work must update this audit and receive a
pre-1.0 migration path.
