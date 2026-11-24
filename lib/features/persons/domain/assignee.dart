/// A telecaller this rep may hand a client to, as `AssigneeResource` sends
/// them.
///
/// Deliberately not the full user shape — a picker has no business carrying
/// email addresses or activity flags. [regionNames] is why the row is worth
/// more than a name: the list is every active telecaller rather than only
/// those covering this rep's territory, so the rep needs to see who works
/// where to choose sensibly.
class Assignee {
  const Assignee({
    required this.id,
    required this.name,
    this.mobile,
    this.regionNames = const [],
  });

  final int id;
  final String name;
  final String? mobile;

  /// Every region this person covers. An MR has one, a telecaller may have
  /// several — the server flattens both into this one shape.
  final List<String> regionNames;

  /// The line under the name in the dropdown: where they work, or a plain
  /// note that nobody has given them a territory yet.
  String get subtitle =>
      regionNames.isEmpty ? 'No region assigned' : regionNames.join(' · ');

  factory Assignee.fromJson(Map<String, dynamic> json) => Assignee(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    mobile: json['mobile'] as String?,
    regionNames:
        (json['regions'] as List?)
            ?.whereType<Map>()
            .map((region) => region['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        const [],
  );
}
