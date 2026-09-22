import 'dart:async';

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
    expect(
      controller.field('email').validationError?.code,
      SkyloomValidationCode.required,
    );
    expect(
      controller.errorEntries
          .firstWhere((error) => error.fieldKey == 'email')
          .code,
      SkyloomValidationCode.required,
    );

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

  test('runs registered custom validators', () {
    final customSchema = const SchemaParser().parse({
      'id': 'custom_validation',
      'fields': [
        {
          'key': 'employeeId',
          'type': FormType.text,
          'validation': {
            ValidationRule.custom: ['startsWithEmployee', 'notReserved'],
          },
        },
      ],
    });
    final controller = SkyloomFormController(
      schema: customSchema,
      validators: {
        'startsWithEmployee': (value, context) =>
            value is String && value.startsWith('EMP-')
            ? null
            : 'Employee IDs must start with EMP-.',
        'notReserved': (value, context) =>
            value == 'EMP-000' ? 'This employee ID is reserved.' : null,
      },
    );
    addTearDown(controller.dispose);

    controller.setValue('employeeId', 'INVALID');
    expect(controller.validateField('employeeId'), isFalse);
    expect(
      controller.errors['employeeId'],
      'Employee IDs must start with EMP-.',
    );

    controller.setValue('employeeId', 'EMP-123');
    expect(controller.validateField('employeeId'), isTrue);
  });

  test('reacts to visibility, required, enabled, and read-only conditions', () {
    final conditionalSchema = const SchemaParser().parse({
      'id': 'conditions',
      'fields': [
        {'key': 'accountType', 'type': FormType.text},
        {'key': 'locked', 'type': FormType.checkbox},
        {
          'key': 'companyName',
          'type': FormType.text,
          'visibleWhen': {'field': 'accountType', 'equals': 'business'},
          'requiredWhen': {'field': 'accountType', 'equals': 'business'},
          'readOnlyWhen': {'field': 'locked', 'equals': true},
        },
        {
          'key': 'personalName',
          'type': FormType.text,
          'disabledWhen': {'field': 'accountType', 'equals': 'business'},
        },
      ],
    });
    final controller = SkyloomFormController(schema: conditionalSchema);
    addTearDown(controller.dispose);

    expect(controller.field('companyName').visible, isFalse);
    expect(controller.field('companyName').required, isFalse);

    controller.setValue('accountType', 'business');
    expect(controller.field('companyName').visible, isTrue);
    expect(controller.field('companyName').required, isTrue);
    expect(controller.field('personalName').disabled, isTrue);
    expect(controller.validateField('companyName'), isFalse);

    controller.setValue('locked', true);
    expect(controller.field('companyName').readOnly, isTrue);
  });

  test('builds, updates, and serializes deeply nested object fields', () {
    final nestedSchema = const SchemaParser().parse({
      'id': 'nested',
      'fields': [
        {
          'key': 'company',
          'type': FormType.object,
          'fields': [
            {
              'key': 'address',
              'type': FormType.object,
              'fields': [
                {
                  'key': 'city',
                  'type': FormType.text,
                  'defaultValue': 'Chennai',
                },
              ],
            },
          ],
        },
      ],
    });
    final controller = SkyloomFormController(schema: nestedSchema);
    addTearDown(controller.dispose);

    expect(controller.value('company.address.city'), 'Chennai');
    expect(controller.value('company'), {
      'address': {'city': 'Chennai'},
    });

    controller.setValue('company.address', {'city': 'Bengaluru'});
    expect(controller.values, {
      'company': {
        'address': {'city': 'Bengaluru'},
      },
    });
  });

  test('supports array defaults, add, duplicate, reorder, and remove', () {
    final arraySchema = const SchemaParser().parse({
      'id': 'arrays',
      'fields': [
        {
          'key': 'employees',
          'type': FormType.array,
          'minItems': 1,
          'maxItems': 3,
          'defaultItem': {'name': 'New'},
          'items': {
            'type': FormType.object,
            'fields': [
              {
                'key': 'name',
                'type': FormType.text,
                'validation': {'required': true},
              },
            ],
          },
        },
      ],
    });
    final controller = SkyloomFormController(schema: arraySchema);
    addTearDown(controller.dispose);

    expect(controller.value('employees'), [
      {'name': 'New'},
    ]);
    expect(controller.addArrayItem('employees', {'name': 'Alex'}), isTrue);
    expect(controller.duplicateArrayItem('employees', 1), isTrue);
    expect(controller.addArrayItem('employees'), isFalse);
    expect(controller.reorderArrayItem('employees', 2, 0), isTrue);
    expect(controller.removeArrayItem('employees', 1), isTrue);
    expect(controller.removeArrayItem('employees', 1), isTrue);
    expect(controller.removeArrayItem('employees', 0), isFalse);
    expect(controller.validateField('employees'), isTrue);
  });

  test('processes dependency chains and reports reload hooks', () {
    final dependencySchema = const SchemaParser().parse({
      'id': 'locations',
      'fields': [
        {'key': 'country', 'type': FormType.text},
        {
          'key': 'state',
          'type': FormType.text,
          'dependsOn': ['country'],
          'dependencyConfig': {
            'clearOnChange': true,
            'reloadDataOnChange': true,
          },
        },
        {
          'key': 'city',
          'type': FormType.text,
          'dependsOn': ['state'],
          'dependencyConfig': {'clearOnChange': true},
        },
      ],
    });
    final changes = <SkyloomDependencyChange>[];
    final controller = SkyloomFormController(
      schema: dependencySchema,
      initialValues: const {'country': 'IN', 'state': 'TN', 'city': 'Chennai'},
      onDependencyChanged: changes.add,
    );
    addTearDown(controller.dispose);

    controller.setValue('country', 'US');

    expect(controller.value('state'), isNull);
    expect(controller.value('city'), isNull);
    expect(changes.map((change) => change.dependentKey), ['city', 'state']);
    expect(changes.last.configuration.reloadDataOnChange, isTrue);
  });

  test('rejects circular dependency graphs', () {
    final circular = const SchemaParser().parse({
      'id': 'circular',
      'fields': [
        {
          'key': 'a',
          'type': FormType.text,
          'dependsOn': ['b'],
        },
        {
          'key': 'b',
          'type': FormType.text,
          'dependsOn': ['a'],
        },
      ],
    });

    expect(
      () => SkyloomFormController(schema: circular),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'loads, maps, paginates, and caches async data-source options',
    () async {
      final dataSchema = const SchemaParser().parse({
        'id': 'data',
        'fields': [
          {'key': 'country', 'type': FormType.text},
          {
            'key': 'state',
            'type': FormType.select,
            'dependsOn': ['country'],
            'dependencyConfig': {'reloadDataOnChange': true},
            'dataSource': {
              'handler': 'states',
              'pageSize': 1,
              'mapping': {
                'label': 'display.name',
                'value': 'code',
                'metadata': 'meta',
              },
            },
          },
        ],
      });
      var calls = 0;
      final requestedCountries = <Object?>[];
      final controller = SkyloomFormController(
        schema: dataSchema,
        initialValues: const {'country': 'IN'},
        dataSources: {
          'states': (request) {
            calls++;
            requestedCountries.add(request.dependencyValues['country']);
            return {
              'items': [
                {
                  'display': {
                    'name': request.page == 1 ? 'Tamil Nadu' : 'Kerala',
                  },
                  'code': request.page == 1 ? 'TN' : 'KL',
                  'meta': {'page': request.page},
                },
              ],
              'hasMore': request.page == 1,
            };
          },
        },
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(controller.optionsFor('state').single.label, 'Tamil Nadu');
      expect(controller.optionsFor('state').single.value, 'TN');
      expect(controller.optionsFor('state').single.metadata['page'], 1);

      await controller.loadNextOptionsPage('state');
      expect(controller.optionsFor('state').map((option) => option.value), [
        'TN',
        'KL',
      ]);
      final callsBeforeCache = calls;
      await controller.loadOptions('state');
      expect(calls, callsBeforeCache);

      controller.setValue('country', 'US');
      await Future<void>.delayed(Duration.zero);
      expect(requestedCountries, contains('US'));
    },
  );

  test('ignores stale data-source responses', () async {
    final dataSchema = const SchemaParser().parse({
      'id': 'stale_data',
      'fields': [
        {
          'key': 'search',
          'type': FormType.select,
          'dataSource': {'handler': 'search'},
        },
      ],
    });
    final pending = <Completer<Object?>>[];
    final controller = SkyloomFormController(schema: dataSchema);
    addTearDown(controller.dispose);
    controller.setDataSources({
      'search': (request) {
        final completer = Completer<Object?>();
        pending.add(completer);
        return completer.future;
      },
    });
    final latestRequest = controller.loadOptions('search', search: 'latest');

    pending[1].complete([
      {'label': 'Latest', 'value': 'latest'},
    ]);
    await latestRequest;
    pending[0].complete([
      {'label': 'Old', 'value': 'old'},
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.optionsFor('search').single.value, 'latest');
  });

  test(
    'async validation ignores stale results and caches latest values',
    () async {
      final asyncSchema = const SchemaParser().parse({
        'id': 'async_validation',
        'fields': [
          {
            'key': 'username',
            'type': FormType.text,
            'asyncValidation': {'handler': 'available'},
          },
        ],
      });
      final pending = <Completer<String?>>[];
      var calls = 0;
      final controller = SkyloomFormController(
        schema: asyncSchema,
        asyncValidators: {
          'available': (value, context) {
            calls++;
            final completer = Completer<String?>();
            pending.add(completer);
            return completer.future;
          },
        },
      );
      addTearDown(controller.dispose);

      controller.setValue('username', 'old');
      final oldValidation = controller.validateFieldAsync('username');
      controller.setValue('username', 'latest');
      final latestValidation = controller.validateFieldAsync('username');

      pending[1].complete(null);
      expect(await latestValidation, isTrue);
      pending[0].complete('Already used.');
      expect(await oldValidation, isFalse);
      expect(controller.field('username').error, isNull);
      expect(
        controller.asyncValidationStatus('username'),
        SkyloomAsyncValidationStatus.success,
      );

      expect(await controller.validateFieldAsync('username'), isTrue);
      expect(calls, 2);
    },
  );

  test(
    'navigates, validates, conditions, and restores multi-step state',
    () async {
      final workflowSchema = const SchemaParser().parse({
        'id': 'workflow',
        'fields': [
          {'key': 'kind', 'type': FormType.text},
          {
            'key': 'name',
            'type': FormType.text,
            'validation': {'required': true},
          },
          {
            'key': 'company',
            'type': FormType.text,
            'validation': {'required': true},
          },
          {'key': 'email', 'type': FormType.email},
        ],
        'steps': [
          {
            'id': 'identity',
            'fields': ['kind', 'name'],
            'order': 1,
          },
          {
            'id': 'business',
            'fields': ['company'],
            'order': 2,
            'visibleWhen': {'field': 'kind', 'equals': 'business'},
          },
          {
            'id': 'contact',
            'fields': ['email'],
            'order': 3,
          },
        ],
      });
      final controller = SkyloomFormController(schema: workflowSchema);
      addTearDown(controller.dispose);

      expect(controller.visibleSteps.map((step) => step.id), [
        'identity',
        'contact',
      ]);
      expect(await controller.nextStep(), isFalse);
      expect(controller.errors['name'], isNotNull);

      controller.setValue('name', 'Sky');
      expect(controller.validate(), isTrue);
      expect(controller.errors['company'], isNull);

      controller.setValue('kind', 'business');
      expect(controller.visibleSteps.map((step) => step.id), [
        'identity',
        'business',
        'contact',
      ]);
      expect(await controller.nextStep(), isTrue);
      expect(controller.currentStep?.id, 'business');

      controller.setValue('company', 'Skyloom');
      expect(await controller.nextStep(), isTrue);
      controller.setValue('email', 'team@skyloom.dev');
      final saved = controller.saveState();

      controller
        ..setValue('email', 'changed@example.com')
        ..previousStep();
      controller.restoreState(saved);
      expect(controller.currentStep?.id, 'contact');
      expect(controller.value('email'), 'team@skyloom.dev');
    },
  );

  test('combines field and form-level errors', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);

    controller
      ..setError('email', 'Email is unavailable.')
      ..setFormErrors(['The server rejected this request.'])
      ..addFormError('Please try again.');

    expect(controller.valid, isFalse);
    expect(controller.formErrors, hasLength(2));
    expect(controller.errorEntries, hasLength(3));
    expect(controller.errorEntries.first.isFormError, isTrue);
    expect(controller.firstErrorFieldKey, 'email');

    controller.clearErrors();
    expect(controller.errorEntries, isEmpty);
  });

  test(
    'treats errors added by submit callbacks as a failed submission',
    () async {
      final controller = SkyloomFormController(
        schema: schema,
        initialValues: const {
          'email': 'valid@example.com',
          'acceptedTerms': true,
        },
      );
      addTearDown(controller.dispose);

      final result = await controller.submit((_) {
        controller.setFormErrors(['The server rejected the form.']);
      });

      expect(result, isFalse);
      expect(controller.submitted, isFalse);
      expect(controller.formErrors, ['The server rejected the form.']);
    },
  );

  test('applies structured backend errors and reports unknown fields', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);

    final result = controller.applyErrors(
      fieldErrors: const {
        'email': ['Already registered.', 'Use another address.'],
        'legacyId': ['This field no longer exists.'],
      },
      formErrors: const ['Unable to create employee.'],
    );

    expect(result.appliedFields, ['email']);
    expect(
      controller.field('email').validationError?.code,
      SkyloomValidationCode.server,
    );
    expect(result.unknownFields, ['legacyId']);
    expect(
      controller.errors['email'],
      'Already registered.\nUse another address.',
    );
    expect(controller.formErrors, [
      'Unable to create employee.',
      'legacyId: This field no longer exists.',
    ]);

    controller.setError('name', 'Keep this error.');
    expect(
      () => controller.applyErrors(
        fieldErrors: const {
          'missing': ['Unknown field.'],
        },
        unknownFieldPolicy: SkyloomUnknownFieldErrorPolicy.throwException,
      ),
      throwsArgumentError,
    );
    expect(controller.errors['name'], 'Keep this error.');
  });

  test('emits renderer-independent field navigation requests', () {
    final controller = SkyloomFormController(schema: schema);
    addTearDown(controller.dispose);

    controller.revealField('email');
    final reveal = controller.fieldNavigationRequest!;
    expect(reveal.fieldPath, 'email');
    expect(reveal.intent, SkyloomFieldNavigationIntent.reveal);

    controller.focusField('name');
    final focus = controller.fieldNavigationRequest!;
    expect(focus.id, greaterThan(reveal.id));
    expect(focus.fieldPath, 'name');
    expect(focus.requestsFocus, isTrue);
    expect(
      () => controller.revealField('missing'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('guards step transitions and tracks completed steps', () async {
    final changes = <SkyloomStepChange>[];
    Completer<bool>? pendingGuard;
    final guardedSchema = const SchemaParser().parse({
      'id': 'guarded_steps',
      'fields': [
        {
          'key': 'name',
          'type': FormType.text,
          'validation': {'required': true},
        },
        {'key': 'email', 'type': FormType.email},
      ],
      'steps': [
        {
          'id': 'identity',
          'fields': ['name'],
        },
        {
          'id': 'contact',
          'fields': ['email'],
        },
      ],
    });
    final controller = SkyloomFormController(
      schema: guardedSchema,
      initialValues: const {'name': 'Sky'},
      onStepChanging: (change) {
        changes.add(change);
        pendingGuard = Completer<bool>();
        return pendingGuard!.future;
      },
    );
    addTearDown(controller.dispose);

    final blocked = controller.nextStep();
    await Future<void>.delayed(Duration.zero);
    expect(controller.navigatingSteps, isTrue);
    pendingGuard!.complete(false);
    expect(await blocked, isFalse);
    expect(controller.currentStep?.id, 'identity');

    final allowed = controller.nextStep();
    await Future<void>.delayed(Duration.zero);
    pendingGuard!.complete(true);
    expect(await allowed, isTrue);
    expect(controller.currentStep?.id, 'contact');
    expect(controller.isStepComplete('identity'), isTrue);
    expect(changes.last.direction, SkyloomStepDirection.forward);

    final previous = controller.previousStep();
    await Future<void>.delayed(Duration.zero);
    pendingGuard!.complete(true);
    await previous;
    controller.setValue('name', 'Changed');
    expect(controller.isStepComplete('identity'), isFalse);
  });
}
