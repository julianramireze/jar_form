import 'package:flutter_test/flutter_test.dart';
import 'package:jar_form/jar_form.dart';

class User {
  final String name;
  final int age;

  User(this.name, this.age);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

void main() {
  group('JarFieldState Tests', () {
    test('Constructor initializes all values correctly', () {
      void onChange(String? value) {}
      void markAsTouched() {}

      final state = JarFieldState<String>(
        value: 'test value',
        error: 'test error',
        isDirty: true,
        isTouched: true,
        isValidating: true,
        isDisabled: true,
        name: 'testField',
        onChange: onChange,
        markAsTouched: markAsTouched,
      );

      expect(state.value, 'test value');
      expect(state.error, 'test error');
      expect(state.isDirty, true);
      expect(state.isTouched, true);
      expect(state.isValidating, true);
      expect(state.isDisabled, true);
      expect(state.name, 'testField');
      expect(state.onChange, onChange);
      expect(state.markAsTouched, markAsTouched);
    });

    test('Constructor with default values', () {
      final state = JarFieldState<String>(
        name: 'testField',
        onChange: (_) {},
        markAsTouched: () {},
      );

      expect(state.value, null);
      expect(state.error, null);
      expect(state.isDirty, false);
      expect(state.isTouched, false);
      expect(state.isValidating, false);
      expect(state.isDisabled, false);
      expect(state.name, 'testField');
    });

    test('copyWith preserves existing values', () {
      final state = JarFieldState<String>(
        value: 'test',
        error: 'error',
        isDirty: true,
        isTouched: true,
        isValidating: true,
        isDisabled: true,
        name: 'field',
        onChange: (_) {},
        markAsTouched: () {},
      );

      final newState = state.copyWith(
        error: null,
      );

      expect(newState.value, 'test');
      expect(newState.error, null);
      expect(newState.isDirty, true);
      expect(newState.isTouched, true);
      expect(newState.isValidating, true);
      expect(newState.isDisabled, true);
      expect(newState.name, 'field');
    });

    test('copyWith updates multiple fields', () {
      final state = JarFieldState<String>(
        value: 'test',
        error: 'error',
        isDirty: true,
        isTouched: true,
        isValidating: true,
        isDisabled: true,
        name: 'field',
        onChange: (_) {},
        markAsTouched: () {},
      );

      final newState = state.copyWith(
        value: 'new value',
        error: null,
        isDirty: false,
        isTouched: false,
      );

      expect(newState.value, 'new value');
      expect(newState.error, null);
      expect(newState.isDirty, false);
      expect(newState.isTouched, false);
      expect(newState.isValidating, true);
      expect(newState.isDisabled, true);
    });

    test('copyWith with undefined value keeps original value', () {
      final state = JarFieldState<String>(
        value: 'test',
        name: 'field',
        onChange: (_) {},
        markAsTouched: () {},
      );

      final newState = state.copyWith(
        isDirty: true,
      );

      expect(newState.value, 'test');
      expect(newState.isDirty, true);
    });

    test('copyWith with explicit null value', () {
      final state = JarFieldState<String>(
        value: 'test',
        name: 'field',
        onChange: (_) {},
        markAsTouched: () {},
      );

      final newState = state.copyWith(
        value: null,
      );

      expect(newState.value, null);
    });

    test('copyWith preserves onChange and markAsTouched functions', () {
      var changeValue = 'original';
      var touchedCalled = false;

      void onChange(String? value) {
        changeValue = value ?? 'null value';
      }

      void markAsTouched() {
        touchedCalled = true;
      }

      final state = JarFieldState<String>(
        value: 'test',
        name: 'field',
        onChange: onChange,
        markAsTouched: markAsTouched,
      );

      final newState = state.copyWith(
        value: 'new value',
      );

      newState.onChange('modified');
      expect(changeValue, 'modified');

      newState.markAsTouched();
      expect(touchedCalled, true);
    });

    test('JarFieldState with different generic types', () {
      final stringState = JarFieldState<String>(
        value: 'string value',
        name: 'stringField',
        onChange: (_) {},
        markAsTouched: () {},
      );
      expect(stringState.value, 'string value');

      final intState = JarFieldState<int>(
        value: 42,
        name: 'intField',
        onChange: (_) {},
        markAsTouched: () {},
      );
      expect(intState.value, 42);

      final boolState = JarFieldState<bool>(
        value: true,
        name: 'boolField',
        onChange: (_) {},
        markAsTouched: () {},
      );
      expect(boolState.value, true);

      final mapState = JarFieldState<Map<String, dynamic>>(
        value: {'key': 'value'},
        name: 'mapField',
        onChange: (_) {},
        markAsTouched: () {},
      );
      expect(mapState.value, {'key': 'value'});

      final listState = JarFieldState<List<String>>(
        value: ['item1', 'item2'],
        name: 'listField',
        onChange: (_) {},
        markAsTouched: () {},
      );
      expect(listState.value, ['item1', 'item2']);
    });

    test('JarFieldState with custom values', () {
      final user = User('John', 30);

      final userState = JarFieldState<User>(
        value: user,
        name: 'userField',
        onChange: (_) {},
        markAsTouched: () {},
      );

      expect(userState.value, user);

      final updatedUser = User('Jane', 25);
      final newUserState = userState.copyWith(
        value: updatedUser,
      );

      expect(newUserState.value, updatedUser);
    });

    test('JarFieldState for null fields', () {
      final nullState = JarFieldState<String?>(
        value: null,
        name: 'nullField',
        onChange: (_) {},
        markAsTouched: () {},
      );

      expect(nullState.value, null);

      final updatedState = nullState.copyWith(
        value: 'no longer null',
      );

      expect(updatedState.value, 'no longer null');

      final backToNullState = updatedState.copyWith(
        value: null,
      );

      expect(backToNullState.value, null);
    });
  });
}
