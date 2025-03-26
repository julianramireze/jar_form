import 'package:flutter_test/flutter_test.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

void main() {
  group('Dependent validation in JarForm', () {
    test('Cross-field validation works with allValues parameter', () {
      final controller = JarFormController();

      final passwordSchema = Jar.string()
          .required('Password is required')
          .min(8, 'Password must be at least 8 characters');

      final confirmSchema = Jar.string()
          .required('Please confirm password')
          .custom((value, [allValues]) {
        final password = allValues?['password'];
        if (value != password) {
          return 'Passwords do not match';
        }
        return null;
      });

      controller.register('password', JarFieldConfig(schema: passwordSchema));
      controller.register(
          'confirmPassword', JarFieldConfig(schema: confirmSchema));

      controller.setValue('password', 'password123');

      controller.setValue('confirmPassword', 'different');

      expect(controller.getFieldState('confirmPassword')?.error,
          'Passwords do not match');
      expect(controller.isValid, false);

      controller.setValue('confirmPassword', 'password123');

      expect(controller.getFieldState('confirmPassword')?.error, null);
      expect(controller.isValid, true);
    });

    test('Conditional required fields based on selection', () {
      final controller = JarFormController();

      String? validateCreditCard(String? value,
          [Map<String, dynamic>? allValues]) {
        final method = allValues?['paymentMethod'];

        if (method == 'creditCard' && (value == null || value.isEmpty)) {
          return 'Credit card number is required for credit card payments';
        }
        return null;
      }

      final creditCardSchema = Jar.string().custom(validateCreditCard);

      controller.register(
          'paymentMethod',
          JarFieldConfig(
              schema: Jar.string()
                  .required()
                  .oneOf(['creditCard', 'bankTransfer', 'paypal'])));

      controller.register(
          'creditCardNumber', JarFieldConfig(schema: creditCardSchema));

      controller.setValue('paymentMethod', 'creditCard');

      controller.setValue('creditCardNumber', '');

      expect(controller.getFieldValue('paymentMethod'), 'creditCard');
      expect(controller.getFieldValue('creditCardNumber'), '');

      controller.trigger();

      print('Payment method: ${controller.getFieldValue('paymentMethod')}');
      print(
          'Credit card number: ${controller.getFieldValue('creditCardNumber')}');
      print(
          'Credit card error: ${controller.getFieldState('creditCardNumber')?.error}');
      print('All values: ${controller.getValues()}');

      expect(controller.getFieldState('creditCardNumber')?.error,
          'Credit card number is required for credit card payments');

      controller.setValue('creditCardNumber', '4111111111111111');

      expect(controller.getFieldState('creditCardNumber')?.error, null);
      expect(controller.isValid, true);

      controller.setValue('paymentMethod', 'paypal');

      controller.trigger();

      expect(controller.getFieldState('creditCardNumber')?.error, null);
    });

    test('Postal code validation by country', () {
      final controller = JarFormController();

      String? validatePostalCode(String? value,
          [Map<String, dynamic>? allValues]) {
        final country = allValues?['country'];

        if (value == null || value.isEmpty) {
          return 'Postal code is required';
        }

        if (country == 'US') {
          return RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value)
              ? null
              : 'US postal code must be in format 12345 or 12345-6789';
        } else if (country == 'CA') {
          return RegExp(r'^[A-Za-z]\d[A-Za-z] \d[A-Za-z]\d$').hasMatch(value)
              ? null
              : 'Canadian postal code must be in format A1A 1A1';
        } else if (country == 'MX') {
          return RegExp(r'^\d{5}$').hasMatch(value)
              ? null
              : 'Mexican postal code must be 5 digits';
        }

        return null;
      }

      controller.register(
          'country',
          JarFieldConfig(
              schema: Jar.string().required().oneOf(['US', 'CA', 'MX'])));

      controller.register(
          'postalCode',
          JarFieldConfig(
              schema: Jar.string().required().custom(validatePostalCode)));

      controller.setValue('country', 'US');

      controller.setValue('postalCode', 'ABC123');

      expect(controller.getFieldState('postalCode')?.error,
          'US postal code must be in format 12345 or 12345-6789');
      expect(controller.isValid, false);

      controller.setValue('postalCode', '12345');

      expect(controller.getFieldState('postalCode')?.error, null);
      expect(controller.isValid, true);

      controller.setValue('country', 'CA');

      expect(controller.getFieldState('postalCode')?.error,
          'Canadian postal code must be in format A1A 1A1');
      expect(controller.isValid, false);

      controller.setValue('postalCode', 'A1A 1A1');

      expect(controller.getFieldState('postalCode')?.error, null);
      expect(controller.isValid, true);
    });
  });
}
