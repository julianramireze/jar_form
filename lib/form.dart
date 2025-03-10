import 'package:flutter/material.dart';
import 'package:jar/jar.dart';
import 'controller.dart';
import 'field/config.dart';
import 'provider.dart';

class JarForm extends StatefulWidget {
  final JarFormController controller;
  final JarSchema<dynamic, JarSchema<dynamic, dynamic>> schema;
  final Widget child;
  final Future<void> Function(Map<String, dynamic> values)? onSubmit;

  const JarForm({
    super.key,
    required this.controller,
    required this.schema,
    required this.child,
    this.onSubmit,
  });

  @override
  JarFormState createState() => JarFormState();
}

class JarFormState extends State<JarForm> {
  @override
  void initState() {
    super.initState();
    if (widget.schema is JarObject) {
      final objectSchema = widget.schema as JarObject;
      objectSchema.fields.forEach((name, fieldSchema) {
        if (!widget.controller.isRegistered(name)) {
          final typedSchema =
              fieldSchema as JarSchema<dynamic, JarSchema<dynamic, dynamic>>;
          widget.controller.register(
            name,
            JarFieldConfig(
              schema: typedSchema,
              defaultValue: null,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return JarFormProvider(
      controller: widget.controller,
      child: Form(
        child: widget.child,
      ),
    );
  }
}