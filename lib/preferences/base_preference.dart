import 'package:database_manager_package/app_utility/app_utility_logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BasePreferences {
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _instancePreferences async {
    if (_preferences != null) return _preferences!;
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }

  Future<T?> fetch<T>(String key) async {
    SharedPreferences preferences = await _instancePreferences;
    return preferences.get(key) as T?;
  }

  void save<T>(String key, T value) async {
    if (value == null) return;
    await _save(key, value);
  }

  Future<void> _save<T>(String key, T value) async {
    SharedPreferences preferences = await _instancePreferences;
    if (value is String) {
      await preferences.setString(key, value);
    } else if (value is int) {
      await preferences.setInt(key, value);
    } else if (value is double) {
      await preferences.setDouble(key, value);
    } else if (value is bool) {
      await preferences.setBool(key, value);
    } else if (value is List<String>) {
      await preferences.setStringList(key, value);
    } else {
      AppUtility.log("[-] PREFERENCE VALUE TYPE NOT DEFINED => $value => ${value.runtimeType}");
    }
  }

  void remove(String key) async {
    SharedPreferences preferences = await _instancePreferences;
    await preferences.remove(key);
  }

  void clearAll() async {
    SharedPreferences preferences = await _instancePreferences;
    await preferences.clear();
  }
}
