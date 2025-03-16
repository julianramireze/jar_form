import 'package:flutter_test/flutter_test.dart';
import 'package:jar_form/jar_form.dart';
import 'mocks/schema_mocks.dart';

void main() {
  group('JarFormController Tests', () {
    late JarFormController controller;
    late MockStringSchema mockSchema;

    setUp(() {
      mockSchema = MockStringSchema();
      controller = JarFormController();
    });

    test('register adds field correctly', () {
      controller.register('name', JarFieldConfig(schema: mockSchema));
      expect(controller.isRegistered('name'), true);
    });

    test('setValue updates value and marks as dirty', () async {
      controller.register('name', JarFieldConfig(schema: mockSchema));
      await controller.setValue('name', 'test');

      final state = controller.getFieldState('name');
      expect(state?.value, 'test');
      expect(state?.isDirty, true);
    });

    test('default value is set when registering', () {
      controller.register(
          'name', JarFieldConfig(schema: mockSchema, defaultValue: 'default'));

      expect(controller.getFieldValue('name'), 'default');
    });

    test('synchronous validation fails correctly', () async {
      final failingSchema = MockFailingStringSchema('Validation error');

      controller.register('name', JarFieldConfig(schema: failingSchema));
      await controller.setValue('name', 'test');

      expect(controller.getFieldState('name')?.error, 'Validation error');
      expect(controller.isValid, false);
    });

    test('asynchronous validation works', () async {
      final asyncValidator = (dynamic value) async {
        await Future.delayed(Duration(milliseconds: 10));
        return value == 'invalid' ? 'Async error' : null;
      };

      controller.register(
          'name',
          JarFieldConfig<String>(
              schema: mockSchema, asyncValidators: [asyncValidator]));

      await controller.setValue('name', 'valid');
      expect(controller.getFieldState('name')?.error, null);

      await controller.setValue('name', 'invalid');
      expect(controller.getFieldState('name')?.error, 'Async error');
    });

    test('reset restores field to initial state', () async {
      controller.register(
          'name', JarFieldConfig(schema: mockSchema, defaultValue: 'default'));

      await controller.setValue('name', 'changed');
      controller.reset('name');

      final state = controller.getFieldState('name');
      expect(state?.value, 'default');
      expect(state?.isDirty, false);
      expect(state?.isTouched, false);
    });

    test('submit validates all fields before submitting', () async {
      final failingSchema = MockFailingStringSchema('Error');
      final validSchema = mockSchema;

      controller.register('invalid', JarFieldConfig(schema: failingSchema));
      controller.register('valid', JarFieldConfig(schema: validSchema));

      bool submitCalled = false;
      final result = await controller.submit((_) async {
        submitCalled = true;
      });

      expect(result, false);
      expect(submitCalled, false);
    });

    test('watchers are notified when value changes', () async {
      controller.register('name', JarFieldConfig(schema: mockSchema));

      String? watchedValue;
      controller.watch<String>('name', (value) {
        watchedValue = value;
      });

      await controller.setValue('name', 'observed');
      expect(watchedValue, 'observed');
    });

    test('markAsTouched updates touched state', () {
      controller.register('name', JarFieldConfig(schema: mockSchema));

      controller.markAsTouched('name');
      expect(controller.getFieldState('name')?.isTouched, true);

      controller.markAsUntouched('name');
      expect(controller.getFieldState('name')?.isTouched, false);
    });

    test('enable/disable updates disabled state', () {
      controller.register(
          'name', JarFieldConfig(schema: mockSchema, disabled: true));

      expect(controller.getFieldState('name')?.isDisabled, true);

      controller.enable('name');
      expect(controller.getFieldState('name')?.isDisabled, false);

      controller.disable('name');
      expect(controller.getFieldState('name')?.isDisabled, true);
    });

    test('clear resets value but keeps dirty state', () async {
      controller.register(
          'name', JarFieldConfig(schema: mockSchema, defaultValue: 'default'));

      controller.clear('name');
      final state = controller.getFieldState('name');
      expect(state?.value, null);
      expect(state?.isDirty, true);
    });

    test('clearAll clears all fields', () {
      controller.register(
          'field1', JarFieldConfig(schema: mockSchema, defaultValue: 'value1'));
      controller.register(
          'field2', JarFieldConfig(schema: mockSchema, defaultValue: 'value2'));

      controller.clearAll();

      expect(controller.getFieldValue('field1'), null);
      expect(controller.getFieldValue('field2'), null);
    });

    test('resetAll resets all fields', () async {
      controller.register('field1',
          JarFieldConfig(schema: mockSchema, defaultValue: 'default1'));
      controller.register('field2',
          JarFieldConfig(schema: mockSchema, defaultValue: 'default2'));

      await controller.setValue('field1', 'changed1');
      await controller.setValue('field2', 'changed2');

      controller.resetAll();

      expect(controller.getFieldValue('field1'), 'default1');
      expect(controller.getFieldValue('field2'), 'default2');
    });

    test('getValues returns all values', () async {
      controller.register(
          'field1', JarFieldConfig(schema: mockSchema, defaultValue: 'value1'));
      controller.register(
          'field2', JarFieldConfig(schema: mockSchema, defaultValue: 'value2'));

      final values = controller.getValues();
      expect(values, {
        'field1': 'value1',
        'field2': 'value2',
      });
    });

    test('getErrors returns all errors', () async {
      controller.register('valid', JarFieldConfig(schema: mockSchema));
      controller.register(
          'invalid', JarFieldConfig(schema: MockFailingStringSchema('Error')));

      await controller.setValue('valid', 'value');
      await controller.setValue('invalid', 'value');

      final errors = controller.getErrors();
      expect(errors['valid'], null);
      expect(errors['invalid'], 'Error');
    });
  });
}
