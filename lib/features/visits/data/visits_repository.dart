import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../../../core/location/location_service.dart';
import '../domain/visit.dart';
import '../domain/visit_purpose.dart';

class VisitsRepository {
  const VisitsRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Visit>> history({int page = 1}) async {
    final envelope = await _api.get(
      AppConstants.visits,
      query: {'page': page, 'per_page': AppConstants.pageSize},
    );

    return Paginated.from(envelope, Visit.fromJson);
  }

  /// Files a visit. `mr_id` is never sent: the server takes it from the
  /// token, so a tampered build cannot file under another rep's name.
  Future<Visit> create({
    required int personId,
    required VisitPurpose purpose,
    String? inTime,
    String? outTime,
    String? notes,
    GeoFix? fix,
  }) async {
    final envelope = await _api.post(
      AppConstants.visits,
      body: {
        'person_id': personId,
        'purpose': purpose.value,
        'in_time': ?inTime,
        'out_time': ?outTime,
        if ((notes ?? '').isNotEmpty) 'notes': notes,
        // Both coordinates or neither; the timestamp says when the device
        // read them, which the server keeps beside its own receive time.
        if (fix != null) ...{
          'latitude': fix.latitude,
          'longitude': fix.longitude,
          'location_fetched_at': fix.takenAt.toUtc().toIso8601String(),
        },
      },
    );

    return Visit.fromJson(envelope.dataMap);
  }
}
