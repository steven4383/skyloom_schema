import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  const parser = SchemaParser();

  group('SchemaParser', () {
    test('parses the minimal schema and applies the schema version', () {
      final schema = parser.parse({
        'id': 'create_employee',
        'fields': [
          {'key': 'name', 'type': 'text'},
        ],
      });

      expect(schema.id, 'create_employee');
      expect(schema.schemaVersion, '1.0');
      expect(schema.fields.single.key, 'name');
      expect(schema.fields.single.type, 'text');
    });

    test('accepts FormType constants as JSON-compatible strings', () {
      final schema = parser.parse({
        'id': 'typed_fields',
        'fields': [
          {'key': 'name', 'type': FormType.text},
          {'key': 'enabled', 'type': FormType.switchField},
        ],
      });

      expect(schema.fields.map((field) => field.type), ['text', 'switch']);
    });

    test('parses common properties, options, validation, and metadata', () {
      final schema = parser.parse({
        'schemaVersion': '1.0',
        'id': 'profile',
        'title': 'Profile',
        'metadata': {'source': 'test'},
        'fields': [
          {
            'key': 'role',
            'type': 'select',
            'label': 'Role',
            'description': 'Employee role',
            'helperText': 'Choose one',
            'placeholder': 'Select a role',
            'defaultValue': null,
            'required': true,
            'disabled': false,
            'readOnly': true,
            'hidden': false,
            'options': [
              {'label': 'Developer', 'value': 'developer'},
            ],
            'validation': {'required': true, 'minLength': 3},
            'metadata': {'analyticsId': 'role'},
          },
        ],
      });

      final field = schema.fields.single;
      expect(field.hasDefaultValue, isTrue);
      expect(field.defaultValue, isNull);
      expect(field.required, isTrue);
      expect(field.readOnly, isTrue);
      expect(field.options!.single.value, 'developer');
      expect(field.validation!.rules['minLength'], 3);
      expect(field.metadata['analyticsId'], 'role');
    });

    test('preserves unknown properties for future extensions', () {
      final schema = parser.parse({
        'id': 'conditional',
        'futureRootSetting': {'enabled': true},
        'fields': [
          {
            'key': 'company',
            'type': 'customCompany',
            'visibleWhen': {'field': 'accountType', 'equals': 'business'},
          },
        ],
      });

      expect(schema.additionalProperties['futureRootSetting'], {
        'enabled': true,
      });
      expect(schema.fields.single.additionalProperties['visibleWhen'], {
        'field': 'accountType',
        'equals': 'business',
      });
      expect(parser.parse(schema.toJson()).toJson(), schema.toJson());
    });

    test('round trips through JSON encoding', () {
      final original = {
        'schemaVersion': '1.0',
        'id': 'employee',
        'fields': [
          {'key': 'address.city', 'type': 'text', 'defaultValue': 'Chennai'},
        ],
      };

      final encoded = jsonEncode(parser.parse(original).toJson());
      final reparsed = parser.parse(jsonDecode(encoded));

      expect(reparsed.toJson(), original);
    });

    test('rejects duplicate field keys with a useful path', () {
      expect(
        () => parser.parse({
          'id': 'duplicate',
          'fields': [
            {'key': 'name', 'type': 'text'},
            {'key': 'name', 'type': 'email'},
          ],
        }),
        throwsA(
          isA<SchemaParseException>()
              .having((error) => error.path, 'path', r'$.fields[1].key')
              .having(
                (error) => error.message,
                'message',
                contains('duplicated'),
              ),
        ),
      );
    });

    test('rejects malformed schemas and paths', () {
      expect(
        () => parser.parse({'id': 'missing_fields'}),
        throwsA(
          isA<SchemaParseException>().having(
            (error) => error.path,
            'path',
            r'$.fields',
          ),
        ),
      );
      expect(
        () => parser.parse({
          'id': 'bad_path',
          'fields': [
            {'key': 'address..city', 'type': 'text'},
          ],
        }),
        throwsA(isA<SchemaParseException>()),
      );
    });

    test('reports the exact path of a non-JSON field value', () {
      expect(
        () => parser.parse({
          'id': 'invalid_default',
          'fields': [
            {
              'key': 'createdAt',
              'type': 'date',
              'defaultValue': DateTime(2026),
            },
          ],
        }),
        throwsA(
          isA<SchemaParseException>().having(
            (error) => error.path,
            'path',
            r'$.fields[0].defaultValue',
          ),
        ),
      );
    });

    test('models expose immutable collections', () {
      final schema = parser.parse({
        'id': 'immutable',
        'metadata': {
          'items': <Object?>[1, 2],
        },
        'fields': [
          {'key': 'name', 'type': 'text'},
        ],
      });

      expect(
        () => schema.fields.add(schema.fields.first),
        throwsUnsupportedError,
      );
      expect(
        () => (schema.metadata['items']! as List<Object?>).add(3),
        throwsUnsupportedError,
      );
    });
  });
}
