import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'api_service.dart';

/// Manages authentication state using SharedPreferences.
/// Provides login/logout, user info access, and ties into [ApiService].
class AuthService {
  final ApiService _api = ApiService();
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _api.setupAuthInterceptor();
      _initialized = true;
    }
  }

  // ─── Check authentication ─────────────────────────────────────
  Future<bool> isAuthenticated() async {
    await _ensureInitialized();
    return _prefs.getString(AppConstants.tokenKey) != null;
  }

  // ─── Login ────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    await _ensureInitialized();
    try {
      final response = await _api.login(email: email, password: password);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        await _prefs.setString(AppConstants.tokenKey, data['access_token'] ?? '');
        await _prefs.setString(AppConstants.userIdKey, data['user']['id'].toString());
        await _prefs.setString(AppConstants.userNameKey, data['user']['name'] ?? '');
        await _prefs.setString(AppConstants.userEmailKey, data['user']['email'] ?? '');
        await _prefs.setString(AppConstants.userRoleKey, data['user']['role'] ?? '');
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────
  Future<void> logout() async {
    await _ensureInitialized();
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.userIdKey);
    await _prefs.remove(AppConstants.userNameKey);
    await _prefs.remove(AppConstants.userEmailKey);
    await _prefs.remove(AppConstants.userRoleKey);
  }

  // ─── User getters ─────────────────────────────────────────────
  Future<String?> getToken() async {
    await _ensureInitialized();
    return _prefs.getString(AppConstants.tokenKey);
  }

  Future<String?> getUserId() async {
    await _ensureInitialized();
    return _prefs.getString(AppConstants.userIdKey);
  }

  Future<String?> getUserName() async {
    await _ensureInitialized();
    return _prefs.getString(AppConstants.userNameKey);
  }

  Future<String?> getUserEmail() async {
    await _ensureInitialized();
    return _prefs.getString(AppConstants.userEmailKey);
  }

  Future<String?> getUserRole() async {
    await _ensureInitialized();
    return _prefs.getString(AppConstants.userRoleKey);
  }
}
