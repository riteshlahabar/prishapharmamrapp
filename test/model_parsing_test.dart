import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mr_app/core/api/api_envelope.dart';
import 'package:mr_app/features/attendance/domain/attendance.dart';
import 'package:mr_app/features/auth/domain/app_user.dart';
import 'package:mr_app/features/messages/domain/message.dart';
import 'package:mr_app/features/persons/domain/person.dart';
import 'package:mr_app/features/visits/domain/visit.dart';
import 'package:mr_app/features/visits/domain/visit_purpose.dart';

/// These fixtures are real responses captured from the Laravel API, not
/// hand-written guesses — so a server-side rename shows up here as a failing
/// test rather than as a blank field on a rep's phone.
ApiEnvelope fixture(String name) => ApiEnvelope.fromJson(
      jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
          as Map<String, dynamic>,
    );

void main() {
  test('login returns a token and the signed-in rep', () {
    final data = fixture('login').dataMap;

    expect(data['token_type'], 'Bearer');
    expect((data['token'] as String).isNotEmpty, isTrue);

    final user = AppUser.fromJson(
      (data['user'] as Map).cast<String, dynamic>(),
    );

    expect(user.role, 'mr');
    expect(user.name, isNotEmpty);
  });

  test('/auth/me carries the regions filled in Phase 6', () {
    final user = AppUser.fromJson(fixture('me').dataMap);

    expect(user.id, greaterThan(0));
    expect(user.role, 'mr');
    // This was `[]` from Phase 2 until Phase 6; an empty list here again
    // would mean the rep's territory never reaches the app.
    expect(user.regions, isNotEmpty);
    expect(user.regions.first.name, isNotEmpty);
    expect(user.regionLabel, isNot('No region assigned'));
  });

  test('a fresh day parses into usable button state', () {
    final today = Attendance.fromJson(fixture('today').dataMap);

    // The server answers even with no row, so the home screen never guesses.
    expect(today.id, isNull);
    expect(today.canCheckIn, isTrue);
    expect(today.canCheckOut, isFalse);
    expect(today.status, 'Absent');
    expect(today.isOnDuty, isFalse);
    expect(today.workedLabel, '—');
  });

  test('visits parse, including the purpose enum and the person', () {
    final page = Paginated.from(fixture('visits'), Visit.fromJson);

    expect(page.items, isNotEmpty);
    expect(page.total, greaterThan(0));

    final visit = page.items.first;
    expect(visit.id, greaterThan(0));
    expect(visit.personName, isNotEmpty);
    expect(visit.purpose, isNotNull);
    expect(visit.purposeLabel, isNotEmpty);
    // Every purpose the server can send must map to a known enum value, or
    // the form would offer something the API rejects.
    for (final item in page.items) {
      expect(item.purpose, isNotNull,
          reason: 'unmapped purpose on visit ${item.id}');
    }
  });

  test('every VisitPurpose round-trips through its wire value', () {
    for (final purpose in VisitPurpose.values) {
      expect(VisitPurpose.fromValue(purpose.value), purpose);
    }
    expect(VisitPurpose.fromValue('not_a_purpose'), isNull);
  });

  test('persons parse with the region the server scoped them to', () {
    final page = Paginated.from(fixture('persons'), Person.fromJson);

    expect(page.items, isNotEmpty);

    final person = page.items.first;
    expect(person.id, greaterThan(0));
    expect(person.name, isNotEmpty);
    expect(person.typeLabel, isNotEmpty);
    expect(person.regionName, isNotEmpty);
    expect(person.subtitle, contains(person.typeLabel));
  });

  test('messages parse, with read state derived server-side', () {
    final page = Paginated.from(fixture('messages'), Message.fromJson);

    expect(page.items, isNotEmpty);

    final message = page.items.first;
    expect(message.subject, isNotEmpty);
    expect(message.body, isNotEmpty);
    expect(message.isRead, isFalse);
    expect(message.sentAt, isNotNull);
    expect(message.fromName, isNotEmpty);
    // The telecaller attached the person they were ringing about.
    expect(message.personName, isNotEmpty);
  });

  test('unread count is a plain integer under data', () {
    expect(fixture('unread').dataMap['unread'], isA<int>());
  });
}
