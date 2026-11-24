import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../domain/assignee.dart';
import '../domain/client_type.dart';
import '../domain/person.dart';

class PersonsRepository {
  const PersonsRepository(this._api);

  final ApiClient _api;

  /// The reps' own assignments in their territory, active only — the scoping
  /// is the server's, so there is no region parameter to send. This is the
  /// visit form's picker.
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

  /// My Clients: the clients this rep is the assigned MR of.
  ///
  /// `mine=1` swaps the server's clamp from territory to ownership, which is
  /// what makes a client a telecaller added and handed to this rep show up
  /// here even when it sits in a region the rep does not cover.
  Future<Paginated<Person>> mine({int page = 1, String? search}) async {
    final envelope = await _api.get(
      AppConstants.persons,
      query: {
        'mine': 1,
        'page': page,
        'per_page': AppConstants.pageSize,
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );

    return Paginated.from(envelope, Person.fromJson);
  }

  /// Adds a client. This rep becomes its MR and the chosen telecaller its
  /// telecaller.
  ///
  /// `assigned_mr_id` is never sent — the server takes it from the token, the
  /// same rule as `mr_id` on a visit — and neither is the region, which the
  /// server reads off this rep's territory. Sending either is a 422, so this
  /// method is the contract as much as the convenience.
  Future<Person> create({
    required String name,
    required String type,
    required String mobile,
    required int telecallerId,
    String? email,
    String? city,
    String? address,
    String? specialization,
  }) async {
    final envelope = await _api.post(
      AppConstants.persons,
      body: {
        'name': name.trim(),
        'type': type,
        'mobile': mobile.trim(),
        'assigned_telecaller_id': telecallerId,
        if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
        if ((city ?? '').trim().isNotEmpty) 'city': city!.trim(),
        if ((address ?? '').trim().isNotEmpty) 'address': address!.trim(),
        if ((specialization ?? '').trim().isNotEmpty)
          'specialization': specialization!.trim(),
      },
    );

    return Person.fromJson(envelope.dataMap);
  }

  /// The kinds of client the form may offer, straight from the panel's
  /// master. A plain array, not a page.
  Future<List<ClientType>> clientTypes() async {
    final envelope = await _api.get(AppConstants.clientTypes);

    return envelope.dataList.map(ClientType.fromJson).toList();
  }

  /// Every active telecaller, for the Add Client dropdown. Also a plain
  /// array — it is a picker, not a list to page through.
  Future<List<Assignee>> telecallers() async {
    final envelope = await _api.get(AppConstants.telecallers);

    return envelope.dataList.map(Assignee.fromJson).toList();
  }
}
