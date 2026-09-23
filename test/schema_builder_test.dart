import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  test('typed builder creates and validates a complete schema', () {
    final schema = SkyloomSchema.form(
      id: 'employee_registration',
      title: 'Employee Registration',
      description: 'Create an employee profile.',
      metadata: const {'department': 'engineering'},
      fields: [
        SkyloomField.text(
          key: 'name',
          label: 'Full name',
          placeholder: 'Enter the employee name',
          validation: SkyloomValidation.rules(
            required: true,
            minLength: 2,
            maxLength: 80,
          ),
        ),
        SkyloomField.email(
          key: 'email',
          label: 'Email address',
          validation: SkyloomValidation.rules(required: true, email: true),
        ),
        SkyloomField.number(
          key: 'age',
          label: 'Age',
          validation: SkyloomValidation.rules(min: 18, max: 100),
        ),
        SkyloomField.select(
          key: 'role',
          label: 'Role',
          options: [
            FieldOption(label: 'Developer', value: 'developer'),
            FieldOption(label: 'Manager', value: 'manager'),
          ],
          validation: SkyloomValidation.rules(required: true),
        ),
        SkyloomField.object(
          key: 'address',
          label: 'Address',
          fields: [
            SkyloomField.text(key: 'city', label: 'City'),
            SkyloomField.select(
              key: 'country',
              label: 'Country',
              options: [FieldOption(label: 'India', value: 'IN')],
            ),
          ],
        ),
        SkyloomField.array(
          key: 'emergencyContacts',
          label: 'Emergency contacts',
          minItems: 1,
          items: SkyloomField.object(
            key: 'contact',
            includeKey: false,
            fields: [
              SkyloomField.text(key: 'name', label: 'Name'),
              SkyloomField.text(key: 'phone', label: 'Phone'),
            ],
          ),
        ),
        SkyloomField.file(
          key: 'resume',
          label: 'Resume',
          upload: FileUploadSchema(
            handler: 'resumeUpload',
            accept: const ['application/pdf'],
            maxBytes: 5000000,
          ),
        ),
      ],
    );

    expect(schema.id, 'employee_registration');
    expect(schema.fields.map((field) => field.type), contains(FormType.file));
    expect(schema.fields.first.validation?.rules, {
      ValidationRule.required: true,
      ValidationRule.minLength: 2,
      ValidationRule.maxLength: 80,
    });
    expect(
      schema.fields
          .firstWhere((field) => field.key == 'emergencyContacts')
          .items
          ?.hasExplicitKey,
      isFalse,
    );
    expect(
      const SchemaParser().parse(schema.toJson()).toJson(),
      schema.toJson(),
    );
  });

  test('typed validation supports custom messages and extension rules', () {
    final validation = SkyloomValidation.rules(
      required: true,
      minLength: 3,
      messages: const {ValidationRule.minLength: 'Too short.'},
      additionalRules: const {'companyRule': true},
    );

    expect(validation.rules[ValidationRule.required], isTrue);
    expect(validation.rules[ValidationRule.minLength], {
      'value': 3,
      'message': 'Too short.',
    });
    expect(validation.rules['companyRule'], isTrue);
  });
}
