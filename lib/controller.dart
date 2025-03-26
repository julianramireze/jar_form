import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jar_form/jar_form.dart';
import 'field/config.dart';
import 'field/state.dart';

class JarFormController extends ChangeNotifier {
  final Map<String, dynamic> _fields = {};
  final Map<String, dynamic> _configs = {};
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, List<Function(dynamic value)>> _watchers = {};
  bool _isSubmitting = false;
  Future<void> Function(Map<String, dynamic> values)? _formOnSubmit;

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

    _controllers[name] = StreamController<JarFieldState<dynamic>>.broadcast();
    _watchers[name] = [];

    if (config.defaultValue != null) {
      setValue<T>(name, config.defaultValue);
    }

    _notifyField(name);
  }

  Future<void> setValue<T>(String name, T? value) async {
    if (!_configs.containsKey(name)) return;

    final fieldConfig = _configs[name] as JarFieldConfig<dynamic>;
    final oldState = _fields[name] as JarFieldState<dynamic>;

    var newState = JarFieldState<T>(
      value: value,
      error: oldState.error,
      isDirty: true,
      isTouched: oldState.isTouched,
      isValidating: oldState.isValidating,
      isDisabled: oldState.isDisabled,
      name: oldState.name,
      onChange: (v) => setValue<T>(name, v),
      markAsTouched: () => markAsTouched(name),
    );

    final allValues = getValues();
    allValues[name] = value;

    final result = fieldConfig.schema.validate(value, allValues);
    newState = newState.copyWith(error: result.error);

    if (newState.error == null && fieldConfig.asyncValidators.isNotEmpty) {
      newState = newState.copyWith(isValidating: true);
      _updateField(name, newState);

      for (final validator in fieldConfig.asyncValidators) {
        try {
          final error = await validator(value);

          if (error != null) {
            newState = newState.copyWith(error: error);
            _updateField(name, newState);
            break;
          }
        } catch (e) {
          newState =
              newState.copyWith(error: 'Validation error: ${e.toString()}');
          _updateField(name, newState);
          break;
        }
      }

      if (newState.error == null) {
        newState = newState.copyWith(isValidating: false);
        _updateField(name, newState);
      }
    } else {
      _updateField(name, newState);
    }

    _notifyWatchers(name, value);

    _revalidateOtherFields(name, allValues);
  }

  void _revalidateOtherFields(
      String changedField, Map<String, dynamic> allValues) {
    for (var fieldName in _fields.keys) {
      if (fieldName != changedField) {
        _revalidateField(fieldName, allValues);
      }
    }
    notifyListeners();
  }

  void _revalidateField(String name, Map<String, dynamic> allValues) {
    if (!_configs.containsKey(name)) return;

    final fieldConfig = _configs[name] as JarFieldConfig<dynamic>;
    final state = _fields[name] as JarFieldState<dynamic>;

    final result = fieldConfig.schema.validate(state.value, allValues);

    final updatedState = state.copyWith(error: result.error);
    _fields[name] = updatedState;
    _notifyField(name);
  }

  void watch<T>(String name, Function(T? value) callback) {
    if (!_watchers.containsKey(name)) {
      _watchers[name] = [];
    }

    void adaptedCallback(dynamic value) {
      try {
        T? typedValue;
        if (value == null) {
          typedValue = null;
        } else if (value is T) {
          typedValue = value;
        } else {
          typedValue = value as T?;
        }
        callback(typedValue);
      } catch (e) {
        callback(null);
      }
    }

    _watchers[name]?.add(adaptedCallback);
  }

  void unwatch<T>(String name, Function(T? value) callback) {
    _watchers[name]?.clear();
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
    final state = _fields[name] as JarFieldState<dynamic>?;
    if (state == null) return null;

    final value = state.value;
    if (value == null) return null;

    try {
      if (value is T) {
        return value;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  JarFieldState<T>? getFieldState<T>(String name) {
    final state = _fields[name] as JarFieldState<dynamic>?;
    if (state == null) return null;

    return JarFieldState<T>(
      value: state.value is T ? state.value as T? : null,
      error: state.error,
      isDirty: state.isDirty,
      isTouched: state.isTouched,
      isValidating: state.isValidating,
      isDisabled: state.isDisabled,
      name: state.name,
      onChange: (value) => setValue<T>(name, value),
      markAsTouched: () => markAsTouched(name),
    );
  }

  Stream<JarFieldState<T>>? getFieldStream<T>(String name) {
    final stream = _controllers[name]?.stream;
    if (stream == null) return null;

    return stream.map((dynamic state) {
      if (state is JarFieldState) {
        return JarFieldState<T>(
          value: state.value is T ? state.value as T? : null,
          error: state.error,
          isDirty: state.isDirty,
          isTouched: state.isTouched,
          isValidating: state.isValidating,
          isDisabled: state.isDisabled,
          name: state.name,
          onChange: (value) => setValue<T>(name, value),
          markAsTouched: () => markAsTouched(name),
        );
      }
      throw StateError('Invalid state type in stream');
    });
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
      await (onSubmit ?? _formOnSubmit)?.call(getValues());
      return true;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void trigger([dynamic fields]) {
    final values = getValues();
    bool updated = false;

    if (fields == null) {
      for (var name in _configs.keys) {
        _revalidateField(name, values);
        updated = true;
      }
    } else if (fields is String) {
      _revalidateField(fields, values);
      updated = true;
    } else if (fields is List<String>) {
      for (var name in fields) {
        _revalidateField(name, values);
        updated = true;
      }
    } else {
      throw ArgumentError('Invalid argument type');
    }

    if (updated) {
      notifyListeners();
    }
  }

  void _updateField<T>(String name, JarFieldState<T> state) {
    _fields[name] = state;
    _notifyField(name);
    notifyListeners();
  }

  void _notifyField(String name) {
    final controller = _controllers[name];
    final state = _fields[name];

    if (controller != null && state != null) {
      controller.add(state);
    }
  }

  void setFormSubmitCallback(
      Future<void> Function(Map<String, dynamic> values)? callback) {
    _formOnSubmit = callback;
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
