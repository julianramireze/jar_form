import 'package:flutter_test/flutter_test.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

void main() {
  group('Specific Scenarios', () {
    test('Dependent fields validate correctly', () async {
      final controller = JarFormController();

      final passwordSchema =
          Jar.string().min(8, 'Password must be at least 8 characters');

      final confirmSchema = Jar.string().custom((dynamic value, [allValues]) {
        final String? stringValue = value as String?;
        final password = controller.getFieldValue<String>('password');
        if (stringValue != password) {
          return 'Passwords do not match';
        }
        return null;
      });

      controller.register('password', JarFieldConfig(schema: passwordSchema));
      controller.register(
          'confirmPassword', JarFieldConfig(schema: confirmSchema));

      await controller.setValue('password', 'password123');

      await controller.setValue('confirmPassword', 'different');
      expect(controller.getFieldState('confirmPassword')?.error, isNotNull);

      await controller.setValue('confirmPassword', 'password123');
      expect(controller.getFieldState('confirmPassword')?.error, isNull);
    });

    test('Async validators with dependencies work', () async {
      final controller = JarFormController();

      final asyncValidator = (dynamic username) async {
        final String? stringUsername = username as String?;
        await Future.delayed(Duration(milliseconds: 10));
        return stringUsername == 'taken' ? 'Username not available' : null;
      };

      controller.register(
          'username',
          JarFieldConfig<String>(
              schema: Jar.string(), asyncValidators: [asyncValidator]));

      await controller.setValue('username', 'available');
      expect(controller.getFieldState('username')?.error, isNull);

      await controller.setValue('username', 'taken');
      expect(controller.getFieldState('username')?.error,
          'Username not available');
    });

    test('Dynamic fields are handled correctly', () async {
      final controller = JarFormController();

      controller.register('hasPhone',
          JarFieldConfig<bool>(schema: Jar.boolean(), defaultValue: false));

      controller.watch('hasPhone', (dynamic hasPhone) {
        final bool? boolHasPhone = hasPhone as bool?;
        if (boolHasPhone == true && !controller.isRegistered('phone')) {
          controller.register(
              'phone',
              JarFieldConfig(
                  schema:
                      Jar.string().matches(r'^\d{10}$', 'Must be 10 digits')));
        }
      });

      expect(controller.isRegistered('phone'), false);

      await controller.setValue('hasPhone', true);
      expect(controller.isRegistered('phone'), true);

      await controller.setValue('phone', 'invalid');
      expect(controller.getFieldState('phone')?.error, isNotNull);

      await controller.setValue('phone', '1234567890');
      expect(controller.getFieldState('phone')?.error, isNull);
    });

    test('Custom formats work correctly', () async {
      final controller = JarFormController();

      final cardNumberSchema = Jar.string()
          .matches(r'^[0-9]{16}$', 'Must be 16 digits')
          .custom((dynamic value, [allValues]) {
        final String? stringValue = value as String?;
        if (stringValue == null || stringValue.isEmpty) return 'Required';

        final digits = stringValue.split('').map(int.parse).toList();
        int sum = 0;

        for (int i = digits.length - 1; i >= 0; i--) {
          int digit = digits[i];
          if ((digits.length - i) % 2 == 0) {
            digit *= 2;
            if (digit > 9) digit -= 9;
          }
          sum += digit;
        }

        return sum % 10 == 0 ? null : 'Invalid card number';
      });

      controller.register(
          'cardNumber', JarFieldConfig(schema: cardNumberSchema));

      await controller.setValue('cardNumber', '4111111111111112');
      expect(controller.getFieldState('cardNumber')?.error, isNotNull);

      await controller.setValue('cardNumber', '4111111111111111');
      expect(controller.getFieldState('cardNumber')?.error, isNull);
    });

    test('Support for nested forms', () async {
      final controller = JarFormController();

      final addressSchema = Jar.object({
        'street': Jar.string().required('Street required'),
        'city': Jar.string().required('City required'),
        'zipcode': Jar.string().matches(r'^\d{5}$', 'Must be 5 digits')
      });

      final userSchema = Jar.object({
        'name': Jar.string().required('Name required'),
        'address': addressSchema
      });

      controller.register('user', JarFieldConfig(schema: userSchema));

      await controller.setValue('user', <String, dynamic>{});
      expect(controller.getFieldState('user')?.error, isNotNull);

      await controller.setValue('user', <String, dynamic>{'name': 'John'});
      expect(controller.getFieldState('user')?.error, isNull);

      await controller.setValue('user', <String, dynamic>{
        'name': 'John',
        'address': <String, dynamic>{
          'street': 'Main Street',
          'city': 'City',
          'zipcode': 'ABC'
        }
      });
      expect(controller.getFieldState('user')?.error, isNotNull);

      await controller.setValue('user', <String, dynamic>{
        'name': 'John',
        'address': <String, dynamic>{
          'street': 'Main Street',
          'city': 'City',
          'zipcode': '12345'
        }
      });
      expect(controller.getFieldState('user')?.error, isNull);
    });

    test('Form with conditional fields based on selection', () async {
      final controller = JarFormController();

      controller.register(
          'category',
          JarFieldConfig<String>(
              schema: Jar.string()
                  .oneOf(['product', 'service'], 'Invalid category')));

      controller.watch('category', (dynamic category) {
        final String? stringCategory = category as String?;
        if (stringCategory == 'product' && !controller.isRegistered('weight')) {
          controller.register(
              'weight',
              JarFieldConfig(
                  schema: Jar.number()
                      .positive('Must be positive')
                      .required('Weight required')));
        } else if (stringCategory == 'service' &&
            !controller.isRegistered('duration')) {
          controller.register(
              'duration',
              JarFieldConfig(
                  schema: Jar.number()
                      .min(1, 'Minimum 1 hour')
                      .required('Duration required')));
        }
      });

      await controller.setValue('category', 'product');
      expect(controller.isRegistered('weight'), true);
      expect(controller.isRegistered('duration'), false);

      await controller.setValue('weight', 0);
      expect(controller.getFieldState('weight')?.error, 'Must be positive');

      await controller.setValue('weight', 10);
      expect(controller.getFieldState('weight')?.error, isNull);

      await controller.setValue('category', 'service');
      expect(controller.isRegistered('duration'), true);

      await controller.setValue('duration', 0);
      expect(controller.getFieldState('duration')?.error, 'Minimum 1 hour');

      await controller.setValue('duration', 2);
      expect(controller.getFieldState('duration')?.error, isNull);
    });

    test('Multi-step form with validation between steps', () async {
      final controller = JarFormController();

      final personalInfoSchema = Jar.object({
        'name': Jar.string().required('Name required'),
        'email': Jar.string().email('Invalid email').required('Email required'),
      });

      final addressSchema = Jar.object({
        'street': Jar.string().required('Street required'),
        'city': Jar.string().required('City required'),
        'zipcode': Jar.string().matches(r'^\d{5}$', 'Must be 5 digits'),
      });

      final paymentSchema = Jar.object({
        'cardNumber': Jar.string()
            .matches(r'^\d{16}$', 'Must be 16 digits')
            .required('Card number required'),
        'expiryDate': Jar.string()
            .matches(r'^\d{2}/\d{2}$', 'Format: MM/YY')
            .required('Expiry date required'),
        'cvv': Jar.string()
            .matches(r'^\d{3}$', 'Must be 3 digits')
            .required('CVV required'),
      });

      controller.register('step1', JarFieldConfig(schema: personalInfoSchema));
      controller.register('step2', JarFieldConfig(schema: addressSchema));
      controller.register('step3', JarFieldConfig(schema: paymentSchema));

      await controller.setValue('step1', {
        'name': '',
        'email': 'not-an-email',
      });
      expect(controller.getFieldState('step1')?.error, isNotNull);

      await controller.setValue('step1', {
        'name': 'John Doe',
        'email': 'john@example.com',
      });
      expect(controller.getFieldState('step1')?.error, isNull);

      await controller.setValue('step2', {
        'street': 'Main Street',
        'zipcode': '123',
      });
      expect(controller.getFieldState('step2')?.error, isNotNull);

      await controller.setValue('step2', {
        'street': 'Main Street',
        'city': 'City',
        'zipcode': '12345',
      });
      expect(controller.getFieldState('step2')?.error, isNull);

      await controller.setValue('step3', {
        'cardNumber': '411111111111',
        'expiryDate': '12-22',
        'cvv': '12',
      });
      expect(controller.getFieldState('step3')?.error, isNotNull);

      await controller.setValue('step3', {
        'cardNumber': '4111111111111111',
        'expiryDate': '12/25',
        'cvv': '123',
      });
      expect(controller.getFieldState('step3')?.error, isNull);

      expect(controller.isValid, true);

      final Map<String, dynamic>? step1Data =
          controller.getFieldValue<Map<String, dynamic>>('step1');
      final Map<String, dynamic>? step2Data =
          controller.getFieldValue<Map<String, dynamic>>('step2');
      final Map<String, dynamic>? step3Data =
          controller.getFieldValue<Map<String, dynamic>>('step3');

      expect(step1Data, isNotNull);
      expect(step2Data, isNotNull);
      expect(step3Data, isNotNull);

      if (step1Data != null && step2Data != null && step3Data != null) {
        final Map<String, dynamic> formData = {
          ...step1Data,
          ...step2Data,
          ...step3Data,
        };

        expect(formData['name'], 'John Doe');
        expect(formData['email'], 'john@example.com');
        expect(formData['street'], 'Main Street');
        expect(formData['city'], 'City');
        expect(formData['zipcode'], '12345');
        expect(formData['cardNumber'], '4111111111111111');
        expect(formData['expiryDate'], '12/25');
        expect(formData['cvv'], '123');
      }
    });
  });
}
