class JarArrayItem {
  final String id;
  final int index;
  final String _arrayName;

  const JarArrayItem({
    required this.id,
    required this.index,
    required String arrayName,
  }) : _arrayName = arrayName;

  String path([String? field]) {
    if (field == null) return '$_arrayName.$index';
    return '$_arrayName.$index.$field';
  }
}
