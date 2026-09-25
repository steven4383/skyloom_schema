# Skyloom maintainer notes

This document is for project planning and is excluded from pub.dev packages.
User-facing installation and API documentation belongs in `README.md`.

## Release preparation

The public API audit for `1.0.0` is complete. Before publishing the stable
release, complete broader platform verification, benchmarks, release notes,
and final migration checks. See `doc/api-audit-1.0.md` for compatibility
decisions.

## Package family direction

The schema package owns parsing, controllers, validation, conditions,
serialization, renderer contracts, and the basic Material renderer. It must
remain independent of any branded UI, builder, grid, or backend package.

Possible companion packages may depend on `skyloom_schema`; the dependency
must never point in the opposite direction. Product names, sequencing, and
illustrative APIs remain internal until those packages are ready to publish.

## Completed development sequence

1. Schema specification and parser
2. Nested value paths and JSON serialization
3. Field and form controllers
4. Validation, conditional state, and dependencies
5. Renderer contract and Material field set
6. Nested objects and repeatable arrays
7. Async data and async validation
8. Responsive UI metadata and sections
9. Multi-step forms and unified errors
10. Performance, accessibility, documentation, and examples
11. Structured errors, localization, diagnostics, and complexity limits
12. Provider-neutral file uploads and typed Dart schema builders

## Maintainer checks

```console
flutter analyze
flutter test
flutter pub publish --dry-run
```

Temporarily enable the `public_member_api_docs` lint before release candidates
to identify any newly exposed API without Dartdoc comments.

Run platform-specific example verification before each stable release and add
a regression test for every corrected parser, controller, or renderer defect.

## Remaining visual-style coverage

The standard and brutalism application themes are available. Before treating
both styles as visually complete, audit and explicitly theme these remaining
Material component groups in both light and true-black dark modes:

1. Checkbox, radio, and switch selected, disabled, error, hover, and focus
   states (`CheckboxThemeData`, `RadioThemeData`, and `SwitchThemeData`).
2. Icon buttons and array-item move, duplicate, remove, and overflow actions.
3. Select menus, popup menus, async-search dialogs, loading rows, empty rows,
   and pagination states.
4. Date-picker dialog, calendar day states, year selector, and range-bound
   errors.
5. File-upload buttons, uploaded-file chips, empty state, failure state,
   progress state, and drag-and-drop treatment if added later.
6. Expansion tiles, collapsible section headers, workflow progress chips,
   error badges, and error-summary actions.
7. Circular progress indicators, snack bars, tooltips, dialogs, and bottom
   sheets.
8. Application navigation components: app bar, navigation rail, navigation
   bar, tabs, drawers, and selected indicators.
9. Consistent spacing, density, typography, focus rings, motion, and reduced-
   motion behavior across every renderer state.
10. RTL, text scaling, high-contrast accessibility, keyboard navigation, and
    golden tests for mobile, tablet, and desktop breakpoints.
11. Optional full Cupertino parity: text and picker fields, boolean controls,
    dates, files, nested collections, sections, workflow navigation, actions,
    dialogs, and error presentation. Field-level Cupertino overrides already
    work through `SkyloomFieldRenderer`; the complete shell is not bundled.
