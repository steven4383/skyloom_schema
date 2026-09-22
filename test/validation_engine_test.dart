import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

final class _TestMessages extends SkyloomMessages {
  const _TestMessages();

  @override
  String validationMessage(
    String code, {
    required String label,
    Map<String, Object?> arguments = const {},
  }) => 'localized:$code:$label';
}

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

  test('supports URL and cross-field equality rules', () {
    final urlField = field({ValidationRule.url: true});
    expect(
      engine.validateField(urlField, 'not-a-url', values),
      'Enter a valid URL.',
    );
    expect(
      engine.validateField(urlField, 'https://skyloom.dev/docs', values),
      isNull,
    );

    final sameAsField = field({ValidationRule.sameAs: 'password'});
    expect(
      engine.validateField(sameAsField, 'different', const {
        'password': 'secret',
      }),
      'Value must match password.',
    );
    expect(
      engine.validateField(sameAsField, 'secret', const {'password': 'secret'}),
      isNull,
    );
  });

  test('supports numeric and date cross-field comparisons', () {
    final lessThan = field({ValidationRule.lessThanOrEqual: 'total'});
    expect(
      engine.validateField(lessThan, '20', const {'total': '100'}),
      isNull,
    );
    expect(
      engine.validateField(lessThan, 101, const {'total': 100}),
      'Value must be less than or equal to total.',
    );

    final after = field({ValidationRule.greaterThan: 'startDate'});
    expect(
      engine.validateField(after, '2026-09-18', const {
        'startDate': '2026-09-17',
      }),
      isNull,
    );
    expect(
      engine.validateField(after, '2026-09-16', const {
        'startDate': '2026-09-17',
      }),
      'Value must be greater than startDate.',
    );
  });

  test('supports inclusive static date bounds', () {
    final date = field({
      ValidationRule.minDate: '2026-09-10',
      ValidationRule.maxDate: {
        'value': '2026-09-20',
        'message': 'Choose a date during enrollment.',
      },
    }, type: FormType.date);

    expect(
      engine.validateField(date, '2026-09-09', values),
      'Value must be on or after 2026-09-10.',
    );
    expect(engine.validateField(date, '2026-09-10', values), isNull);
    expect(engine.validateField(date, '2026-09-20', values), isNull);
    expect(
      engine.validateField(date, '2026-09-21', values),
      'Choose a date during enrollment.',
    );
    expect(
      engine.validateField(date, 'not-a-date', values),
      'Value must be a valid date.',
    );
  });

  test('returns structured localized validation errors', () {
    final required = field({'required': true});
    const localizedEngine = ValidationEngine(messages: _TestMessages());

    final error = localizedEngine.validateFieldError(required, null, values);

    expect(error?.code, SkyloomValidationCode.required);
    expect(error?.message, 'localized:required:Value');
    expect(error?.arguments, isEmpty);
  });

  test('validates JSON-safe uploaded-file values and limits', () {
    final uploadField = const SchemaParser()
        .parse({
          'id': 'upload_validation',
          'fields': [
            {
              'key': 'documents',
              'type': FormType.file,
              'upload': {
                'handler': 'documents',
                'multiple': true,
                'maxFiles': 2,
                'maxBytes': 100,
                'accept': ['application/pdf', 'image/*', '.docx'],
              },
            },
          ],
        })
        .fields
        .single;
    final validFile = SkyloomUploadedFile(
      id: 'one',
      name: 'one.pdf',
      mimeType: 'application/pdf',
      size: 80,
    ).toJson();
    final largeFile = SkyloomUploadedFile(
      id: 'large',
      name: 'large.pdf',
      mimeType: 'application/pdf',
      size: 101,
    ).toJson();

    expect(engine.validateField(uploadField, [validFile], values), isNull);
    expect(
      engine.validateFieldError(uploadField, [largeFile], values)?.code,
      SkyloomValidationCode.uploadMaxBytes,
    );
    expect(
      engine.validateFieldError(uploadField, [
        validFile,
        validFile,
        validFile,
      ], values)?.code,
      SkyloomValidationCode.uploadMaxFiles,
    );
    final invalidType = SkyloomUploadedFile(
      id: 'text',
      name: 'notes.txt',
      mimeType: 'text/plain',
      size: 20,
    ).toJson();
    expect(
      engine.validateFieldError(uploadField, [invalidType], values)?.code,
      SkyloomValidationCode.uploadInvalidType,
    );
  });

  test('enforces array item-count bounds including empty arrays', () {
    final schema = const SchemaParser()
        .parse({
          'id': 'arrays',
          'fields': [
            {
              'key': 'tags',
              'type': FormType.array,
              'minItems': 1,
              'maxItems': 2,
              'items': {'type': FormType.text},
            },
          ],
        })
        .fields
        .single;

    expect(
      engine.validateField(schema, const [], values),
      'tags must contain at least 1 item.',
    );
    expect(engine.validateField(schema, const ['one'], values), isNull);
    expect(
      engine.validateField(schema, const ['one', 'two', 'three'], values),
      'tags must contain at most 2 items.',
    );
  });
}
