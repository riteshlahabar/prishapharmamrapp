import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../domain/attendance.dart';

/// Today's punch state, and the two actions that change it.
class AttendanceController extends AsyncNotifier<Attendance> {
  @override
  Future<Attendance> build() =>
      ref.watch(attendanceRepositoryProvider).today();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(attendanceRepositoryProvider).today(),
    );
  }

  Future<void> checkIn() => _punch(checkingIn: true);

  Future<void> checkOut() => _punch(checkingIn: false);

  /// Reads the GPS, then posts. A location problem is thrown on to the
  /// screen rather than swallowed: a punch with no coordinates is not what
  /// the business asked for, so the rep is told what to fix.
  Future<void> _punch({required bool checkingIn}) async {
    final fix = await ref.read(locationServiceProvider).current();
    final repository = ref.read(attendanceRepositoryProvider);

    final updated = checkingIn
        ? await repository.checkIn(fix)
        : await repository.checkOut(fix);

    state = AsyncValue.data(updated);
  }
}

final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, Attendance>(
  AttendanceController.new,
);
