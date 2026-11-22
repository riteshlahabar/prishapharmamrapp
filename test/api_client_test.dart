import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mr_app/core/api/api_client.dart';
import 'package:mr_app/core/api/api_failure.dart';
import 'package:mr_app/core/api/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Replies with a canned body and status, and records what it was sent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body, {this.headers = const {}});

  final int status;
  final String body;
  final Map<String, List<String>> headers;

  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;

    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String errorFixture(String name) =>
    File('test/fixtures/error_$name.json').readAsStringSync();

Future<ApiClient> _clientFor(
  _StubAdapter adapter, {
  String? token,
  void Function(ApiFailure)? onSignOut,
}) async {
  SharedPreferences.setMockInitialValues(
    token == null ? {} : {'auth_token': token},
  );

  final dio = Dio()..httpClientAdapter = adapter;

  return ApiClient(
    tokens: await TokenStore.open(),
    dio: dio,
    onSignOut: onSignOut,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a success envelope comes back as data', () async {
    final adapter = _StubAdapter(
      200,
      jsonEncode({
        'success': true,
        'message': 'Today loaded.',
        'data': {'status': 'On duty'},
      }),
    );

    final envelope = await (await _clientFor(adapter)).get('/attendance/today');

    expect(envelope.success, isTrue);
    expect(envelope.dataMap['status'], 'On duty');
  });

  test('the bearer token is attached when there is one', () async {
    final adapter = _StubAdapter(
      200,
      jsonEncode({'success': true, 'data': <String, dynamic>{}}),
    );

    await (await _clientFor(adapter, token: 'tok-123')).get('/auth/me');

    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer tok-123');
  });

  test('no Authorization header before sign-in', () async {
    final adapter = _StubAdapter(
      200,
      jsonEncode({'success': true, 'data': <String, dynamic>{}}),
    );

    await (await _clientFor(adapter)).post('/auth/login');

    expect(adapter.lastRequest?.headers.containsKey('Authorization'), isFalse);
  });

  test('a real 422 becomes a validation failure with field errors', () async {
    final adapter = _StubAdapter(422, errorFixture('422'));
    final client = await _clientFor(adapter, token: 't');

    final failure = await client.post('/visits').then<ApiFailure?>(
          (_) => null,
          onError: (Object e) => e as ApiFailure,
        );

    expect(failure, isNotNull);
    expect(failure!.reason, ApiReason.validation);
    expect(failure.status, 422);
    expect(failure.fieldError('person_id'),
        'The person id field is required.');
    expect(failure.fieldError('purpose'), 'The selected purpose is invalid.');
    // `reason` is metadata, not a field the form should show.
    expect(failure.fieldErrors.containsKey('reason'), isFalse);
    expect(failure.requiresSignOut, isFalse);
  });

  test('a real 409 keeps the attendance reason so the UI can explain', () async {
    final adapter = _StubAdapter(409, errorFixture('409'));
    final client = await _clientFor(adapter, token: 't');

    final failure = await client
        .post('/attendance/check-in')
        .then<ApiFailure?>((_) => null, onError: (Object e) => e as ApiFailure);

    expect(failure!.reason, ApiReason.alreadyCheckedIn);
    expect(failure.message, contains('already checked in'));
    expect(failure.requiresSignOut, isFalse);
  });

  test('a real 403 does not sign the rep out', () async {
    final adapter = _StubAdapter(403, errorFixture('403'));
    var signedOut = false;

    final client = await _clientFor(
      adapter,
      token: 't',
      onSignOut: (_) => signedOut = true,
    );

    final failure = await client
        .get('/call-logs')
        .then<ApiFailure?>((_) => null, onError: (Object e) => e as ApiFailure);

    expect(failure!.reason, ApiReason.forbidden);
    // Being refused one endpoint is not a reason to throw away the session.
    expect(signedOut, isFalse);
  });

  test('a real 401 does sign the rep out', () async {
    final adapter = _StubAdapter(401, errorFixture('401'));
    ApiFailure? captured;

    final client = await _clientFor(
      adapter,
      token: 't',
      onSignOut: (failure) => captured = failure,
    );

    await client
        .get('/visits')
        .then<void>((_) {}, onError: (Object _) {});

    expect(captured, isNotNull);
    expect(captured!.reason, ApiReason.unauthenticated);
  });

  test('account_inactive signs out — a token outliving its account', () async {
    final adapter = _StubAdapter(
      403,
      jsonEncode({
        'success': false,
        'message': 'This account is no longer active.',
        'errors': {'reason': 'account_inactive'},
      }),
    );
    ApiFailure? captured;

    final client = await _clientFor(
      adapter,
      token: 't',
      onSignOut: (failure) => captured = failure,
    );

    await client.get('/visits').then<void>((_) {}, onError: (Object _) {});

    expect(captured?.reason, ApiReason.accountInactive);
  });

  test('a 429 keeps Retry-After so the app can wait the stated time', () async {
    final adapter = _StubAdapter(
      429,
      jsonEncode({
        'success': false,
        'message': 'Too Many Attempts.',
        'errors': {'reason': 'throttled'},
      }),
      headers: {
        'retry-after': ['48'],
      },
    );

    final failure = await (await _clientFor(adapter))
        .post('/auth/login')
        .then<ApiFailure?>((_) => null, onError: (Object e) => e as ApiFailure);

    expect(failure!.reason, ApiReason.throttled);
    expect(failure.retryAfter, const Duration(seconds: 48));
  });

  test('an HTML error page is a readable failure, not a crash', () async {
    // What a wrong base URL or a proxy error page actually returns.
    final adapter = _StubAdapter(
      502,
      '<html><body>Bad Gateway</body></html>',
      headers: {
        'content-type': ['text/html'],
      },
    );

    final failure = await (await _clientFor(adapter))
        .get('/visits')
        .then<ApiFailure?>((_) => null, onError: (Object e) => e as ApiFailure);

    expect(failure!.reason, ApiReason.serverError);
    expect(failure.message, isNotEmpty);
  });

  test('a body that lies about being JSON is a server fault, not network',
      () async {
    // Dio throws while decoding. The rep reached the server, so telling them
    // to check their signal would send them chasing the wrong problem.
    final adapter = _StubAdapter(200, 'this is not json{{');

    final failure = await (await _clientFor(adapter))
        .get('/visits')
        .then<ApiFailure?>((_) => null, onError: (Object e) => e as ApiFailure);

    expect(failure!.reason, ApiReason.serverError);
    expect(failure.reason, isNot(ApiReason.network));
  });
}
