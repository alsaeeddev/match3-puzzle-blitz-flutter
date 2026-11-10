/// Abstract interface for local persistence storage with schema versioning.
abstract interface class StorageService {
  /// Initializes the storage engine and runs schema migrations if needed.
  Future<void> init();

  // Generic typed getters and setters
  Future<void> setInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> setStringList(String key, List<String> values);
  Future<List<String>?> getStringList(String key);

  // JSON map helpers
  Future<void> setJson(String key, Map<String, dynamic> json);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> setJsonList(String key, List<Map<String, dynamic>> list);
  Future<List<Map<String, dynamic>>?> getJsonList(String key);

  /// Removes an entry by key.
  Future<void> remove(String key);

  /// Clears all keys in storage.
  Future<void> clear();

  // Schema versioning
  int get currentSchemaVersion;
  Future<void> migrate(int fromVersion, int toVersion);
}
