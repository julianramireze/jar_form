import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jar_form/jar_form.dart';

void main() {
  group('JarFormProvider Tests', () {
    testWidgets('Provider gives access to controller in widget tree',
        (WidgetTester tester) async {
      final controller = JarFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: JarFormProvider(
            controller: controller,
            child: Builder(
              builder: (context) {
                final provider = JarFormProvider.of(context);
                return Text(
                    provider != null ? 'Provider found' : 'Provider not found');
              },
            ),
          ),
        ),
      );

      expect(find.text('Provider found'), findsOneWidget);
    });

    testWidgets('Provider throws error when accessed outside scope',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final provider = JarFormProvider.of(context);
              return Text(
                  provider != null ? 'Provider found' : 'Provider not found');
            },
          ),
        ),
      );

      expect(find.text('Provider not found'), findsOneWidget);
    });

    testWidgets('updateShouldNotify works correctly',
        (WidgetTester tester) async {
      final controller1 = JarFormController();
      final controller2 = JarFormController();

      Widget buildTestWidget(JarFormController controller) {
        return MaterialApp(
          home: JarFormProvider(
            controller: controller,
            child: Builder(
              builder: (context) {
                final provider = JarFormProvider.of(context);

                return Text('Controller ID: ${provider!.controller.hashCode}');
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget(controller1));
      expect(
          find.text('Controller ID: ${controller1.hashCode}'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(controller2));
      expect(
          find.text('Controller ID: ${controller2.hashCode}'), findsOneWidget);
    });

    testWidgets('Controller in Provider updates with setState',
        (WidgetTester tester) async {
      late JarFormController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              controller = JarFormController();

              return JarFormProvider(
                controller: controller,
                child: Builder(
                  builder: (BuildContext context) {
                    final provider = JarFormProvider.of(context);
                    if (provider == null) {
                      return const Text('Provider not found');
                    }

                    return Column(
                      children: [
                        Text('Controller ID: ${provider.controller.hashCode}'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              controller = JarFormController();
                            });
                          },
                          child: const Text('Update controller'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      final initialControllerHash = controller.hashCode;
      expect(
          find.text('Controller ID: $initialControllerHash'), findsOneWidget);

      await tester.tap(find.text('Update controller'));
      await tester.pump();

      expect(controller.hashCode, isNot(equals(initialControllerHash)));
      expect(
          find.text('Controller ID: ${controller.hashCode}'), findsOneWidget);
    });
  });
}
