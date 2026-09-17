import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  const engine = ConditionEngine();
  const values = <String, Object?>{
    'role': 'admin',
    'age': 27,
    'tags': ['flutter', 'dart'],
    'profile': {'city': 'Chennai'},
    'emptyValue': '',
  };

  test('evaluates comparison and collection operators', () {
    expect(
      engine.evaluate({'field': 'role', 'equals': 'admin'}, values),
      isTrue,
    );
    expect(
      engine.evaluate({'field': 'role', 'notEquals': 'user'}, values),
      isTrue,
    );
    expect(
      engine.evaluate({'field': 'tags', 'contains': 'dart'}, values),
      isTrue,
    );
    expect(
      engine.evaluate({
        'field': 'profile.city',
        'in': ['Chennai', 'Bengaluru'],
      }, values),
      isTrue,
    );
    expect(
      engine.evaluate({'field': 'age', 'greaterThan': 18}, values),
      isTrue,
    );
    expect(
      engine.evaluate({'field': 'age', 'lessThanOrEqual': 27}, values),
      isTrue,
    );
    expect(
      engine.evaluate({'field': 'emptyValue', 'empty': true}, values),
      isTrue,
    );
  });

  test('evaluates nested all, any, and not groups', () {
    expect(
      engine.evaluate({
        'all': [
          {'field': 'role', 'equals': 'admin'},
          {
            'any': [
              {'field': 'age', 'lessThan': 18},
              {'field': 'age', 'greaterThanOrEqual': 21},
            ],
          },
          {
            'not': {'field': 'role', 'equals': 'guest'},
          },
        ],
      }, values),
      isTrue,
    );
  });
}
