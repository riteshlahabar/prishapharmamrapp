/// Today's presence, as `AttendanceResource` sends it.
///
/// The two flags are computed server-side on purpose: the day's sequence is
/// the server's rule, so a reinstall — or a phone whose clock is wrong —
/// cannot talk the buttons into a double check-in (docs/api/v1-mr.md).
class Attendance {
  const Attendance({
    required this.canCheckIn,
    required this.canCheckOut,
    required this.status,
    this.id,
    this.date,
    this.checkInAt,
    this.checkOutAt,
    this.workedMinutes,
  });

  final int? id;
  final DateTime? date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int? workedMinutes;
  final String status;
  final bool canCheckIn;
  final bool canCheckOut;

  bool get isOnDuty => checkInAt != null && checkOutAt == null;

  String get workedLabel {
    final minutes = workedMinutes;
    if (minutes == null || minutes <= 0) return '—';

    final hours = minutes ~/ 60;
    final rest = minutes % 60;

    return hours > 0 ? '${hours}h ${rest}m' : '${rest}m';
  }

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: (json['id'] as num?)?.toInt(),
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        checkInAt: DateTime.tryParse(json['check_in_at'] as String? ?? ''),
        checkOutAt: DateTime.tryParse(json['check_out_at'] as String? ?? ''),
        workedMinutes: (json['worked_minutes'] as num?)?.toInt(),
        status: json['status'] as String? ?? 'Absent',
        // Default to "nothing is possible" if the server ever omits these:
        // better a dead button than one that files a wrong punch.
        canCheckIn: json['can_check_in'] == true,
        canCheckOut: json['can_check_out'] == true,
      );
}
