import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  group('PathUtils', () {
    test('reads nested maps and array indexes', () {
      final values = <String, Object?>{
        'company': {
          'employees': [
            {'name': 'Steven'},
          ],
        },
      };

      expect(PathUtils.getValue(values, 'company.employees[0].name'), 'Steven');
      expect(PathUtils.contains(values, 'company.employees[0].name'), isTrue);
      expect(PathUtils.contains(values, 'company.employees[1].name'), isFalse);
    });

    test('distinguishes an absent value from an explicit null', () {
      final values = <String, Object?>{
        'profile': {'nickname': null},
      };

      expect(PathUtils.getValue(values, 'profile.nickname'), isNull);
      expect(PathUtils.contains(values, 'profile.nickname'), isTrue);
      expect(PathUtils.contains(values, 'profile.name'), isFalse);
    });

    test('creates maps and arrays while setting a value', () {
      final values = <String, Object?>{};

      PathUtils.setValue(values, 'employees[1].address.city', 'Chennai');

      expect(
        PathUtils.getValue(values, 'employees[1].address.city'),
        'Chennai',
      );
      expect(PathUtils.getValue(values, 'employees[0]'), isNull);
    });

    test('rejects malformed paths', () {
      expect(
        () => PathUtils.getValue(const {}, 'address..city'),
        throwsArgumentError,
      );
    });
  });
}
