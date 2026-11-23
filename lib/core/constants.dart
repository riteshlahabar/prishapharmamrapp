/// Everything the app needs to find the backend, in one place.
///
/// The paths mirror `docs/api/v1-mr.md` in the CRM repo. That document is the
/// contract: a field named here exists there, and renaming one on either side
/// breaks a shipped build.
class AppConstants {
  AppConstants._();

  static const String appName = 'Prisha Pharma MR';

  /// `10.0.2.2` is the host machine as seen from the Android emulator.
  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=https://crm.example.com/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://prishapharmacrm.turnkeyinfotech.live/api/v1',
  );

  /// Sent on login so the server refuses a telecaller account here rather
  /// than leaving it to the client (docs/api/v1-auth.md).
  static const String appRole = 'mr';
  static const String deviceName = 'mr-app';

  // Storage keys.
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // Endpoints — /api/v1, never the unversioned legacy routes.
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String attendanceToday = '/attendance/today';
  static const String attendanceHistory = '/attendance/history';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';

  static const String visits = '/visits';
  static const String persons = '/persons';

  static const String messages = '/messages';
  static const String unreadCount = '/messages/unread-count';
  static const String readAll = '/messages/read-all';
  static String markRead(int id) => '/messages/$id/read';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Matches the server's default; it clamps anything over 100.
  static const int pageSize = 20;

  /// How often the inbox badge re-counts. There is no Firebase: the MR app
  /// polls one indexed COUNT, so this can be frequent without being costly.
  static const Duration unreadPollInterval = Duration(seconds: 60);
}
