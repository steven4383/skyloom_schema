## 0.6.1

- Add dependency graphs with cycle detection and relative nested paths.
- Add configurable clear, revalidate, reload-hook, and preserve behavior.
- Add `onDependencyChanged` integration for dependent data reloads.

## 0.6.0

- Add primitive, object, and nested array schemas and Material renderers.
- Add array add, remove, duplicate, and reorder controller operations.
- Add `minItems`, `maxItems`, `defaultItem`, and recursive validation.

## 0.5.1

- Add recursively nested object schemas, controllers, values, and Material UI.
- Add deep object defaults, updates, validation, and serialization.

## 0.5.0

- Add equality, numeric, and date-based cross-field validation rules.
- Make all form values available to built-in and custom validators.

## 0.4.0

- Add `visibleWhen`, `hiddenWhen`, `requiredWhen`, `enabledWhen`,
  `disabledWhen`, and `readOnlyWhen` behavior.
- Add condition groups and comparison, membership, and empty-value operators.
- Add automatic field-state updates when dependency values change.
- Add built-in scrolling, padding, and local Material input-decoration themes.
- Add JSON-safe `FormType` and `ValidationRule` constants.

## 0.3.0

- Add URL, `sameAs`, and `notSameAs` validation.
- Add named custom-validator registration and multiple custom validators.
- Add change, blur, submit, and manual validation modes.

## 0.2.0

- Complete form and field dirty, touched, loading, submission, and error state.
- Add edit-data loading as a new pristine baseline.
- Add batched controller notifications and reset-to-initial behavior.

## 0.1.0

- Add `SkyloomForm` and `SkyloomForm.fromJson`.
- Add reactive form and field controllers.
- Add required, length, numeric, email, and pattern validation.
- Add a replaceable renderer registry and renderer context.
- Add theme-aware Material renderers for all initial field types.
- Add a runnable Material 3 example application.

## 0.0.1

- Define the initial Skyloom form schema contract.
- Add immutable form, field, option, and validation models.
- Add schema parsing with path-aware errors and duplicate-key detection.
- Add nested map and array value-path utilities.
