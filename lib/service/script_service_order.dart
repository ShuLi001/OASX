part of 'script_service.dart';

extension ScriptServiceOrderX on ScriptService {
  String get _scriptOrderStorageKey =>
      '${StorageKey.homeScriptOrder.name}:${ApiClient().address}';

  List<String> get _savedScriptOrder {
    final raw = _storage.read(_scriptOrderStorageKey);
    return raw is List ? raw.whereType<String>().toSet().toList() : [];
  }

  /// Persists a complete display order separately for each OAS backend.
  Future<void> saveScriptOrder(List<String> names) async {
    final current = scriptOrderList.toSet();
    if (names.length != current.length || !names.toSet().containsAll(current)) {
      return;
    }
    final storageKey = _scriptOrderStorageKey;
    await _storage.write(storageKey, names);
    if (_scriptOrderStorageKey == storageKey &&
        scriptOrderList.length == names.length &&
        scriptOrderList.toSet().containsAll(names)) {
      scriptOrderList.assignAll(names);
    }
  }

  Future<void> _rememberRenamedScript(String oldName, String newName) =>
      _storage.write(_scriptOrderStorageKey, [
        for (final name in scriptOrderList) name == oldName ? newName : name,
      ]);
}
