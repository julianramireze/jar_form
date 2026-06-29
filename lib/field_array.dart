import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

class JarFieldArray extends StatefulWidget {
  final String name;
  final JarObject itemSchema;
  final JarArray<Map<String, dynamic>> Function(JarArray<Map<String, dynamic>>)?
      arraySchema;
  final List<Map<String, dynamic>>? defaultItems;
  final Widget Function(BuildContext context, JarFieldArrayController array)
      builder;

  const JarFieldArray({
    super.key,
    required this.name,
    required this.itemSchema,
    this.arraySchema,
    this.defaultItems,
    required this.builder,
  });

  @override
  JarFieldArrayState createState() => JarFieldArrayState();
}

class JarFieldArrayState extends State<JarFieldArray> {
  StreamSubscription? _subscription;
  JarFormController? _controller;
  JarFieldArrayController? _array;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription?.cancel();

    final formProvider = JarFormProvider.of(context);
    if (formProvider == null) return;

    _controller = formProvider.controller;
    _array = _controller!.registerArray(
      widget.name,
      itemSchema: widget.itemSchema,
      arraySchema: widget.arraySchema,
      defaultItems: widget.defaultItems,
    );

    final stream = _controller!.getFieldStream(widget.name);
    if (stream != null) {
      _subscription = stream.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _array == null) {
      throw StateError('No FormController found in context');
    }

    return widget.builder(context, _array!);
  }
}
