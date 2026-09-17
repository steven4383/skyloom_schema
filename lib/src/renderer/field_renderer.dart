import 'package:flutter/widgets.dart';

import 'renderer_context.dart';

/// Builds a Flutter widget for one schema field type.
abstract interface class SkyloomFieldRenderer {
  const SkyloomFieldRenderer();

  Widget build(BuildContext context, SkyloomRendererContext rendererContext);
}
