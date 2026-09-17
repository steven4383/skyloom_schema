import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  FieldSchema field(Map<String, Object?> validation, {String type = 'text'}) {
    return const SchemaParser()
        .parse({
          'id': 'validation',
          'fields': [
            {
              'key': 'value',
              'type': type,
              'label': 'Value',
              'validation': validation,
            },
          ],
        })
        .fields
        .single;
  }

  const engine = ValidationEngine();
  const values = <String, Object?>{};

  test('supports length boundaries and custom messages', () {
    final schema = field({
      'minLength': {'value': 3, 'message': 'Too short.'},
      'maxLength': 5,
    });

    expect(engine.validateField(schema, 'ab', values), 'Too short.');
    expect(
      engine.validateField(schema, 'abcdef', values),
      'Value must contain at most 5 characters.',
    );
    expect(engine.validateField(schema, 'abcd', values), isNull);
  });

  test('supports number boundaries and rejects non-numbers', () {
    final schema = field({'min': 18, 'max': 65}, type: 'number');

    expect(
      engine.validateField(schema, 'invalid', values),
      'Value must be a valid number.',
    );
    expect(
      engine.validateField(schema, 17, values),
      'Value must be at least 18.',
    );
    expect(
      engine.validateField(schema, 66, values),
      'Value must be at most 65.',
    );
    expect(engine.validateField(schema, 30, values), isNull);
  });

  test('supports pattern and regex aliases', () {
    expect(
      engine.validateField(field({'pattern': r'^A'}), 'Beta', values),
      'Value has an invalid format.',
    );
    expect(
      engine.validateField(field({'regex': r'\d+$'}), 'item10', values),
      isNull,
    );
  });

  test('required checkbox rejects false while required switch accepts it', () {
    final checkbox = field({'required': true}, type: 'checkbox');
    final switchField = field({'required': true}, type: 'switch');

    expect(engine.validateField(checkbox, false, values), 'Value is required.');
    expect(engine.validateField(switchField, false, values), isNull);
  });
}
