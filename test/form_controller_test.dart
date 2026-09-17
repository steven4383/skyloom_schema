import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  late FormSchema schema;

  setUp(() {
    schema = const SchemaParser().parse({
      'id': 'employee',
      'fields': [
        {
          'key': 'name',
          'type': 'text',
          'defaultValue': 'Default name',
          'validation': {'required': true, 'minLength': 2},
        },
        {
          'key': 'email',
          'type': 'email',
          'validation': {
            'required': {'value': true, 'message': 'We need an email.'},
          },
        },
        {'key': 'address.city', 'type': 'text'},
        {'key': 'acceptedTerms', 'type': 'checkbox', 'required': true},
      ],
    });
  });

  test('loads initial values over schema defaults', () {
    final controller = SkyloomFormController(
      schema: schema,
      initialValues: const {
        'name': 'Steven',
        'address': {'city': 'Chennai'},
      },
    );
    addTearDown(controller.dispose);

    expect(controller.value('name'), 'Steven');
    expect(controller.value('address.city'), 'Chennai');
    expect(controller.values, {
      'name': 'Steven',
      'email': null,
      'address': {'city': 'Chennai'},
      'acceptedTerms': null,
    });
    expect(controller.pristine, isTrue);
  });

  test('tracks field state and resets to initial values', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);

    controller.setValue('name', 'Changed');

    expect(controller.field('name').dirty, isTrue);
    expect(controller.field('name').touched, isTrue);
    expect(controller.dirty, isTrue);

    controller.reset();

    expect(controller.value('name'), 'Default name');
    expect(controller.field('name').pristine, isTrue);
    expect(controller.field('name').untouched, isTrue);
  });

  test('patches nested values without clearing other fields', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);
    controller.setValue('email', 'first@example.com');

    controller.patchValues(const {
      'address': {'city': 'Bengaluru'},
    });

    expect(controller.value('email'), 'first@example.com');
    expect(controller.value('address.city'), 'Bengaluru');
  });

  test('validates required, email, and checkbox rules', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);

    expect(controller.validate(), isFalse);
    expect(controller.errors['email'], 'We need an email.');
    expect(controller.errors['acceptedTerms'], 'acceptedTerms is required.');

    controller
      ..setValue('email', 'not-an-email')
      ..setValue('acceptedTerms', true);
    expect(controller.validate(), isFalse);
    expect(controller.errors['email'], 'Enter a valid email address.');

    controller.setValue('email', 'steven@example.com');
    expect(controller.validate(), isTrue);
    expect(controller.errors, isEmpty);
  });

  test('submit only invokes the callback for a valid form', () async {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);
    var submissions = 0;

    expect(
      await controller.submit((_) async {
        submissions++;
      }),
      isFalse,
    );
    expect(submissions, 0);

    controller
      ..setValue('email', 'steven@example.com')
      ..setValue('acceptedTerms', true);

    expect(
      await controller.submit((values) async {
        submissions++;
        expect(values['name'], 'Default name');
      }),
      isTrue,
    );
    expect(submissions, 1);
    expect(controller.submitted, isTrue);
    expect(controller.submitting, isFalse);
  });

  test('supports backend errors', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);

    controller.setErrors({
      'email': 'Email already exists.',
      'name': 'Name is unavailable.',
    });
    expect(controller.errors, hasLength(2));

    controller.clearError('name');
    expect(controller.errors, {'email': 'Email already exists.'});

    controller.clearErrors();
    expect(controller.errors, isEmpty);
  });

  test('loads edit data as a new pristine baseline', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);
    controller.setValue('name', 'Changed');

    controller.loadJson(const {
      'name': 'Backend name',
      'email': 'backend@example.com',
    });

    expect(controller.value('name'), 'Backend name');
    expect(controller.field('name').initialValue, 'Backend name');
    expect(controller.value('email'), 'backend@example.com');
    expect(controller.pristine, isTrue);
    expect(controller.touched, isFalse);
  });

  test('tracks form and field loading state', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);

    controller.setLoading(true);
    expect(controller.loading, isTrue);

    controller.setLoading(false);
    controller.field('email').setLoading(true);
    expect(controller.loading, isTrue);
  });
}
