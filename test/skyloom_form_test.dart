import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  const schema = <String, Object?>{
    'id': 'login',
    'fields': [
      {
        'key': 'email',
        'type': 'email',
        'label': 'Email',
        'validation': {'required': true},
      },
      {'key': 'rememberMe', 'type': 'checkbox', 'label': 'Remember me'},
    ],
  };

  testWidgets('renders fields and submits JSON-compatible values', (
    tester,
  ) async {
    Map<String, Object?>? submittedValues;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SkyloomForm.fromJson(
            schema: schema,
            onSubmit: (values) {
              submittedValues = values;
            },
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Submit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'steven@example.com');
    await tester.tap(find.text('Remember me'));
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pump();

    expect(submittedValues, {
      'email': 'steven@example.com',
      'rememberMe': true,
    });
  });

  testWidgets('shows validation errors and blocks invalid submission', (
    tester,
  ) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyloomForm.fromJson(
            schema: schema,
            onSubmit: (_) {
              submitted = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('calls onChanged when a field value changes', (tester) async {
    Map<String, Object?>? changedValues;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyloomForm.fromJson(
            schema: schema,
            showSubmitButton: false,
            onChanged: (values) {
              changedValues = values;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'test@example.com');

    expect(changedValues?['email'], 'test@example.com');
  });

  testWidgets('displays a clear message for an unregistered field type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyloomForm.fromJson(
            schema: const {
              'id': 'custom',
              'fields': [
                {'key': 'location', 'type': 'geoPicker'},
              ],
            },
          ),
        ),
      ),
    );

    expect(
      find.text('No renderer is registered for "geoPicker" (location).'),
      findsOneWidget,
    );
  });

  testWidgets('builds every default Material field type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SkyloomForm.fromJson(
              schema: const {
                'id': 'all_fields',
                'fields': [
                  {'key': 'text', 'type': 'text', 'label': 'Text'},
                  {'key': 'email', 'type': 'email', 'label': 'Email'},
                  {'key': 'password', 'type': 'password', 'label': 'Password'},
                  {'key': 'number', 'type': 'number', 'label': 'Number'},
                  {'key': 'notes', 'type': 'textarea', 'label': 'Notes'},
                  {'key': 'checkbox', 'type': 'checkbox', 'label': 'Checkbox'},
                  {'key': 'switch', 'type': 'switch', 'label': 'Switch'},
                  {
                    'key': 'radio',
                    'type': 'radio',
                    'label': 'Radio',
                    'options': [
                      {'label': 'One', 'value': 'one'},
                    ],
                  },
                  {
                    'key': 'select',
                    'type': 'select',
                    'label': 'Select',
                    'options': [
                      {'label': 'One', 'value': 'one'},
                    ],
                  },
                  {'key': 'date', 'type': 'date', 'label': 'Date'},
                ],
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Checkbox'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    expect(find.text('Radio'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
  });

  testWidgets('supports outlined inputs and scrolls large forms', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyloomForm.fromJson(
            schema: {
              'id': 'large_form',
              'fields': [
                for (var index = 0; index < 20; index++)
                  {
                    'key': 'field$index',
                    'type': FormType.text,
                    'label': 'Field $index',
                  },
              ],
            },
            padding: const EdgeInsets.all(16),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );

    final fieldContext = tester.element(find.byType(TextField).first);
    expect(
      Theme.of(fieldContext).inputDecorationTheme.border,
      isA<OutlineInputBorder>(),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Field 10'), findsOneWidget);
  });
}
