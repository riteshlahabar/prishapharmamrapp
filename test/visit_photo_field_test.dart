import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mr_app/core/app_theme.dart';
import 'package:mr_app/features/visits/domain/visit_photo.dart';
import 'package:mr_app/features/visits/ui/visit_photo_field.dart';

/// The shopfront photo field on the visit form.
///
/// The camera itself cannot be driven in a widget test — it is the platform's
/// own app — so what is checked here is everything around it: the field is
/// optional, it never blocks a visit, and a server complaint about `photo`
/// lands on the field rather than only in a snackbar.
void main() {
  Future<void> pump(WidgetTester tester, {String? error}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: VisitPhotoField(error: error, onChanged: (_) {}),
          ),
        ),
      ),
    );
  }

  testWidgets('offers the camera first and the gallery as a fallback', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Shop / hospital photo'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('says it is optional, so nobody waits on a camera', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.text('Optional — a picture of the place you visited'),
      findsOneWidget,
    );
    // Nothing to remove until something is attached.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets("shows the server's complaint about the photo on the field", (
    tester,
  ) async {
    await pump(tester, error: 'That photo is too large — 8 MB is the limit.');

    expect(
      find.text('That photo is too large — 8 MB is the limit.'),
      findsOneWidget,
    );
  });

  test('the size hint reads in KB below a megabyte and MB above it', () {
    VisitPhoto of(int bytes) => VisitPhoto(
      bytes: Uint8List(bytes),
      filename: 'shopfront.jpg',
      takenAt: DateTime(2026, 11, 24, 10, 55),
    );

    expect(of(400 * 1024).sizeLabel, '400 KB');
    expect(of(2 * 1024 * 1024).sizeLabel, '2.0 MB');
  });
}
