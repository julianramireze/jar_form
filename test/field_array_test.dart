import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

JarObject _professionSchema() => Jar.object({
      'startTime': Jar.string().required('Start required'),
      'endTime': Jar.string().required('End required'),
    });

JarObject _chefSchema() => Jar.object({
      'profession': Jar.string().required('Profession required'),
      'foodType': Jar.string().when('profession', {
        'Chef': (s) => s.required('Food type required for chef'),
      }),
    });

void main() {
  group('JarFieldArrayController operations', () {
    late JarFormController controller;
    late JarFieldArrayController array;

    setUp(() {
      controller = JarFormController();
      array = controller.registerArray('professions',
          itemSchema: _professionSchema());
    });

    test('starts empty', () {
      expect(array.length, 0);
      expect(array.items, isEmpty);
    });

    test('append adds items and exposes stable indexed ids', () {
      array.append({'startTime': '09:00', 'endTime': '17:00'});
      array.append({'startTime': '10:00', 'endTime': '14:00'});

      expect(array.length, 2);
      expect(array.items[0].index, 0);
      expect(array.items[1].index, 1);
      expect(array.items[0].id, isNot(array.items[1].id));
      expect(array.items[0].path('startTime'), 'professions.0.startTime');
      expect(array.items[1].path('endTime'), 'professions.1.endTime');
    });

    test('getValues collapses leaf fields into a nested list', () {
      array.append({'startTime': '09:00', 'endTime': '17:00'});
      array.append({'startTime': '10:00', 'endTime': '14:00'});

      final values = controller.getValues();

      expect(values['professions'], [
        {'startTime': '09:00', 'endTime': '17:00'},
        {'startTime': '10:00', 'endTime': '14:00'},
      ]);
      expect(values.keys.where((k) => k.startsWith('professions.')), isEmpty);
    });

    test('removeAt keeps stable ids and shifts values down', () {
      array.append({'startTime': 'a', 'endTime': 'A'});
      array.append({'startTime': 'b', 'endTime': 'B'});
      array.append({'startTime': 'c', 'endTime': 'C'});

      final idFirst = array.items[0].id;
      final idThird = array.items[2].id;

      array.removeAt(1);

      expect(array.length, 2);
      expect(array.items[0].id, idFirst);
      expect(array.items[1].id, idThird);
      expect(controller.getValues()['professions'], [
        {'startTime': 'a', 'endTime': 'A'},
        {'startTime': 'c', 'endTime': 'C'},
      ]);
    });

    test('insert places value at index and shifts the rest up', () {
      array.append({'startTime': 'a', 'endTime': 'A'});
      array.append({'startTime': 'c', 'endTime': 'C'});

      array.insert(1, {'startTime': 'b', 'endTime': 'B'});

      expect(controller.getValues()['professions'], [
        {'startTime': 'a', 'endTime': 'A'},
        {'startTime': 'b', 'endTime': 'B'},
        {'startTime': 'c', 'endTime': 'C'},
      ]);
    });

    test('move reorders items and their values', () {
      array.append({'startTime': 'a', 'endTime': 'A'});
      array.append({'startTime': 'b', 'endTime': 'B'});
      array.append({'startTime': 'c', 'endTime': 'C'});

      final idFirst = array.items[0].id;
      array.move(0, 2);

      expect(array.items[2].id, idFirst);
      expect(controller.getValues()['professions'], [
        {'startTime': 'b', 'endTime': 'B'},
        {'startTime': 'c', 'endTime': 'C'},
        {'startTime': 'a', 'endTime': 'A'},
      ]);
    });

    test('clear removes all items', () {
      array.append({'startTime': 'a', 'endTime': 'A'});
      array.append({'startTime': 'b', 'endTime': 'B'});

      array.clear();

      expect(array.length, 0);
      expect(controller.getValues()['professions'], isEmpty);
      expect(controller.isRegistered('professions.0.startTime'), false);
    });

    test('defaultItems seed the array on registration', () {
      final seeded = JarFormController().registerArray(
        'professions',
        itemSchema: _professionSchema(),
        defaultItems: [
          {'startTime': '09:00', 'endTime': '17:00'},
        ],
      );

      expect(seeded.length, 1);
      expect(seeded.items[0].path('startTime'), 'professions.0.startTime');
    });

    test('resetAll restores default items', () {
      final form = JarFormController();
      final seeded = form.registerArray(
        'professions',
        itemSchema: _professionSchema(),
        defaultItems: [
          {'startTime': '09:00', 'endTime': '17:00'},
        ],
      );

      seeded.append({'startTime': '11:00', 'endTime': '12:00'});
      expect(seeded.length, 2);

      form.resetAll();

      expect(seeded.length, 1);
      expect(form.getValues()['professions'], [
        {'startTime': '09:00', 'endTime': '17:00'},
      ]);
    });
  });

  group('JarFieldArray validation', () {
    test('array-level min surfaces on array.error and isValid', () {
      final controller = JarFormController();
      final array = controller.registerArray(
        'professions',
        itemSchema: _professionSchema(),
        arraySchema: (base) => base.min(1, 'At least one profession'),
      );

      expect(array.error, 'At least one profession');
      expect(controller.isValid, false);

      array.append({'startTime': '09:00', 'endTime': '17:00'});

      expect(array.error, isNull);
      expect(controller.isValid, true);
    });

    test('per-field leaf errors still surface', () async {
      final controller = JarFormController();
      final array = controller.registerArray('professions',
          itemSchema: _professionSchema());

      array.append({'startTime': null, 'endTime': '17:00'});

      await controller.setValue('professions.0.startTime', null);
      controller.trigger();

      expect(controller.getFieldState('professions.0.startTime')?.error,
          'Start required');
      expect(controller.isValid, false);

      await controller.setValue('professions.0.startTime', '09:00');

      expect(controller.getFieldState('professions.0.startTime')?.error, isNull);
    });

    test('submit delivers the nested array payload', () async {
      final controller = JarFormController();
      final array = controller.registerArray('professions',
          itemSchema: _professionSchema());

      array.append({'startTime': '09:00', 'endTime': '17:00'});

      Map<String, dynamic>? submitted;
      final ok = await controller.submit((values) async {
        submitted = values;
      });

      expect(ok, true);
      expect(submitted?['professions'], [
        {'startTime': '09:00', 'endTime': '17:00'},
      ]);
    });
  });

  group('JarFieldArray widget', () {
    Widget buildHarness(JarFormController controller) {
      return MaterialApp(
        home: Scaffold(
          body: JarForm(
            controller: controller,
            schema: Jar.object({}),
            child: Material(
              child: SingleChildScrollView(
                child: JarFieldArray(
                  name: 'professions',
                  itemSchema: _professionSchema(),
                  defaultItems: const [
                    {'startTime': 'a', 'endTime': 'A'},
                    {'startTime': 'b', 'endTime': 'B'},
                    {'startTime': 'c', 'endTime': 'C'},
                  ],
                  builder: (context, array) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in array.items)
                        Row(
                          key: ValueKey(item.id),
                          children: [
                            Expanded(
                              child: JarFormField<String>(
                                name: item.path('startTime'),
                                builder: (field) => Text(
                                  field.value ?? '',
                                  key: Key('value-${item.id}'),
                                ),
                              ),
                            ),
                            IconButton(
                              key: Key('remove-${item.id}'),
                              icon: const Icon(Icons.delete),
                              onPressed: () => array.removeAt(item.index),
                            ),
                          ],
                        ),
                      TextButton(
                        key: const Key('add'),
                        onPressed: () =>
                            array.append({'startTime': 'new', 'endTime': ''}),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders one row per item', (tester) async {
      await tester.pumpWidget(buildHarness(JarFormController()));

      expect(find.byType(IconButton), findsNWidgets(3));
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('append adds a row', (tester) async {
      await tester.pumpWidget(buildHarness(JarFormController()));

      await tester.tap(find.byKey(const Key('add')));
      await tester.pump();

      expect(find.byType(IconButton), findsNWidgets(4));
      expect(find.text('new'), findsOneWidget);
    });

    testWidgets('removeAt removes the right row and shifts the rest',
        (tester) async {
      final controller = JarFormController();
      await tester.pumpWidget(buildHarness(controller));

      final array = controller.getArray('professions')!;
      final middleId = array.items[1].id;

      await tester.tap(find.byKey(Key('remove-$middleId')));
      await tester.pump();

      expect(find.byType(IconButton), findsNWidgets(2));
      expect(find.text('b'), findsNothing);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
      expect(controller.getValues()['professions'], [
        {'startTime': 'a', 'endTime': 'A'},
        {'startTime': 'c', 'endTime': 'C'},
      ]);
    });
  });

  group('JarFieldArray item-scoped validation', () {
    test('leaf .when discriminates against its own item siblings', () async {
      final controller = JarFormController();
      final array =
          controller.registerArray('professions', itemSchema: _chefSchema());

      array.append({'profession': 'Chef'});

      await controller.setValue('professions.0.foodType', null);
      expect(controller.getFieldState('professions.0.foodType')?.error,
          'Food type required for chef');

      await controller.setValue('professions.0.foodType', 'Italian');
      expect(controller.getFieldState('professions.0.foodType')?.error, isNull);
    });

    test('leaf .when does not require when the discriminator differs',
        () async {
      final controller = JarFormController();
      final array =
          controller.registerArray('professions', itemSchema: _chefSchema());

      array.append({'profession': 'Waiter'});

      await controller.setValue('professions.0.foodType', null);
      expect(controller.getFieldState('professions.0.foodType')?.error, isNull);
    });

    test('trigger surfaces discriminated leaf errors independently per item',
        () {
      final controller = JarFormController();
      final array =
          controller.registerArray('professions', itemSchema: _chefSchema());

      array.append({'profession': 'Chef'});
      array.append({'profession': 'Waiter'});

      controller.trigger();

      expect(controller.getFieldState('professions.0.foodType')?.error,
          'Food type required for chef');
      expect(controller.getFieldState('professions.1.foodType')?.error, isNull);
      expect(controller.isValid, false);
    });

    test('getFieldValue<T> returns typed values for array leaves', () {
      final controller = JarFormController();
      final array =
          controller.registerArray('professions', itemSchema: _chefSchema());

      array.append({'profession': 'Chef', 'foodType': 'Italian'});

      expect(controller.getFieldValue<String>('professions.0.profession'),
          'Chef');
      expect(controller.getFieldValue<String>('professions.0.foodType'),
          'Italian');
    });

    test('leaf still discriminates on a top-level field (merged context)',
        () async {
      final controller = JarFormController();
      controller.register('mode', JarFieldConfig(schema: Jar.string()));
      final array = controller.registerArray(
        'professions',
        itemSchema: Jar.object({
          'note': Jar.string().when('mode', {
            'strict': (s) => s.required('Note required in strict mode'),
          }),
        }),
      );

      array.append({'note': null});

      await controller.setValue('mode', 'strict');
      await controller.setValue('professions.0.note', null);

      expect(controller.getFieldState('professions.0.note')?.error,
          'Note required in strict mode');
      expect(controller.isValid, false);
    });

    test('leaf .test discriminates with item context and runs on null',
        () async {
      final controller = JarFormController();
      final array = controller.registerArray(
        'professions',
        itemSchema: Jar.object({
          'profession': Jar.string().required('Profession required'),
          'foodType': Jar.string().test((value, ctx) =>
              ctx.parent?['profession'] == 'Chef' &&
                      (value == null || value.isEmpty)
                  ? 'Food type required for chef'
                  : null),
        }),
      );

      array.append({'profession': 'Chef'});
      controller.trigger();
      expect(controller.getFieldState('professions.0.foodType')?.error,
          'Food type required for chef');

      await controller.setValue('professions.0.foodType', 'Italian');
      expect(controller.getFieldState('professions.0.foodType')?.error, isNull);
    });
  });
}
