/// Determines when field validation runs automatically in form widgets.
enum SkyloomValidationMode {
  /// Validate after every value change, on blur, and on submission.
  onChange,

  /// Validate when a field loses focus and on submission.
  onBlur,

  /// Validate only when the form is submitted.
  onSubmit,

  /// Do not validate during editing. Controller validation remains available.
  manual,
}
