import '../renderer/field_renderer.dart';

/// Resolves schema field type names to Flutter renderers.
final class SkyloomRendererRegistry {
  SkyloomRendererRegistry(Map<String, SkyloomFieldRenderer> renderers)
    : _renderers = Map<String, SkyloomFieldRenderer>.unmodifiable(renderers);

  final Map<String, SkyloomFieldRenderer> _renderers;

  Map<String, SkyloomFieldRenderer> get renderers => _renderers;

  SkyloomFieldRenderer? rendererFor(String fieldType) => _renderers[fieldType];

  SkyloomRendererRegistry withOverrides(
    Map<String, SkyloomFieldRenderer> overrides,
  ) {
    return SkyloomRendererRegistry({..._renderers, ...overrides});
  }
}
