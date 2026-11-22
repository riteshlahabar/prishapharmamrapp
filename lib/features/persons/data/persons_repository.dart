import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../domain/person.dart';

class PersonsRepository {
  const PersonsRepository(this._api);

  final ApiClient _api;

  /// The reps' own assignments, active only — the scoping is the server's,
  /// so there is no region parameter to send.
  Future<Paginated<Person>> list({int page = 1, String? search}) async {
    final envelope = await _api.get(
      AppConstants.persons,
      query: {
        'page': page,
        'per_page': AppConstants.pageSize,
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );

    return Paginated.from(envelope, Person.fromJson);
  }
}
