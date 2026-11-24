import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_envelope.dart';
import '../../../core/state/providers.dart';
import '../domain/assignee.dart';
import '../domain/client_type.dart';
import '../domain/person.dart';

/// The rep's assigned persons in their territory, for the visit form's
/// picker.
///
/// Keyed by the search box so each query is its own cached request; passing
/// an empty string gives the first page unfiltered.
final personsSearchProvider = FutureProvider.family<List<Person>, String>((
  ref,
  query,
) async {
  final page = await ref.watch(personsRepositoryProvider).list(search: query);

  return page.items;
});

/// What the rep is searching My Clients for. Empty means the whole list.
class MyClientsSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final myClientsSearchProvider = NotifierProvider<MyClientsSearch, String>(
  MyClientsSearch.new,
);

/// My Clients: the clients this rep is the assigned MR of, re-fetched
/// whenever the search changes.
///
/// A different question from [personsSearchProvider], which is the visit
/// form's territory-scoped picker — see `PersonsRepository.mine`.
final myClientsProvider = FutureProvider<Paginated<Person>>((ref) {
  final search = ref.watch(myClientsSearchProvider);

  return ref.watch(personsRepositoryProvider).mine(search: search);
});

/// The kinds of client the Add Client form may offer. Loaded from the
/// panel's master rather than hard-coded, and cached for the session: the
/// table is tiny and changes about never.
final clientTypesProvider = FutureProvider<List<ClientType>>(
  (ref) => ref.watch(personsRepositoryProvider).clientTypes(),
);

/// Every active telecaller, for the Add Client dropdown.
final telecallersProvider = FutureProvider<List<Assignee>>(
  (ref) => ref.watch(personsRepositoryProvider).telecallers(),
);

/// Everything a new client makes stale, in one place so neither the form nor
/// a future caller has to remember the list: My Clients gains a row, and the
/// visit form's picker can reach the client immediately.
void invalidateClientLists(WidgetRef ref) {
  ref.invalidate(myClientsProvider);
  ref.invalidate(personsSearchProvider);
}
