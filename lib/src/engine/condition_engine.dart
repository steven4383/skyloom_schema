import '../utils/path_utils.dart';

/// Evaluates schema condition objects against current form values.
final class ConditionEngine {
  const ConditionEngine();

  bool evaluate(Object? condition, Map<String, Object?> values) {
    if (condition is! Map<Object?, Object?>) return false;

    final all = condition['all'];
    if (all is List<Object?>) {
      return all.every((item) => evaluate(item, values));
    }

    final any = condition['any'];
    if (any is List<Object?>) {
      return any.any((item) => evaluate(item, values));
    }

    if (condition.containsKey('not')) {
      return !evaluate(condition['not'], values);
    }

    final fieldPath = condition['field'];
    if (fieldPath is! String) return false;
    final actual = PathUtils.getValue(values, fieldPath);

    if (condition.containsKey('equals')) {
      return _deepEquals(actual, condition['equals']);
    }
    if (condition.containsKey('notEquals')) {
      return !_deepEquals(actual, condition['notEquals']);
    }
    if (condition.containsKey('contains')) {
      return _contains(actual, condition['contains']);
    }
    if (condition.containsKey('notContains')) {
      return !_contains(actual, condition['notContains']);
    }
    if (condition.containsKey('in')) {
      return _in(actual, condition['in']);
    }
    if (condition.containsKey('notIn')) {
      return !_in(actual, condition['notIn']);
    }
    if (condition.containsKey('empty')) {
      return _isEmpty(actual) == (condition['empty'] == true);
    }
    if (condition.containsKey('notEmpty')) {
      return !_isEmpty(actual) == (condition['notEmpty'] == true);
    }
    if (condition.containsKey('greaterThan')) {
      return _compare(actual, condition['greaterThan'], (value) => value > 0);
    }
    if (condition.containsKey('greaterThanOrEqual')) {
      return _compare(
        actual,
        condition['greaterThanOrEqual'],
        (value) => value >= 0,
      );
    }
    if (condition.containsKey('lessThan')) {
      return _compare(actual, condition['lessThan'], (value) => value < 0);
    }
    if (condition.containsKey('lessThanOrEqual')) {
      return _compare(
        actual,
        condition['lessThanOrEqual'],
        (value) => value <= 0,
      );
    }
    return false;
  }

  bool _contains(Object? collection, Object? expected) {
    if (collection is String && expected is String) {
      return collection.contains(expected);
    }
    if (collection is Iterable<Object?>) {
      return collection.any((item) => _deepEquals(item, expected));
    }
    if (collection is Map<Object?, Object?>) {
      return collection.containsKey(expected);
    }
    return false;
  }

  bool _in(Object? actual, Object? candidates) {
    return candidates is Iterable<Object?> &&
        candidates.any((candidate) => _deepEquals(actual, candidate));
  }

  bool _compare(
    Object? left,
    Object? right,
    bool Function(int value) predicate,
  ) {
    if (left is num && right is num) {
      return predicate(left.compareTo(right));
    }
    if (left is String && right is String) {
      final leftDate = DateTime.tryParse(left);
      final rightDate = DateTime.tryParse(right);
      if (leftDate != null && rightDate != null) {
        return predicate(leftDate.compareTo(rightDate));
      }
      return predicate(left.compareTo(right));
    }
    return false;
  }

  bool _isEmpty(Object? value) {
    return value == null ||
        value is String && value.trim().isEmpty ||
        value is Iterable<Object?> && value.isEmpty ||
        value is Map<Object?, Object?> && value.isEmpty;
  }

  bool _deepEquals(Object? left, Object? right) {
    if (identical(left, right)) return true;
    if (left is List<Object?> && right is List<Object?>) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_deepEquals(left[index], right[index])) return false;
      }
      return true;
    }
    if (left is Map<Object?, Object?> && right is Map<Object?, Object?>) {
      if (left.length != right.length) return false;
      for (final entry in left.entries) {
        if (!right.containsKey(entry.key) ||
            !_deepEquals(entry.value, right[entry.key])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }
}
