import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

const employeeSchema = <String, Object?>{
  'schemaVersion': '1.0',
  'id': 'employee_registration',
  'title': 'Employee Registration',
  'fields': [
    {
      'key': 'name',
      'type': FormType.text,
      'label': 'Full name',
      'validation': {'required': true, 'minLength': 2},
    },
    {
      'key': 'email',
      'type': FormType.email,
      'label': 'Email address',
      'validation': {'required': true, 'email': true},
    },
    {
      'key': 'age',
      'type': FormType.number,
      'label': 'Age',
      'validation': {'min': 18, 'max': 100},
    },
    {
      'key': 'role',
      'type': FormType.select,
      'label': 'Role',
      'options': [
        {'label': 'Developer', 'value': 'developer'},
        {'label': 'Quality Analyst', 'value': 'qa'},
        {'label': 'Manager', 'value': 'manager'},
      ],
      'validation': {'required': true},
    },
    {
      'key': 'contactPreference',
      'type': FormType.radio,
      'label': 'Preferred contact method',
      'options': [
        {'label': 'Email', 'value': 'email'},
        {'label': 'Phone', 'value': 'phone'},
      ],
    },
    {
      'key': 'notificationsEnabled',
      'type': FormType.switchField,
      'label': 'Enable notifications',
      'defaultValue': true,
    },
    {
      'key': 'acceptedTerms',
      'type': FormType.checkbox,
      'label': 'Accept the terms',
      'validation': {'required': true},
    },
    {'key': 'dateOfBirth', 'type': FormType.date, 'label': 'Date of birth'},
    {
      'key': 'address',
      'type': FormType.object,
      'label': 'Address',
      'fields': [
        {
          'key': 'country',
          'type': FormType.select,
          'label': 'Country',
          'options': [
            {'label': 'India', 'value': 'IN'},
            {'label': 'United States', 'value': 'US'},
          ],
        },
        {
          'key': 'state',
          'type': FormType.text,
          'label': 'State',
          'dependsOn': ['country'],
          'dependencyConfig': {
            'clearOnChange': true,
            'reloadDataOnChange': true,
          },
        },
        {'key': 'city', 'type': FormType.text, 'label': 'City'},
      ],
    },
    {
      'key': 'emergencyContacts',
      'type': FormType.array,
      'label': 'Emergency contacts',
      'minItems': 1,
      'maxItems': 3,
      'items': {
        'type': FormType.object,
        'fields': [
          {'key': 'name', 'type': FormType.text, 'label': 'Contact name'},
          {'key': 'phone', 'type': FormType.text, 'label': 'Phone number'},
        ],
      },
    },
    {'key': 'notes', 'type': FormType.textarea, 'label': 'Notes'},
  ],
};

void main() => runApp(const SkyloomExampleApp());

class SkyloomExampleApp extends StatelessWidget {
  const SkyloomExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skyloom Schema Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const EmployeeFormPage(),
    );
  }
}

class EmployeeFormPage extends StatefulWidget {
  const EmployeeFormPage({super.key});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  Map<String, Object?>? _submittedValues;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Registration')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SkyloomForm.fromJson(
              schema: employeeSchema,
              layout: SkyloomFormLayout.column,
              padding: const EdgeInsets.all(4),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
              initialValues: const {
                'address': {'country': 'IN', 'city': 'Chennai'},
              },
              onDependencyChanged: (change) {
                if (change.configuration.reloadDataOnChange) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Reload options for ${change.dependentKey}',
                      ),
                    ),
                  );
                }
              },
              onSubmit: (values) {
                setState(() => _submittedValues = values);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Form submitted')));
              },
            ),
            if (_submittedValues != null) ...[
              const SizedBox(height: 24),
              Text(
                'Submitted JSON',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                const JsonEncoder.withIndent(' ').convert(_submittedValues),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
