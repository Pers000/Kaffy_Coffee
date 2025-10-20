import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _prefsKey = 'user_role';
  static const _userKey = 'current_user';

  final Map<String, Map<String, dynamic>> _users = {
    'admin': {'password': 'admin123', 'role': 'admin'},
    'cashier': {'password': '1234', 'role': 'cashier'},
  };

  Future<String?> login(String username, String password) async {
    if (!_users.containsKey(username) ||
        _users[username]!['password'] != password) {
      return null;
    }

    final userRole = _users[username]!['role'];
    await _storage.write(key: _userKey, value: username);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, userRole);
    return userRole;
  }

  Future<void> logout() async {
    await _storage.delete(key: _userKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<String?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }
}
