import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mr_app/core/app_theme.dart';
import 'package:mr_app/features/attendance/domain/attendance.dart';
import 'package:mr_app/features/attendance/state/attendance_controller.dart';
import 'package:mr_app/features/attendance/ui/home_screen.dart';
import 'package:mr_app/features/auth/domain/app_user.dart';
import 'package:mr_app/features/auth/state/auth_controller.dart';

/// Serves a fixed day, so the screen is tested rather than the network.
class _FakeAttendance extends AttendanceController {
  _FakeAttendance(this._value);

  final Attendance _value;

  @override
  Future<Attendance> build() async => _value;
}

class _FakeAuth extends AuthController {
  @override
  AppUser? build() => const AppUser(
        id: 1,
        name: 'Asha Patel',
        email: 'asha@example.test',
        role: 'mr',
        regions: [Region(id: 1, name: 'Pune West', code: 'PW')],
      );
}

Future<void> pumpHome(WidgetTester tester, Attendance attendance) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuth.new),
        attendanceControllerProvider
            .overrideWith(() => _FakeAttendance(attendance)),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const fresh = Attendance(
    canCheckIn: true,
    canCheckOut: false,
    status: 'Absent',
  );

  testWidgets('a fresh day offers check in and nothing else', (tester) async {
    await pumpHome(tester, fresh);

    expect(find.text('Asha Patel'), findsOneWidget);
    expect(find.text('Pune West'), findsOneWidget);
    expect(find.text('Check in'), findsWidgets);
    // The check-out button must not exist yet: the server said so, and the
    // screen does not second-guess it.
    expect(find.widgetWithText(FilledButton, 'Check out'), findsNothing);
  });

  testWidgets('on duty offers check out instead', (tester) async {
    await pumpHome(
      tester,
      Attendance(
        canCheckIn: false,
        canCheckOut: true,
        status: 'On duty',
        checkInAt: DateTime(2026, 11, 22, 9, 15),
        id: 4,
      ),
    );

    expect(find.text('On duty'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Check out'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Check in'), findsNothing);
  });

  testWidgets('a finished day offers no punch at all', (tester) async {
    await pumpHome(
      tester,
      Attendance(
        canCheckIn: false,
        canCheckOut: false,
        status: 'Completed',
        checkInAt: DateTime(2026, 11, 22, 9, 15),
        checkOutAt: DateTime(2026, 11, 22, 17, 40),
        workedMinutes: 505,
        id: 4,
      ),
    );

    expect(find.textContaining("That's your day recorded"), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    // 505 minutes reads as hours and minutes, not as a raw count.
    expect(find.text('Worked 8h 25m'), findsOneWidget);
  });
}
