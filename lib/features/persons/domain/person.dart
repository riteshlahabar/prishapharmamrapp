/// A doctor, hospital or medical store, as `PersonResource` sends them.
///
/// Two lists are built from this, and they ask different questions. The visit
/// form's picker uses the territory-scoped list; My Clients uses
/// `?mine=1` — the clients this rep is the assigned MR of, wherever they sit.
/// Both are scoped server-side, so the app never sends a filter it could
/// tamper with (docs/api/v1-mr.md).
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
    this.telecallerName,
  });

  final int id;
  final String name;
  final String type;
  final String typeLabel;
  final String? mobile;
  final String? city;
  final String? specialization;
  final String? regionName;

  /// The telecaller on the other side of this client — whoever added it.
  /// Null on a client an admin left one-sided; a client added from either app
  /// always has both.
  final String? telecallerName;

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
    telecallerName: (json['assigned_telecaller'] as Map?)?['name'] as String?,
  );
}
