## 0.10.0-dev.1

- Begin the non-breaking Part 1 architecture split with dedicated Material
  step-progress, error-summary, and action components.
- Add controller-driven reveal and focus requests that the Material renderer
  fulfills across steps and collapsed sections.
- Add structured backend error application with multiple messages and
  configurable unknown-field handling.
- Add asynchronous step-transition guards, navigation loading state,
  completed-step tracking, step error counts, and optional progress-chip
  navigation.
- Use the green woven-thread Skyloom monogram throughout the README, pub.dev
  package metadata, and example documentation app.
- Revalidate displayed field errors as users correct values in blur and submit
  validation modes while preserving fully manual validation.
- Avoid repeating a field label when its validation-summary message already
  includes that label.
- Add inclusive `minDate` and `maxDate` rules and constrain Material date
  calendars using static and cross-field comparison bounds.
- Add stable validation error codes while preserving the existing string error
  API, including distinct custom, async, server, and upload failures.
- Add `SkyloomMessages` with default English validation copy and per-form or
  per-controller localization support.
- Add accumulating schema diagnostics, unknown-field-type policies, and
  defensive field, nesting, array, option, and condition limits.
- Add provider-neutral single and multiple file fields with registered upload
  callbacks, JSON-safe uploaded-file references, and count/size/type checks.
- Complete the non-breaking pre-1.0 public API audit and document its stability
  decisions.
- Fix Feature Guide expansion by isolating code-block page storage, and prevent
  documentation badges from overflowing on narrow screens.
- Add autocomplete-friendly `SkyloomSchema`, `SkyloomField`, and
  `SkyloomValidation` Dart builders while preserving JSON schema support.
- Expand Dartdoc coverage across the public schema, validation, data-source,
  upload, layout, and typed-builder APIs for pub.dev discoverability.
- Keep the published README consumer-focused and move roadmap and release
  planning into pub-excluded maintainer documentation.

## 0.9.2

- Add lazy top-level form rendering and configurable scroll cache extent for
  large forms.
- Isolate field repaints and retain field-level reactive rebuilds.
- Cache the evaluated visible-step list until form values change.
- Add accessible step progress, live error summaries, and automatic
  scroll/focus navigation to invalid fields.

## 0.9.1

- Add unified field-level and form-level error entries.
- Add server/form error APIs and a Material error-summary panel.
- Navigate error-summary actions across steps and expand collapsed sections.

## 0.9.0

- Add ordered and conditional multi-step form schemas.
- Add validated next, back, and go-to navigation to the form controller.
- Add per-step synchronous and asynchronous validation.
- Add JSON-compatible workflow save and restore snapshots.
- Add Material step progress and responsive navigation actions.

## 0.8.2

- Show field-error counts and the first validation message in collapsed section
  headers.
- Add row and column layouts for radio fields through UI visual hints.
- Add a Material chip renderer with single-select and multi-select modes.
- Remove redundant dividers between outlined nested fields.

## 0.8.1

- Add ordered, collapsible form sections with configurable initial expansion.
- Validate section field membership and render unsectioned fields safely.
- Flatten nested Material surfaces and add section/object/array dividers.
- Improve responsive array actions and verify move-up/down behavior.
- Keep explicitly ordered fields ahead of unordered section fields.

## 0.8.0

- Add separate per-field UI schema with renderer overrides and ordering.
- Add responsive mobile, tablet, and desktop twelve-column spans.
- Add responsive Material form layout without coupling layout to data fields.

## 0.7.1

- Add asynchronous validators with debounce, cache, cancellation, and
  latest-value protection.
- Add idle, validating, success, and failure validation states.
- Make form submission await asynchronous validation.

## 0.7.0

- Add registered asynchronous data sources for select fields.
- Add search, debounce, pagination, infinite loading, retry, empty, error,
  caching, response mapping, and stale-request protection.
- Pass dependency values, complete form values, and field metadata to requests.

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
