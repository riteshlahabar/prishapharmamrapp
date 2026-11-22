import 'visit_purpose.dart';

/// A filed visit, as `VisitResource` sends it.
class Visit {
  const Visit({
    required this.id,
    required this.purposeLabel,
    this.visitDate,
    this.purpose,
    this.inTime,
    this.outTime,
    this.durationMinutes,
    this.notes,
    this.personName,
    this.personTypeLabel,
    this.latitude,
    this.longitude,
    this.recordedAt,
  });

  final int id;
  final DateTime? visitDate;
  final VisitPurpose? purpose;
  final String purposeLabel;
  final String? inTime;
  final String? outTime;
  final int? durationMinutes;
  final String? notes;
  final String? personName;
  final String? personTypeLabel;
  final double? latitude;
  final double? longitude;

  /// When the server received it, which is not when the visit happened —
  /// a late entry is visible as one.
  final DateTime? recordedAt;

  bool get isGeotagged => latitude != null && longitude != null;

  String get timeLabel {
    if (inTime == null && outTime == null) return '—';
    if (outTime == null) return 'from $inTime';
    if (inTime == null) return 'until $outTime';

    return '$inTime – $outTime';
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    final person = (json['person'] as Map?)?.cast<String, dynamic>();

    return Visit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      visitDate: DateTime.tryParse(json['visit_date'] as String? ?? ''),
      purpose: VisitPurpose.fromValue(json['purpose'] as String?),
      purposeLabel: json['purpose_label'] as String? ?? '',
      inTime: json['in_time'] as String?,
      outTime: json['out_time'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      personName: person?['name'] as String?,
      personTypeLabel: person?['type'] as String?,
      // decimal(10,7) arrives as a string, so parse rather than cast.
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? ''),
    );
  }

  static double? _toDouble(dynamic value) => switch (value) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
}
