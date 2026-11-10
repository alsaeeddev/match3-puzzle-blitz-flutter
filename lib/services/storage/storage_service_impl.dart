import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// SharedPreferences implementation of [StorageService] with JSON serialization,
/// corrupted-data fallback, and versioned schema migrations.
class StorageServiceImpl implements StorageService {
  static const String _schemaVersionKey = '_schema_version';
  static const int _targetSchemaVersion = 1;

  SharedPreferences? _prefs;

  StorageServiceImpl([SharedPreferences? prefs]) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  int get currentSchemaVersion => _targetSchemaVersion;

  @override
  Future<void> init() async {
    final prefs = await _getPrefs();
    final storedVersion = prefs.getInt(_schemaVersionKey) ?? 0;
    if (storedVersion != currentSchemaVersion) {
      await migrate(storedVersion, currentSchemaVersion);
      await prefs.setInt(_schemaVersionKey, currentSchemaVersion);
    }
  }

  @override
  Future<void> migrate(int fromVersion, int toVersion) async {
    debugPrint(
        '[StorageService] Running migration from schema v$fromVersion to v$toVersion');
    if (fromVersion == 0) {
      // First version or clean install, nothing to migrate
      return;
    }
    if (fromVersion > toVersion) {
      // Data from a newer, incompatible schema version - wipe cleanly
      await clear();
      return;
    }

    // Stepwise migration loop for future schema increments
    for (var current = fromVersion; current < toVersion; current++) {
      switch (current) {
        case 1:
          // Placeholder for future schema v1 -> v2 key renames or conversions
          break;
        default:
          break;
      }
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    final prefs = await _getPrefs();
    return prefs.getInt(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = await _getPrefs();
    return prefs.getBool(key);
  }

  @override
  Future<void> setStringList(String key, List<String> values) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(key, values);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final prefs = await _getPrefs();
    return prefs.getStringList(key);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> json) async {
    final prefs = await _getPrefs();
    final raw = jsonEncode(json);
    await prefs.setString(key, raw);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      // If content was not a JSON map, remove bad entry
      await remove(key);
      return null;
    } on FormatException {
      // Corrupted JSON fallback
      await remove(key);
      return null;
    } catch (_) {
      await remove(key);
      return null;
    }
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _getPrefs();
    final raw = jsonEncode(list);
    await prefs.setString(key, raw);
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      await remove(key);
      return null;
    } on FormatException {
      await remove(key);
      return null;
    } catch (_) {
      await remove(key);
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
