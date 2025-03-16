import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

enum SignInFieldE { email, password, keepSignedIn }

void main() {
  group('Form Integration Test', () {
    testWidgets('Sign In form validates and submits correctly',
        (WidgetTester tester) async {
      final signInSchema = Jar.object({
        SignInFieldE.email.name: Jar.string()
            .email('Please enter a valid email')
            .required('Email is required'),
        SignInFieldE.password.name: Jar.string()
            .min(8, 'Password must be at least 8 characters')
            .required('Password is required'),
        SignInFieldE.keepSignedIn.name: Jar.boolean(),
      });

      final controller = JarFormController();
      bool formSubmitted = false;
      Map<String, dynamic>? submittedValues;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JarForm(
              schema: signInSchema,
              controller: controller,
              onSubmit: (values) async {
                formSubmitted = true;
                submittedValues = values;
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    JarFormField<String>(
                      name: SignInFieldE.email.name,
                      builder: (field) => TextField(
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          errorText: field.error,
                        ),
                        onChanged: field.onChange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    JarFormField<String>(
                      name: SignInFieldE.password.name,
                      builder: (field) => TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: field.error,
                        ),
                        onChanged: field.onChange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    JarFormField<bool>(
                      name: SignInFieldE.keepSignedIn.name,
                      builder: (field) => CheckboxListTile(
                        title: const Text('Keep me signed in'),
                        value: field.value ?? false,
                        onChanged: (value) => field.onChange(value),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Builder(
                      builder: (context) {
                        final formProvider = JarFormProvider.of(context);
                        final isValid =
                            formProvider?.controller.isValid ?? false;

                        return ElevatedButton(
                          onPressed: isValid ? () => controller.submit() : null,
                          child: const Text('Sign In'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(controller.isValid, false);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(formSubmitted, false);

      await tester.enterText(
          find.widgetWithText(TextField, 'Email Address'), 'invalid-email');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'short');
      await tester.pump();

      expect(controller.isValid, false);
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Email Address'), 'user@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'validpassword');
      await tester.tap(find.text('Keep me signed in'));
      await tester.pump();

      expect(controller.isValid, true);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(formSubmitted, true);
      expect(submittedValues?[SignInFieldE.email.name], 'user@example.com');
      expect(submittedValues?[SignInFieldE.password.name], 'validpassword');
      expect(submittedValues?[SignInFieldE.keepSignedIn.name], true);
    });
  });
}
