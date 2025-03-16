import 'package:flutter_test/flutter_test.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

void main() {
  group('Integration with jar (validation)', () {
    test('JarString validates minimum length', () async {
      final controller = JarFormController();
      final schema = Jar.string().min(3, 'Minimum 3 characters');

      controller.register('username', JarFieldConfig(schema: schema));

      await controller.setValue('username', 'ab');
      expect(
          controller.getFieldState('username')?.error, 'Minimum 3 characters');

      await controller.setValue('username', 'abc');
      expect(controller.getFieldState('username')?.error, isNull);
    });

    test('JarString validates emails', () async {
      final controller = JarFormController();
      final schema = Jar.string().email('Invalid email');

      controller.register('email', JarFieldConfig(schema: schema));

      await controller.setValue('email', 'notanemail');
      expect(controller.getFieldState('email')?.error, 'Invalid email');

      await controller.setValue('email', 'test@example.com');
      expect(controller.getFieldState('email')?.error, isNull);
    });

    test('JarString validates regular expressions', () async {
      final controller = JarFormController();
      final schema = Jar.string().matches(r'^\d{5}$', 'Must have 5 digits');

      controller.register('zipcode', JarFieldConfig(schema: schema));

      await controller.setValue('zipcode', '123');
      expect(controller.getFieldState('zipcode')?.error, 'Must have 5 digits');

      await controller.setValue('zipcode', '12345');
      expect(controller.getFieldState('zipcode')?.error, isNull);
    });

    test('JarString validates with custom function', () async {
      final controller = JarFormController();
      final schema = Jar.string().custom((value) {
        if (value == null || value.isEmpty) return 'Required field';
        if (value.length % 2 != 0) return 'Must have even length';
        return null;
      });

      controller.register('evenLength', JarFieldConfig(schema: schema));

      await controller.setValue('evenLength', 'odd');
      expect(controller.getFieldState('evenLength')?.error,
          'Must have even length');

      await controller.setValue('evenLength', 'even');
      expect(controller.getFieldState('evenLength')?.error, isNull);
    });

    test('JarNumber validates range correctly', () async {
      final controller = JarFormController();
      final schema = Jar.number().min(1, 'Min 1').max(100, 'Max 100');

      controller.register('age', JarFieldConfig(schema: schema));

      await controller.setValue('age', 0);
      expect(controller.getFieldState('age')?.error, 'Min 1');

      await controller.setValue('age', 101);
      expect(controller.getFieldState('age')?.error, 'Max 100');

      await controller.setValue('age', 50);
      expect(controller.getFieldState('age')?.error, isNull);
    });

    test('JarNumber validates integers', () async {
      final controller = JarFormController();
      final schema = Jar.number().integer('Must be an integer');

      controller.register('quantity', JarFieldConfig(schema: schema));

      await controller.setValue('quantity', 10.5);
      expect(controller.getFieldState('quantity')?.error, 'Must be an integer');

      await controller.setValue('quantity', 10);
      expect(controller.getFieldState('quantity')?.error, isNull);
    });

    test('JarNumber validates positive numbers', () async {
      final controller = JarFormController();
      final schema = Jar.number().positive('Must be positive');

      controller.register('price', JarFieldConfig(schema: schema));

      await controller.setValue('price', -5);
      expect(controller.getFieldState('price')?.error, 'Must be positive');

      await controller.setValue('price', 5);
      expect(controller.getFieldState('price')?.error, isNull);
    });

    test('JarNumber validates with custom function', () async {
      final controller = JarFormController();
      final schema = Jar.number().custom((value) {
        if (value == null) return 'Required field';
        if (value % 2 != 0) return 'Must be an even number';
        return null;
      });

      controller.register('evenNumber', JarFieldConfig(schema: schema));

      await controller.setValue('evenNumber', 5);
      expect(controller.getFieldState('evenNumber')?.error,
          'Must be an even number');

      await controller.setValue('evenNumber', 6);
      expect(controller.getFieldState('evenNumber')?.error, isNull);
    });

    test('JarBoolean validates specific value', () async {
      final controller = JarFormController();
      final schema = Jar.boolean().isTrue('Must be true');

      controller.register('terms', JarFieldConfig(schema: schema));

      await controller.setValue('terms', false);
      expect(controller.getFieldState('terms')?.error, 'Must be true');

      await controller.setValue('terms', true);
      expect(controller.getFieldState('terms')?.error, isNull);
    });

    test('JarBoolean validates with custom function', () async {
      final controller = JarFormController();
      final schema = Jar.boolean().custom((value) {
        if (value == null) return 'Required field';
        if (value != true) return 'Must accept terms';
        return null;
      });

      controller.register('termsAccepted', JarFieldConfig(schema: schema));

      await controller.setValue('termsAccepted', false);
      expect(controller.getFieldState('termsAccepted')?.error,
          'Must accept terms');

      await controller.setValue('termsAccepted', true);
      expect(controller.getFieldState('termsAccepted')?.error, isNull);
    });

    test('JarArray validates minimum length', () async {
      final controller = JarFormController();
      final schema = Jar.array(Jar.string()).min(2, 'At least 2 items');

      controller.register('tags', JarFieldConfig(schema: schema));

      await controller.setValue('tags', ['tag1']);
      expect(controller.getFieldState('tags')?.error, 'At least 2 items');

      await controller.setValue('tags', ['tag1', 'tag2']);
      expect(controller.getFieldState('tags')?.error, isNull);
    });

    test('JarArray validates unique elements', () async {
      final controller = JarFormController();
      final schema = Jar.array(Jar.string()).unique('Items must be unique');

      controller.register('options', JarFieldConfig(schema: schema));

      await controller.setValue('options', ['option1', 'option1']);
      expect(
          controller.getFieldState('options')?.error, 'Items must be unique');

      await controller.setValue('options', ['option1', 'option2']);
      expect(controller.getFieldState('options')?.error, isNull);
    });

    test('JarArray validates with custom function', () async {
      final controller = JarFormController();
      final schema = Jar.array(Jar.string()).custom((value) {
        if (value == null || value.isEmpty) return 'Required field';
        if (value.any((item) => item.length > 10))
          return 'Items cannot exceed 10 characters';
        return null;
      });

      controller.register('limitedTags', JarFieldConfig(schema: schema));

      await controller
          .setValue('limitedTags', ['short', 'thisIsTooLongForTheTest']);
      expect(controller.getFieldState('limitedTags')?.error,
          'Items cannot exceed 10 characters');

      await controller.setValue('limitedTags', ['tag1', 'tag2']);
      expect(controller.getFieldState('limitedTags')?.error, isNull);
    });

    test('JarObject validates complex structures', () async {
      final controller = JarFormController();
      final addressSchema = Jar.object({
        'street': Jar.string().required('Street required'),
        'city': Jar.string().required('City required'),
        'zipcode':
            Jar.string().matches(r'^\d{5}$', 'Zipcode must have 5 digits')
      });

      controller.register('address', JarFieldConfig(schema: addressSchema));

      await controller.setValue('address', {'street': 'Main Street'});
      expect(controller.getFieldState('address')?.error, isNotNull);

      await controller.setValue('address',
          {'street': 'Main Street', 'city': 'City', 'zipcode': '123'});
      expect(controller.getFieldState('address')?.error, isNotNull);

      await controller.setValue('address',
          {'street': 'Main Street', 'city': 'City', 'zipcode': '12345'});
      expect(controller.getFieldState('address')?.error, isNull);
    });

    test('JarObject with specific field requirements', () async {
      final controller = JarFormController();
      final formSchema = Jar.object({
        'name': Jar.string().optional(),
        'email': Jar.string().optional(),
        'phone': Jar.string().optional()
      }).requireAtLeastOne(['email', 'phone'], 'Must provide email or phone');

      controller.register('contact', JarFieldConfig(schema: formSchema));

      await controller.setValue('contact', {'name': 'John Doe'});
      expect(controller.getFieldState('contact')?.error,
          'Must provide email or phone');

      await controller.setValue(
          'contact', {'name': 'John Doe', 'email': 'john@example.com'});
      expect(controller.getFieldState('contact')?.error, isNull);

      await controller
          .setValue('contact', {'name': 'John Doe', 'phone': '1234567890'});
      expect(controller.getFieldState('contact')?.error, isNull);
    });

    test('JarObject validates with custom function', () async {
      final controller = JarFormController();
      final schema = Jar.object({
        'startDate': Jar.string(),
        'endDate': Jar.string(),
      }).custom((value) {
        if (value == null) return null;
        final startDate = value['startDate'];
        final endDate = value['endDate'];
        if (startDate == null || endDate == null) return null;

        if (startDate.compareTo(endDate) > 0) {
          return 'Start date must be before end date';
        }
        return null;
      });

      controller.register('dateRange', JarFieldConfig(schema: schema));

      await controller.setValue('dateRange', {
        'startDate': '2023-05-15',
        'endDate': '2023-05-10',
      });
      expect(controller.getFieldState('dateRange')?.error,
          'Start date must be before end date');

      await controller.setValue('dateRange', {
        'startDate': '2023-05-10',
        'endDate': '2023-05-15',
      });
      expect(controller.getFieldState('dateRange')?.error, isNull);
    });

    test('Conditional validation with when()', () async {
      final controller = JarFormController();

      final paymentTypeSchema =
          Jar.string().oneOf(['credit', 'paypal'], 'Invalid payment type');
      controller.register(
          'paymentType', JarFieldConfig(schema: paymentTypeSchema));

      final creditCardSchema = Jar.string().when('paymentType', {
        'credit': (s) => s
            .matches(r'^\d{16}$', 'Card number must have 16 digits')
            .required('Card number required'),
        'paypal': (s) => s.optional(),
      });
      controller.register(
          'creditCardNumber', JarFieldConfig(schema: creditCardSchema));

      await controller.setValue('paymentType', 'credit');

      await controller.setValue('creditCardNumber', '123');
      expect(controller.getFieldState('creditCardNumber')?.error,
          'Card number must have 16 digits');

      await controller.setValue('creditCardNumber', '1234567890123456');
      expect(controller.getFieldState('creditCardNumber')?.error, isNull);

      await controller.setValue('paymentType', 'paypal');
      expect(controller.getFieldState('creditCardNumber')?.error, isNull);
    });

    test('Schema composition with merge()', () async {
      final controller = JarFormController();

      final personalInfoSchema = Jar.object({
        'name': Jar.string().required('Name required'),
        'email': Jar.string().email('Invalid email').required('Email required'),
      });

      final addressSchema = Jar.object({
        'street': Jar.string().required('Street required'),
        'city': Jar.string().required('City required'),
      });

      final combinedSchema = personalInfoSchema.merge(addressSchema);

      controller.register('userInfo', JarFieldConfig(schema: combinedSchema));

      await controller.setValue('userInfo', {
        'name': 'John Doe',
        'email': 'john@example.com',
      });
      expect(controller.getFieldState('userInfo')?.error, isNotNull);

      await controller.setValue('userInfo', {
        'name': 'John Doe',
        'email': 'john@example.com',
        'street': 'Main Street',
        'city': 'City'
      });
      expect(controller.getFieldState('userInfo')?.error, isNull);
    });

    test('JarDate validates dates', () async {
      final controller = JarFormController();
      final now = DateTime.now();
      final pastDate = now.subtract(Duration(days: 10));
      final futureDate = now.add(Duration(days: 10));

      final birthDateSchema = Jar.date().past('Date must be in the past');
      controller.register('birthDate', JarFieldConfig(schema: birthDateSchema));

      await controller.setValue('birthDate', futureDate);
      expect(controller.getFieldState('birthDate')?.error,
          'Date must be in the past');

      await controller.setValue('birthDate', pastDate);
      expect(controller.getFieldState('birthDate')?.error, isNull);

      final meetingSchema = Jar.date().future('Date must be in the future');
      controller.register('meetingDate', JarFieldConfig(schema: meetingSchema));

      await controller.setValue('meetingDate', pastDate);
      expect(controller.getFieldState('meetingDate')?.error,
          'Date must be in the future');

      await controller.setValue('meetingDate', futureDate);
      expect(controller.getFieldState('meetingDate')?.error, isNull);
    });

    test('JarDate validates with custom function', () async {
      final controller = JarFormController();
      final schema = Jar.date().custom((value) {
        if (value == null) return 'Required field';

        final weekday = value.weekday;
        if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
          return 'Date cannot be on a weekend';
        }
        return null;
      });

      controller.register('workday', JarFieldConfig(schema: schema));

      final saturday =
          DateTime.now().add(Duration(days: (6 - DateTime.now().weekday) % 7));
      await controller.setValue('workday', saturday);
      expect(controller.getFieldState('workday')?.error,
          'Date cannot be on a weekend');

      final monday =
          DateTime.now().add(Duration(days: (8 - DateTime.now().weekday) % 7));
      await controller.setValue('workday', monday);
      expect(controller.getFieldState('workday')?.error, isNull);
    });

    test('JarMixed for mixed type values', () async {
      final controller = JarFormController();
      final schema =
          Jar.mixed().oneOf(['option1', 'option2', 3, 4], 'Invalid option');

      controller.register('mixedField', JarFieldConfig(schema: schema));

      await controller.setValue('mixedField', 'option3');
      expect(controller.getFieldState('mixedField')?.error, 'Invalid option');

      await controller.setValue('mixedField', 'option1');
      expect(controller.getFieldState('mixedField')?.error, isNull);

      await controller.setValue('mixedField', 3);
      expect(controller.getFieldState('mixedField')?.error, isNull);
    });

    test('JarMixed validates with custom function', () async {
      final controller = JarFormController();
      final schema = Jar.mixed().custom((value) {
        if (value == null) return 'Required field';

        if (value is String && value.length > 10) return 'String too long';
        if (value is int && value < 0) return 'Number must be positive';

        return null;
      });

      controller.register('mixedValidation', JarFieldConfig(schema: schema));

      await controller.setValue('mixedValidation', 'ThisStringIsTooLong');
      expect(controller.getFieldState('mixedValidation')?.error,
          'String too long');

      await controller.setValue('mixedValidation', -5);
      expect(controller.getFieldState('mixedValidation')?.error,
          'Number must be positive');

      await controller.setValue('mixedValidation', 'valid');
      expect(controller.getFieldState('mixedValidation')?.error, isNull);

      await controller.setValue('mixedValidation', 10);
      expect(controller.getFieldState('mixedValidation')?.error, isNull);
    });

    test('Complete form with multiple fields', () async {
      final controller = JarFormController();

      final userSchema = Jar.object({
        'username': Jar.string()
            .min(3, 'Minimum 3 characters')
            .required('Username required'),
        'email': Jar.string().email('Invalid email').required('Email required'),
        'age': Jar.number().min(18, 'Must be 18 or older'),
        'address': Jar.object({
          'street': Jar.string().required('Street required'),
          'city': Jar.string().required('City required'),
        }),
        'hobbies': Jar.array(Jar.string()).min(1, 'At least one hobby'),
        'agreeToTerms': Jar.boolean().isTrue('Must accept terms')
      });

      controller.register('user', JarFieldConfig(schema: userSchema));

      await controller.setValue('user', {
        'username': 'ab',
        'email': 'notanemail',
        'age': 16,
        'address': {'street': 'Main Street'},
        'hobbies': [],
        'agreeToTerms': false
      });

      expect(controller.getFieldState('user')?.error, isNotNull);

      await controller.setValue('user', {
        'username': 'john',
        'email': 'john@example.com',
        'age': 25,
        'address': {'street': 'Main Street', 'city': 'City'},
        'hobbies': ['Reading', 'Sports'],
        'agreeToTerms': true
      });

      expect(controller.getFieldState('user')?.error, isNull);
    });
  });
}
