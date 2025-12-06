import 'package:flutter_test/flutter_test.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';
import 'mocks/schema_mocks.dart';

void main() {
  group('Performance Tests', () {
    test('Efficiently handles large forms', () async {
      final controller = JarFormController();
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        controller.register(
            'field$i', JarFieldConfig(schema: MockStringSchema()));
      }

      final registrationTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      for (int i = 0; i < 100; i++) {
        await controller.setValue('field$i', 'value$i');
      }

      final setValueTime = stopwatch.elapsedMilliseconds;

      expect(registrationTime, lessThan(500));
      expect(setValueTime, lessThan(1000));
    });

    test('Performance with async validators', () async {
      final controller = JarFormController();

      final asyncValidator = (dynamic value) async {
        await Future.delayed(Duration(milliseconds: 5));
        return null;
      };

      for (int i = 0; i < 10; i++) {
        controller.register(
            'field$i',
            JarFieldConfig<String>(
                schema: MockStringSchema(), asyncValidators: [asyncValidator]));
      }

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10; i++) {
        await controller.setValue('field$i', 'value$i');
      }

      final setValueTime = stopwatch.elapsedMilliseconds;

      expect(setValueTime, lessThan(500));
    });

    test('Performance with multiple watchers', () async {
      final controller = JarFormController();
      int watcherCallCount = 0;

      controller.register(
          'watched', JarFieldConfig(schema: MockStringSchema()));

      for (int i = 0; i < 20; i++) {
        controller.watch('watched', (dynamic value) {
          watcherCallCount++;
        });
      }

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 5; i++) {
        await controller.setValue('watched', 'value$i');
      }

      final setValueTime = stopwatch.elapsedMilliseconds;

      expect(watcherCallCount, 20 * 5);
      expect(setValueTime, lessThan(500));
    });

    test('Performance with nested objects', () async {
      final controller = JarFormController();

      final nestedSchema = Jar.object({
        'level1': Jar.object({
          'level2': Jar.object({
            'level3':
                Jar.object({'field': Jar.string().required('Field required')})
          })
        })
      });

      controller.register('nested', JarFieldConfig(schema: nestedSchema));

      final stopwatch = Stopwatch()..start();

      await controller.setValue('nested', {
        'level1': {
          'level2': {
            'level3': {'field': 'value'}
          }
        }
      });

      final nestedSetTime = stopwatch.elapsedMilliseconds;

      expect(nestedSetTime, lessThan(200));
      expect(controller.getFieldState('nested')?.error, isNull);
    });

    test('Performance with complex validation rules', () async {
      final controller = JarFormController();

      final passwordValidator = (dynamic value) {
        final String? stringValue = value as String?;
        return stringValue != null &&
                stringValue.contains(RegExp(r'[A-Z]')) &&
                stringValue.contains(RegExp(r'[0-9]'))
            ? null
            : 'Password needs uppercase letters and numbers';
      };

      final schema = Jar.object({
        'username': Jar.string()
            .min(3, 'Min 3 chars')
            .max(20, 'Max 20 chars')
            .matches(r'^[a-zA-Z0-9_]+$', 'Invalid chars')
            .required('Username required'),
        'email': Jar.string().email('Invalid email').required('Email required'),
        'password': Jar.string()
            .min(8, 'Min 8 chars')
            .custom(passwordValidator)
            .required('Password required'),
        'age': Jar.number().min(18, 'Must be 18+').integer('Must be integer'),
        'tags': Jar.array(Jar.string())
            .min(1, 'Min 1 tag')
            .max(5, 'Max 5 tags')
            .unique('Must be unique'),
        'address': Jar.object({
          'street': Jar.string().required('Street required'),
          'city': Jar.string().required('City required'),
          'zipcode': Jar.string().matches(r'^\d{5}$', 'Must be 5 digits')
        })
      });

      controller.register('form', JarFieldConfig(schema: schema));

      final confirmPasswordValidator = (dynamic value) async {
        final String? stringValue = value as String?;
        final formData = controller.getFieldValue<Map<String, dynamic>>('form');
        if (formData == null) return null;

        final password = formData['password'] as String?;
        return stringValue != password ? 'Passwords must match' : null;
      };

      controller.register(
          'confirmPassword',
          JarFieldConfig<String>(
              schema: Jar.string().required('Confirm password required'),
              asyncValidators: [confirmPasswordValidator]));

      final stopwatch = Stopwatch()..start();

      await controller.setValue('form', {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'Password123',
        'age': 25,
        'tags': ['tag1', 'tag2', 'tag3'],
        'address': {'street': 'Main Street', 'city': 'City', 'zipcode': '12345'}
      });

      await controller.setValue('confirmPassword', 'Password123');

      final validationTime = stopwatch.elapsedMilliseconds;

      expect(validationTime, lessThan(300));
      expect(controller.getFieldState('form')?.error, isNull);
      expect(controller.getFieldState('confirmPassword')?.error, isNull);
    });

    test('Performance with form reset/clear operations', () async {
      final controller = JarFormController();

      for (int i = 0; i < 50; i++) {
        controller.register('field$i',
            JarFieldConfig(schema: Jar.string(), defaultValue: 'default$i'));
      }

      for (int i = 0; i < 50; i++) {
        await controller.setValue('field$i', 'changed$i');
      }

      final stopwatch = Stopwatch()..start();

      controller.resetAll();

      final resetTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      for (int i = 0; i < 50; i++) {
        expect(controller.getFieldValue<String>('field$i'), 'default$i');
      }

      controller.clearAll();

      final clearTime = stopwatch.elapsedMilliseconds;

      expect(resetTime, lessThan(200));
      expect(clearTime, lessThan(200));

      for (int i = 0; i < 50; i++) {
        expect(controller.getFieldValue<String>('field$i'), isNull);
      }
    });
  });
}
