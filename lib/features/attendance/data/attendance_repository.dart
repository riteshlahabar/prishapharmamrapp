import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../../../core/location/location_service.dart';
import '../domain/attendance.dart';

class AttendanceRepository {
  const AttendanceRepository(this._api);

  final ApiClient _api;

  /// Always answers, even on a day with no row yet, so the home screen can
  /// render its buttons without guessing.
  Future<Attendance> today() async {
    final envelope = await _api.get(AppConstants.attendanceToday);

    return Attendance.fromJson(envelope.dataMap);
  }

  Future<Attendance> checkIn(GeoFix? fix) => _punch(AppConstants.checkIn, fix);

  Future<Attendance> checkOut(GeoFix? fix) =>
      _punch(AppConstants.checkOut, fix);

  Future<Paginated<Attendance>> history({int page = 1}) async {
    final envelope = await _api.get(
      AppConstants.attendanceHistory,
      query: {'page': page, 'per_page': AppConstants.pageSize},
    );

    return Paginated.from(envelope, Attendance.fromJson);
  }

  /// The body carries coordinates and nothing else — no timestamp. The
  /// server stamps the row, so a wound-back device clock cannot forge a
  /// shift. Both coordinates travel together or neither does, which is what
  /// the server validates.
  Future<Attendance> _punch(String path, GeoFix? fix) async {
    final envelope = await _api.post(
      path,
      body: fix == null
          ? const <String, dynamic>{}
          : {'latitude': fix.latitude, 'longitude': fix.longitude},
    );

    return Attendance.fromJson(envelope.dataMap);
  }
}
