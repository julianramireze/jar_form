import 'package:jar/jar.dart';
import '../controller.dart';
import 'item.dart';

class JarFieldArrayController {
  final JarFormController _form;
  final String name;
  final JarObject itemSchema;
  final JarArray<Map<String, dynamic>> schema;
  final List<Map<String, dynamic>>? _defaultItems;
  final List<String> _ids = [];
  int _nextId = 0;

  JarFieldArrayController({
    required JarFormController form,
    required this.name,
    required this.itemSchema,
    required this.schema,
    List<Map<String, dynamic>>? defaultItems,
  })  : _form = form,
        _defaultItems = defaultItems;

  int get length => _ids.length;

  List<JarArrayItem> get items => [
        for (var i = 0; i < _ids.length; i++)
          JarArrayItem(id: _ids[i], index: i, arrayName: name),
      ];

  String? get error => _form.getFieldState(name)?.error;

  void append([Map<String, dynamic>? value]) {
    _registerSlot(_ids.length, value);
    _ids.add(_newId());
    _form.finalizeArray(name);
  }

  void insert(int index, [Map<String, dynamic>? value]) {
    final count = _ids.length;
    _registerSlot(count, null);
    for (var slot = count - 1; slot >= index; slot--) {
      _writeSlot(slot + 1, _readSlot(slot));
    }
    _writeSlot(index, value ?? {});
    _ids.insert(index, _newId());
    _form.finalizeArray(name);
  }

  void removeAt(int index) {
    final count = _ids.length;
    for (var slot = index; slot < count - 1; slot++) {
      _writeSlot(slot, _readSlot(slot + 1));
    }
    _unregisterSlot(count - 1);
    _ids.removeAt(index);
    _form.finalizeArray(name);
  }

  void move(int from, int to) {
    final snapshot = [for (var slot = 0; slot < _ids.length; slot++) _readSlot(slot)];
    snapshot.insert(to, snapshot.removeAt(from));
    _ids.insert(to, _ids.removeAt(from));
    for (var slot = 0; slot < snapshot.length; slot++) {
      _writeSlot(slot, snapshot[slot]);
    }
    _form.finalizeArray(name);
  }

  void clear() {
    for (var slot = _ids.length - 1; slot >= 0; slot--) {
      _unregisterSlot(slot);
    }
    _ids.clear();
    _form.finalizeArray(name);
  }

  void init() => _seed(_defaultItems);

  void resetToDefaults() {
    for (var slot = _ids.length - 1; slot >= 0; slot--) {
      _unregisterSlot(slot);
    }
    _ids.clear();
    _seed(_defaultItems);
    _form.finalizeArray(name);
  }

  List<Map<String, dynamic>> assemble() =>
      [for (var slot = 0; slot < _ids.length; slot++) _readSlot(slot)];

  Map<String, dynamic>? itemValuesForLeaf(String leafName) {
    final slot = _slotForLeaf(leafName);
    if (slot == null) return null;
    return _readSlot(slot);
  }

  int? _slotForLeaf(String leafName) {
    final prefix = '$name.';
    if (!leafName.startsWith(prefix)) return null;
    final rest = leafName.substring(prefix.length);
    final dot = rest.indexOf('.');
    final slotSegment = dot == -1 ? rest : rest.substring(0, dot);
    return int.tryParse(slotSegment);
  }

  void _seed(List<Map<String, dynamic>>? defaultItems) {
    if (defaultItems == null) return;
    for (final item in defaultItems) {
      _registerSlot(_ids.length, item);
      _ids.add(_newId());
    }
  }

  void _registerSlot(int slot, Map<String, dynamic>? value) {
    itemSchema.fields.forEach((field, fieldSchema) {
      _form.registerLeaf(_leaf(slot, field), fieldSchema, value?[field]);
    });
  }

  void _unregisterSlot(int slot) {
    for (final field in itemSchema.fields.keys) {
      _form.unregister(_leaf(slot, field));
    }
  }

  Map<String, dynamic> _readSlot(int slot) {
    final map = <String, dynamic>{};
    for (final field in itemSchema.fields.keys) {
      map[field] = _form.getFieldValue(_leaf(slot, field));
    }
    return map;
  }

  void _writeSlot(int slot, Map<String, dynamic> value) {
    for (final field in itemSchema.fields.keys) {
      _form.placeLeafValue(_leaf(slot, field), value[field]);
    }
  }

  String _leaf(int slot, String field) => '$name.$slot.$field';

  String _newId() => '$name-${_nextId++}';
}
