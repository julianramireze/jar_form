import 'package:flutter/material.dart';
import 'package:jar_form/controller.dart';

class JarFormProvider extends InheritedWidget {
  final JarFormController controller;

  const JarFormProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static JarFormProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<JarFormProvider>();
  }

  @override
  bool updateShouldNotify(JarFormProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}
