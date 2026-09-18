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

    test('parses and round trips nested objects, arrays, and dependencies', () {
      final source = {
        'schemaVersion': '1.0',
        'id': 'team',
        'fields': [
          {
            'key': 'company',
            'type': FormType.object,
            'fields': [
              {
                'key': 'address',
                'type': FormType.object,
                'fields': [
                  {'key': 'country', 'type': FormType.text},
                ],
              },
            ],
          },
          {
            'key': 'employees',
            'type': FormType.array,
            'minItems': 1,
            'maxItems': 3,
            'defaultItem': {'name': 'New employee'},
            'items': {
              'type': FormType.object,
              'fields': [
                {'key': 'name', 'type': FormType.text},
                {
                  'key': 'skills',
                  'type': FormType.array,
                  'items': {'type': FormType.text},
                },
              ],
            },
          },
          {
            'key': 'state',
            'type': FormType.select,
            'dependsOn': ['company.address.country'],
            'dependencyConfig': {
              'clearOnChange': true,
              'reloadDataOnChange': true,
            },
          },
        ],
      };

      final schema = parser.parse(source);
      final employees = schema.fields[1];

      expect(schema.fields.first.fields!.single.fields!.single.key, 'country');
      expect(employees.items!.hasExplicitKey, isFalse);
      expect(employees.items!.fields![1].items!.type, FormType.text);
      expect(employees.minItems, 1);
      expect(schema.fields.last.dependency.clearOnChange, isTrue);
      expect(schema.fields.last.dependency.reloadDataOnChange, isTrue);
      expect(parser.parse(schema.toJson()).toJson(), source);
    });

    test('rejects incomplete or invalid object and array schemas', () {
      expect(
        () => parser.parse({
          'id': 'bad_object',
          'fields': [
            {'key': 'address', 'type': FormType.object},
          ],
        }),
        throwsA(
          isA<SchemaParseException>().having(
            (error) => error.path,
            'path',
            r'$.fields[0].fields',
          ),
        ),
      );
      expect(
        () => parser.parse({
          'id': 'bad_array',
          'fields': [
            {
              'key': 'items',
              'type': FormType.array,
              'minItems': 2,
              'maxItems': 1,
              'items': {'type': FormType.text},
            },
          ],
        }),
        throwsA(isA<SchemaParseException>()),
      );
    });

    test('parses async data, async validation, UI schema, and sections', () {
      final source = {
        'schemaVersion': '1.0',
        'id': 'advanced',
        'fields': [
          {'key': 'country', 'type': FormType.select},
          {
            'key': 'state',
            'type': FormType.select,
            'dependsOn': ['country'],
            'dataSource': {
              'handler': 'states',
              'pageSize': 25,
              'mapping': {
                'label': 'display.name',
                'value': 'id',
                'metadata': 'meta',
              },
            },
            'asyncValidation': {
              'handler': 'allowedState',
              'debounceMilliseconds': 200,
            },
          },
        ],
        'uiSchema': {
          'country': {
            'widget': FormType.radio,
            'layout': {'tablet': 6, 'desktop': 4},
            'order': 2,
            'visualHints': {'dense': true},
          },
        },
        'sections': [
          {
            'id': 'location',
            'title': 'Location',
            'fields': ['country', 'state'],
            'collapsible': true,
            'defaultExpanded': false,
          },
        ],
      };

      final schema = parser.parse(source);
      final state = schema.fields.last;

      expect(state.dataSource!.handler, 'states');
      expect(state.dataSource!.labelField, 'display.name');
      expect(state.asyncValidation!.handler, 'allowedState');
      expect(schema.uiSchema['country']!.layout.desktop, 4);
      expect(schema.sections.single.defaultExpanded, isFalse);
      expect(parser.parse(schema.toJson()).toJson(), source);
    });

    test('rejects invalid spans and duplicate section field membership', () {
      expect(
        () => parser.parse({
          'id': 'bad_layout',
          'fields': [
            {'key': 'name', 'type': FormType.text},
          ],
          'uiSchema': {
            'name': {
              'layout': {'desktop': 13},
            },
          },
        }),
        throwsA(isA<SchemaParseException>()),
      );
      expect(
        () => parser.parse({
          'id': 'bad_sections',
          'fields': [
            {'key': 'name', 'type': FormType.text},
          ],
          'sections': [
            {
              'id': 'one',
              'fields': ['name'],
            },
            {
              'id': 'two',
              'fields': ['name'],
            },
          ],
        }),
        throwsA(isA<SchemaParseException>()),
      );
    });

    test('parses and round trips ordered conditional steps', () {
      final source = {
        'schemaVersion': '1.0',
        'id': 'wizard',
        'fields': [
          {'key': 'kind', 'type': FormType.text},
          {'key': 'details', 'type': FormType.text},
        ],
        'steps': [
          {
            'id': 'identity',
            'title': 'Identity',
            'fields': ['kind'],
            'order': 1,
          },
          {
            'id': 'details',
            'title': 'Details',
            'fields': ['details'],
            'order': 2,
            'visibleWhen': {'field': 'kind', 'equals': 'full'},
          },
        ],
      };

      final schema = parser.parse(source);

      expect(schema.steps, hasLength(2));
      expect(schema.steps.last.visibleWhen, {
        'field': 'kind',
        'equals': 'full',
      });
      expect(parser.parse(schema.toJson()).toJson(), source);
    });

    test('rejects duplicate and incomplete step field membership', () {
      expect(
        () => parser.parse({
          'id': 'duplicate_steps',
          'fields': [
            {'key': 'name', 'type': FormType.text},
          ],
          'steps': [
            {
              'id': 'one',
              'fields': ['name'],
            },
            {
              'id': 'two',
              'fields': ['name'],
            },
          ],
        }),
        throwsA(isA<SchemaParseException>()),
      );
      expect(
        () => parser.parse({
          'id': 'missing_step_field',
          'fields': [
            {'key': 'name', 'type': FormType.text},
            {'key': 'email', 'type': FormType.email},
          ],
          'steps': [
            {
              'id': 'one',
              'fields': ['name'],
            },
          ],
        }),
        throwsA(
          isA<SchemaParseException>().having(
            (error) => error.message,
            'message',
            contains('email'),
          ),
        ),
      );
    });
  });
}
