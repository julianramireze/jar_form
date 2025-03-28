import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jar_form/jar_form.dart';

class JarFormField<T> extends StatefulWidget {
  final String name;
  final Widget Function(JarFieldState<T> field) builder;

  const JarFormField({
    super.key,
    required this.name,
    required this.builder,
  });

  @override
  JarFormFieldState<T> createState() => JarFormFieldState<T>();
}

class JarFormFieldState<T> extends State<JarFormField<T>> {
  StreamSubscription? _subscription;
  JarFormController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription?.cancel();

    final formProvider = JarFormProvider.of(context);
    if (formProvider != null) {
      _controller = formProvider.controller;
      final stream = _controller?.getFieldStream<T>(widget.name);
      if (stream != null) {
        _subscription = stream.listen((state) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      throw StateError('No FormController found in context');
    }

    final fieldState = _controller!.getFieldState<T>(widget.name);
    if (fieldState == null) {
      throw StateError('Field ${widget.name} not found in form');
    }

    return widget.builder(fieldState);
  }
}
