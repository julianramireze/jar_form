class JarFieldState<T> {
  final T? value;
  final String? error;
  final bool isDirty;
  final bool isTouched;
  final bool isValidating;
  final bool isDisabled;
  final String name;
  final void Function(T?) onChange;
  final void Function() markAsTouched;

  const JarFieldState({
    this.value,
    this.error,
    this.isDirty = false,
    this.isTouched = false,
    this.isValidating = false,
    this.isDisabled = false,
    required this.name,
    required this.onChange,
    required this.markAsTouched,
  });

  JarFieldState<T> copyWith({
    T? value,
    String? error,
    bool? isDirty,
    bool? isTouched,
    bool? isValidating,
    bool? isDisabled,
  }) {
    return JarFieldState<T>(
      value: value ?? this.value,
      error: error,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      isValidating: isValidating ?? this.isValidating,
      isDisabled: isDisabled ?? this.isDisabled,
      name: name,
      onChange: onChange,
      markAsTouched: markAsTouched,
    );
  }
}
