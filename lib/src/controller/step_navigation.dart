import 'dart:async';

import '../schema/step_schema.dart';

/// Direction of a multi-step workflow transition.
enum SkyloomStepDirection { forward, backward, direct }

/// Context passed to an application-defined step navigation guard.
final class SkyloomStepChange {
  const SkyloomStepChange({
    required this.from,
    required this.to,
    required this.direction,
  });

  final StepSchema from;
  final StepSchema to;
  final SkyloomStepDirection direction;
}

/// Return false to cancel a requested step transition.
typedef SkyloomStepGuard = FutureOr<bool> Function(SkyloomStepChange change);
