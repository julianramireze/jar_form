import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'field/config.dart';
import 'field/state.dart';

class JarFormController extends ChangeNotifier {
  final Map<String, dynamic> _fields = {};
  final Map<String, dynamic> _configs = {};
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, List<Function(dynamic value)>> _watchers = {};
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;
  bool get isValid =>
      !_fields.values.any((state) => (state as JarFieldState).error != null);
  bool get isDirty =>
      _fields.values.any((state) => (state as JarFieldState).isDirty);
  bool get isTouched =>
      _fields.values.any((state) => (state as JarFieldState).isTouched);
  bool get isValidating =>
      _fields.values.any((state) => (state as JarFieldState).isValidating);

  bool isRegistered(String name) => _configs.containsKey(name);

  void register<T>(String name, JarFieldConfig<T> config) {
    if (isRegistered(name)) return;

    _configs[name] = config;
    _fields[name] = JarFieldState<T>(
      value: config.defaultValue,
      isDisabled: config.disabled,
      name: name,
      onChange: (value) => setValue<T>(name, value),
      markAsTouched: () => markAsTouched(name),
    );
    _controllers[name] = StreamController<JarFieldState<T>>.broadcast();
    _watchers[name] = [];

    if (config.defaultValue != null) {
      setValue<T>(name, config.defaultValue);
    }

    _notifyField(name);
  }

  Future<void> setValue<T>(String name, T? value) async {
    if (!_configs.containsKey(name)) return;

    final dynamicConfig = _configs[name] as JarFieldConfig<dynamic>;
    final config = JarFieldConfig<T>(
      schema: dynamicConfig.schema as dynamic,
      defaultValue: dynamicConfig.defaultValue as T?,
      disabled: dynamicConfig.disabled,
      asyncValidators:
          dynamicConfig.asyncValidators
              .map((validator) => (T? value) => validator(value))
              .toList(),
    );

    final oldState = _fields[name] as JarFieldState<dynamic>;
    final typedOldState = JarFieldState<T>(
      value: oldState.value as T?,
      error: oldState.error,
      isDirty: oldState.isDirty,
      isTouched: oldState.isTouched,
      isValidating: oldState.isValidating,
      isDisabled: oldState.isDisabled,
      name: oldState.name,
      onChange: oldState.onChange,
      markAsTouched: oldState.markAsTouched,
    );

    var newState = typedOldState.copyWith(value: value, isDirty: true);

    final allValues = getValues();
    allValues[name] = value;

    final result = config.schema.validate(value, allValues);
    newState = newState.copyWith(error: result.error);

    if (newState.error == null && config.asyncValidators.isNotEmpty) {
      newState = newState.copyWith(isValidating: true);
      _updateField(name, newState);

      for (final validator in config.asyncValidators) {
        final error = await validator(value);
        if (error != null) {
          newState = newState.copyWith(error: error);
          break;
        }
      }

      newState = newState.copyWith(isValidating: false);
    }

    _updateField(name, newState);
    _notifyWatchers(name, value);
  }

  void watch<T>(String name, Function(T? value) callback) {
    _watchers[name]?.add(callback as Function(dynamic));
  }

  void unwatch<T>(String name, Function(T? value) callback) {
    _watchers[name]?.remove(callback);
  }

  void _notifyWatchers(String name, dynamic value) {
    _watchers[name]?.forEach((callback) => callback(value));
  }

  void markAsTouched(String name) {
    final state = _fields[name] as JarFieldState;
    _updateField(name, state.copyWith(isTouched: true));
  }

  void markAsUntouched(String name) {
    final state = _fields[name] as JarFieldState;
    _updateField(name, state.copyWith(isTouched: false));
  }

  void enable(String name) {
    final state = _fields[name] as JarFieldState;
    _updateField(name, state.copyWith(isDisabled: false));
  }

  void disable(String name) {
    final state = _fields[name] as JarFieldState;
    _updateField(name, state.copyWith(isDisabled: true));
  }

  void reset(String name) {
    final config = _configs[name] as JarFieldConfig;
    final state = _fields[name] as JarFieldState;

    _updateField(
      name,
      state.copyWith(
        value: config.defaultValue,
        error: null,
        isDirty: false,
        isTouched: false,
        isValidating: false,
        isDisabled: config.disabled,
      ),
    );
  }

  void resetAll() {
    _configs.keys.forEach(reset);
  }

  void clear(String name) {
    final state = _fields[name] as JarFieldState;
    _updateField(name, state.copyWith(value: null, error: null, isDirty: true));
  }

  void clearAll() {
    _fields.keys.forEach(clear);
  }

  T? getFieldValue<T>(String name) {
    final state = _fields[name] as JarFieldState<T>?;
    return state?.value;
  }

  JarFieldState<T>? getFieldState<T>(String name) {
    return _fields[name] as JarFieldState<T>?;
  }

  Stream<JarFieldState<T>>? getFieldStream<T>(String name) {
    return _controllers[name]?.stream as Stream<JarFieldState<T>>?;
  }

  Map<String, dynamic> getValues() {
    return Map.fromEntries(
      _fields.entries.map(
        (e) => MapEntry(e.key, (e.value as JarFieldState).value),
      ),
    );
  }

  Map<String, String?> getErrors() {
    return Map.fromEntries(
      _fields.entries.map(
        (e) => MapEntry(e.key, (e.value as JarFieldState).error),
      ),
    );
  }

  Future<bool> submit([
    Future<void> Function(Map<String, dynamic> values)? onSubmit,
  ]) async {
    trigger();

    if (_isSubmitting || !isValid) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      await onSubmit?.call(getValues());
      return true;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void trigger([dynamic fields]) {
    final values = getValues();

    if (fields == null) {
      for (var name in _configs.keys) {
        final value = values[name];
        setValue(name, value);
      }
    } else if (fields is String) {
      setValue(fields, values[fields]);
    } else if (fields is List<String>) {
      for (var name in fields) {
        final value = values[name];
        setValue(name, value);
      }
    } else {
      throw ArgumentError('Invalid argument type');
    }
  }

  void _updateField<T>(String name, JarFieldState<T> state) {
    _fields[name] = state;
    _notifyField(name);
    notifyListeners();
  }

  void _notifyField(String name) {
    _controllers[name]?.add(_fields[name]);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _watchers.clear();
    super.dispose();
  }
}