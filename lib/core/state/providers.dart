import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attendance/data/attendance_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/messages/data/messages_repository.dart';
import '../../features/persons/data/persons_repository.dart';
import '../../features/products/data/products_repository.dart';
import '../../features/visits/data/visits_repository.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../location/location_service.dart';

/// Filled in `main()` once SharedPreferences has opened, so nothing below
/// has to be async just to read a token.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// Today, for anything that prints a date. A provider rather than a bare
/// `DateTime.now()` so a golden test can hold the clock still — the home
/// header shows the date, and a golden taken against the real clock fails
/// the next morning.
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

/// Set when the server rejects a token for good — expired, account switched
/// off, role moved. The router watches this and drops to the login screen,
/// and the login screen shows the reason once.
class SessionEnded extends Notifier<String?> {
  @override
  String? build() => null;

  void reason(String message) => state = message;

  void clear() => state = null;
}

final sessionEndedProvider = NotifierProvider<SessionEnded, String?>(
  SessionEnded.new,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokens: ref.watch(tokenStoreProvider),
    onSignOut: (failure) async {
      await ref.read(tokenStoreProvider).clear();
      ref.read(sessionEndedProvider.notifier).reason(failure.message);
    },
  );
});

final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(apiClientProvider)),
);

final visitsRepositoryProvider = Provider<VisitsRepository>(
  (ref) => VisitsRepository(ref.watch(apiClientProvider)),
);

final personsRepositoryProvider = Provider<PersonsRepository>(
  (ref) => PersonsRepository(ref.watch(apiClientProvider)),
);

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(apiClientProvider)),
);

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(ref.watch(apiClientProvider)),
);
