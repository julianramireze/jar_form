import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

class JarFieldConfig<T> {
  final JarSchema<T, JarSchema<T, dynamic>> schema;
  final T? defaultValue;
  final bool disabled;
  final List<AsyncValidator<T>> asyncValidators;

  const JarFieldConfig({
    required this.schema,
    this.defaultValue,
    this.disabled = false,
    this.asyncValidators = const [],
  });
}