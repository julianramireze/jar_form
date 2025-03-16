import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

void main() {
  group('JarFormField and JarForm Widget Tests', () {
    testWidgets('JarFormField displays and updates correctly',
        (WidgetTester tester) async {
      final controller = JarFormController();
      final schema = Jar.string().required('This field is required');

      controller.register('test', JarFieldConfig(schema: schema));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: JarFormProvider(
                controller: controller,
                child: Material(
                  child: JarFormField<String>(
                    name: 'test',
                    builder: (field) => TextField(
                      onChanged: field.onChange,
                      decoration: InputDecoration(
                        errorText: field.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'new value');
      await tester.pump();

      expect(controller.getFieldValue<String>('test'), 'new value');
    });

    testWidgets('JarForm initializes schema fields automatically',
        (WidgetTester tester) async {
      final controller = JarFormController();
      final jarSchema = Jar.object({
        'name': Jar.string().required('Name is required'),
        'email':
            Jar.string().email('Invalid email').required('Email is required'),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: JarForm(
                controller: controller,
                schema: jarSchema,
                child: Material(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JarFormField<String>(
                          name: 'name',
                          builder: (field) => TextField(
                            onChanged: field.onChange,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              errorText: field.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        JarFormField<String>(
                          name: 'email',
                          builder: (field) => TextField(
                            onChanged: field.onChange,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              errorText: field.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.isRegistered('name'), true);
      expect(controller.isRegistered('email'), true);

      await controller.setValue('name', '');
      await tester.pump();
      expect(find.text('Name is required'), findsOneWidget);

      await controller.setValue('email', 'not-an-email');
      await tester.pump();
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('JarForm onSubmit is called when form is valid',
        (WidgetTester tester) async {
      final controller = JarFormController();
      final schema = Jar.object({
        'name': Jar.string().required('Name is required'),
      });

      bool submitCalled = false;
      Map<String, dynamic>? submittedValues;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: JarForm(
                controller: controller,
                schema: schema,
                onSubmit: (values) async {
                  submitCalled = true;
                  submittedValues = values;
                },
                child: Material(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JarFormField<String>(
                          name: 'name',
                          builder: (field) => TextField(
                            onChanged: field.onChange,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              errorText: field.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => controller.submit(),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(submitCalled, false);
      await controller.setValue('name', 'Test Name');
      await tester.pump();

      await controller.submit();
      await tester.pumpAndSettle();

      expect(submitCalled, true);
      expect(submittedValues?['name'], 'Test Name');
    });

    testWidgets('JarFormField handles errors correctly',
        (WidgetTester tester) async {
      final controller = JarFormController();
      final schema = Jar.string()
          .min(3, 'At least 3 characters')
          .required('This field is required');

      controller.register('test', JarFieldConfig(schema: schema));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: JarFormProvider(
                controller: controller,
                child: Material(
                  child: JarFormField<String>(
                    name: 'test',
                    builder: (field) => TextField(
                      key: Key('test-field'),
                      onChanged: field.onChange,
                      decoration: InputDecoration(
                        labelText: 'Text Field',
                        errorText: field.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await controller.setValue('test', 'ab');
      await tester.pump();

      expect(find.text('At least 3 characters'), findsOneWidget);

      await controller.setValue('test', 'abc');
      await tester.pump();

      expect(find.text('At least 3 characters'), findsNothing);
    });

    testWidgets('JarFormField displays disabled state correctly',
        (WidgetTester tester) async {
      final controller = JarFormController();
      final schema = Jar.string().required('Field required');

      controller.register(
          'test', JarFieldConfig(schema: schema, disabled: true));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: JarFormProvider(
                controller: controller,
                child: Material(
                  child: JarFormField<String>(
                    name: 'test',
                    builder: (field) => TextField(
                      enabled: !field.isDisabled,
                      onChanged: field.onChange,
                      decoration: InputDecoration(
                        labelText: 'Disabled Field',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final TextField textField = tester.widget(find.byType(TextField));
      expect(textField.enabled, false);

      controller.enable('test');
      await tester.pump();

      final TextField updatedTextField = tester.widget(find.byType(TextField));
      expect(updatedTextField.enabled, true);
    });

    testWidgets('Form with conditional validation works correctly',
        (WidgetTester tester) async {
      final controller = JarFormController();

      final schema = Jar.object({
        'hasPhone': Jar.boolean(),
        'phone': Jar.string().when('hasPhone', {
          true: (schema) => schema
              .matches(r'^\d{10}$', 'Must be 10 digits')
              .required('Phone required'),
          false: (schema) => schema.optional(),
        }),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: JarForm(
                controller: controller,
                schema: schema,
                child: Material(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        JarFormField<bool>(
                          name: 'hasPhone',
                          builder: (field) => CheckboxListTile(
                            title: const Text('Has Phone?'),
                            value: field.value ?? false,
                            onChanged: (value) => field.onChange(value),
                          ),
                        ),
                        JarFormField<String>(
                          name: 'phone',
                          builder: (field) => TextField(
                            enabled:
                                controller.getFieldValue('hasPhone') == true,
                            onChanged: field.onChange,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              errorText: field.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await controller.setValue('hasPhone', true);
      await tester.pump();

      expect(controller.getFieldValue('hasPhone'), true);

      await controller.setValue('phone', '123');
      await tester.pump();

      expect(find.text('Must be 10 digits'), findsOneWidget);

      await controller.setValue('phone', '1234567890');
      await tester.pump();

      expect(find.text('Must be 10 digits'), findsNothing);

      await controller.setValue('hasPhone', false);
      await tester.pump();

      expect(controller.getFieldValue('hasPhone'), false);

      expect(find.text('Must be 10 digits'), findsNothing);
    });

    testWidgets('JarForm with nested fields', (WidgetTester tester) async {
      final controller = JarFormController();
      final schema = Jar.object({
        'personal': Jar.object({
          'name': Jar.string().required('Name required'),
          'email':
              Jar.string().email('Invalid email').required('Email required'),
        }),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: JarForm(
                controller: controller,
                schema: schema,
                child: Material(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (context) {
                            expect(controller.isRegistered('personal'), true);

                            if (!controller.isRegistered('personal.name')) {
                              controller.register(
                                  'personal.name',
                                  JarFieldConfig(
                                      schema: Jar.string()
                                          .required('Name required')));
                            }

                            if (!controller.isRegistered('personal.email')) {
                              controller.register(
                                  'personal.email',
                                  JarFieldConfig(
                                      schema: Jar.string()
                                          .email('Invalid email')
                                          .required('Email required')));
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                JarFormField<String>(
                                  name: 'personal.name',
                                  builder: (field) => TextField(
                                    onChanged: field.onChange,
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      errorText: field.error,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                JarFormField<String>(
                                  name: 'personal.email',
                                  builder: (field) => TextField(
                                    onChanged: field.onChange,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      errorText: field.error,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.isRegistered('personal.name'), true);
      expect(controller.isRegistered('personal.email'), true);

      await controller.setValue('personal.name', '');
      await controller.setValue('personal.email', 'not-an-email');
      await tester.pump();

      expect(find.text('Name required'), findsOneWidget);
      expect(find.text('Invalid email'), findsOneWidget);

      await controller.setValue('personal.name', 'John Doe');
      await controller.setValue('personal.email', 'john@example.com');
      await tester.pump();

      expect(find.text('Name required'), findsNothing);
      expect(find.text('Invalid email'), findsNothing);

      await controller.setValue('personal',
          <String, dynamic>{'name': 'Jane Doe', 'email': 'jane@example.com'});
      await tester.pump();

      expect(find.text('Name required'), findsNothing);
      expect(find.text('Invalid email'), findsNothing);
    });
  });
}
