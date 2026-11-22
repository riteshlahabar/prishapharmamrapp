@Tags(['screenshot'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mr_app/core/api/api_envelope.dart';
import 'package:mr_app/core/app_theme.dart';
import 'package:mr_app/features/attendance/domain/attendance.dart';
import 'package:mr_app/features/attendance/state/attendance_controller.dart';
import 'package:mr_app/features/attendance/ui/home_screen.dart';
import 'package:mr_app/features/auth/domain/app_user.dart';
import 'package:mr_app/features/auth/state/auth_controller.dart';
import 'package:mr_app/features/auth/ui/login_screen.dart';
import 'package:mr_app/features/messages/domain/message.dart';
import 'package:mr_app/features/messages/state/messages_controller.dart';
import 'package:mr_app/features/messages/ui/inbox_screen.dart';
import 'package:mr_app/features/visits/domain/visit.dart';
import 'package:mr_app/features/visits/domain/visit_purpose.dart';
import 'package:mr_app/features/visits/state/visits_controller.dart';
import 'package:mr_app/features/visits/ui/visits_screen.dart';

/// Renders each screen to a PNG so the design can actually be looked at.
/// Not golden assertions — these are for human review of the ProKit styling.
/// Run with: flutter test test/screenshot_test.dart
class _Att extends AttendanceController {
  _Att(this.v);
  final Attendance v;
  @override
  Future<Attendance> build() async => v;
}

class _Auth extends AuthController {
  @override
  AppUser? build() => const AppUser(
        id: 1,
        name: 'Asha Patel',
        email: 'asha.patel@prishapharma.in',
        role: 'mr',
        mobile: '98200 11223',
        regions: [Region(id: 1, name: 'Pune West', code: 'PW')],
      );
}

class _Visits extends VisitsController {
  @override
  Future<Paginated<Visit>> build() async => Paginated(
        items: [
          Visit(
            id: 3,
            purpose: VisitPurpose.productDetailing,
            purposeLabel: 'Product detailing',
            personName: 'Dr Meera Joshi',
            visitDate: DateTime(2026, 11, 22),
            inTime: '10:15',
            outTime: '10:45',
            latitude: 18.52,
            longitude: 73.85,
            notes: 'Discussed the new cardio line. Asked for samples.',
          ),
          Visit(
            id: 2,
            purpose: VisitPurpose.sampleDrop,
            purposeLabel: 'Sample drop',
            personName: 'Sunrise Medical Store',
            visitDate: DateTime(2026, 11, 21),
            inTime: '16:00',
            outTime: '16:10',
          ),
        ],
        page: 1,
        lastPage: 1,
        total: 2,
        hasMore: false,
      );
}

class _Inbox extends InboxController {
  @override
  Future<Paginated<Message>> build() async => Paginated(
        items: [
          Message(
            id: 18,
            subject: 'Dr Phase3 wants a sample',
            body: 'Spoke to the doctor this morning. They asked for a sample '
                'pack of the new line on your next round.',
            isRead: false,
            fromName: 'Ravi (telecaller)',
            personName: 'Dr Meera Joshi',
            sentAt: DateTime(2026, 11, 22, 9, 12),
          ),
          Message(
            id: 17,
            subject: 'Pharmacy asked about delivery',
            body: 'Sunrise Medical want to know the next delivery date.',
            isRead: true,
            fromName: 'Ravi (telecaller)',
            sentAt: DateTime(2026, 11, 20, 15, 40),
          ),
        ],
        page: 1,
        lastPage: 1,
        total: 2,
        hasMore: false,
      );
}

class _Unread extends UnreadCount {
  @override
  Future<int> build() async => 1;
}

/// Loads real fonts so the PNGs show text instead of the test font's boxes.
///
/// `flutter test` ships a placeholder font and google_fonts cannot fetch
/// anything offline, so without this the goldens prove layout but are
/// useless for looking at the design. Roboto and the Material icon font both
/// come with the SDK.
Future<void> loadFonts() async {
  // flutter_tester lives at <cache>/artifacts/engine/<platform>/, so three
  // levels up is the artifacts directory the fonts sit in.
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
  final dir = Directory('$artifacts/material_fonts');

  if (!dir.existsSync()) return;

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var found = false;

    for (final name in files) {
      final file = File('${dir.path}/$name');
      if (file.existsSync()) {
        loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
        found = true;
      }
    }

    if (found) await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// The app theme with Roboto substituted for Poppins.
///
/// google_fonts fetches Poppins at runtime and cannot do so offline in a
/// test, so it falls back to the placeholder font and every glyph renders
/// as a box. Swapping in the SDK's Roboto makes these PNGs readable. Colour,
/// spacing and layout are the app's own; only the typeface differs.
ThemeData get reviewTheme {
  final base = AppTheme.light;

  const label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    // The button themes carry their own Poppins TextStyle, so replacing the
    // text theme alone would still leave every button label as boxes.
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        textStyle: WidgetStateProperty.all(label),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        textStyle: WidgetStateProperty.all(label),
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'Roboto', fontSize: 12),
      ),
    ),
  );
}

/// Pumps a ready-made widget tree and writes a PNG of it.
///
/// Takes the whole tree rather than a list of overrides because Riverpod 3
/// does not export the `Override` type, so a helper cannot name it.
Future<void> shoot(WidgetTester tester, String name, Widget tree) async {
  // A typical mid-range Android handset, which is what reps carry.
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await loadFonts();
  await tester.pumpWidget(tree);
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('golden/$name.png'),
  );
}

/// The common scope: a signed-in rep and one unread message.
Widget scoped(Widget screen, {List<Object?> extra = const []}) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        unreadCountProvider.overrideWith(_Unread.new),
      ],
      child: MaterialApp(theme: reviewTheme, home: screen),
    );

void main() {
  testWidgets('login', (t) async {
    await shoot(
      t,
      'login',
      ProviderScope(
        child: MaterialApp(theme: reviewTheme, home: const LoginScreen()),
      ),
    );
  });

  testWidgets('home fresh day', (t) async {
    await shoot(
      t,
      'home_fresh',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          unreadCountProvider.overrideWith(_Unread.new),
          attendanceControllerProvider.overrideWith(
            () => _Att(const Attendance(
                canCheckIn: true, canCheckOut: false, status: 'Absent')),
          ),
        ],
        child: MaterialApp(theme: reviewTheme, home: const HomeScreen()),
      ),
    );
  });

  testWidgets('home on duty', (t) async {
    await shoot(
      t,
      'home_on_duty',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          unreadCountProvider.overrideWith(_Unread.new),
          attendanceControllerProvider.overrideWith(
            () => _Att(Attendance(
              id: 9,
              canCheckIn: false,
              canCheckOut: true,
              status: 'On duty',
              checkInAt: DateTime(2026, 11, 22, 9, 12),
              workedMinutes: 215,
            )),
          ),
        ],
        child: MaterialApp(theme: reviewTheme, home: const HomeScreen()),
      ),
    );
  });

  testWidgets('visits', (t) async {
    await shoot(
      t,
      'visits',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          unreadCountProvider.overrideWith(_Unread.new),
          visitsControllerProvider.overrideWith(_Visits.new),
        ],
        child: MaterialApp(theme: reviewTheme, home: const VisitsScreen()),
      ),
    );
  });

  testWidgets('inbox', (t) async {
    await shoot(
      t,
      'inbox',
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          unreadCountProvider.overrideWith(_Unread.new),
          inboxControllerProvider.overrideWith(_Inbox.new),
        ],
        child: MaterialApp(theme: reviewTheme, home: const InboxScreen()),
      ),
    );
  });
}
