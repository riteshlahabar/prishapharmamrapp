/// App-wide constants for Prisha Pharma MR.
class AppConstants {
  AppConstants._();

  // API base URL - update for production
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  static const String appName = 'Prisha Pharma MR';
  static const String authHeader = 'Authorization';
  static const String contentType = 'application/json';

  // SharedPreferences keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey = 'user_role';

  // API endpoints
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/auth/profile';
  static const String customersEndpoint = '/customers';
  static const String ordersEndpoint = '/orders';
  static const String productsEndpoint = '/products';
  static const String reportsEndpoint = '/reports';
  static const String visitsEndpoint = '/visits';

  // Timeouts in milliseconds
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // UI constants
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double cardBorderRadius = 12;
  static const double inputBorderRadius = 10;
}
