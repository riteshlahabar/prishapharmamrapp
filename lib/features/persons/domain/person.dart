/// A doctor, hospital or medical store, as `PersonResource` sends them.
///
/// The list is scoped server-side to the reps' own assignments, so the app
/// never sends a filter it could tamper with (docs/api/v1-mr.md).
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    this.mobile,
    this.city,
    this.specialization,
    this.regionName,
  });

  final int id;
  final String name;
  final String type;
  final String typeLabel;
  final String? mobile;
  final String? city;
  final String? specialization;
  final String? regionName;

  /// The line under the name in a list row: whatever of these exists.
  String get subtitle => [
        typeLabel,
        if ((specialization ?? '').isNotEmpty) specialization,
        if ((city ?? '').isNotEmpty) city,
      ].join(' · ');

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        typeLabel: json['type_label'] as String? ?? '',
        mobile: json['mobile'] as String?,
        city: json['city'] as String?,
        specialization: json['specialization'] as String?,
        regionName: (json['region'] as Map?)?['name'] as String?,
      );
}
