import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../domain/person.dart';

/// The rep's assigned persons, for the visit form's picker.
///
/// Keyed by the search box so each query is its own cached request; passing
/// an empty string gives the first page unfiltered.
final personsSearchProvider =
    FutureProvider.family<List<Person>, String>((ref, query) async {
  final page = await ref.watch(personsRepositoryProvider).list(search: query);

  return page.items;
});
