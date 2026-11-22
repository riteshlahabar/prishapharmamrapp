import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_envelope.dart';
import '../../../core/state/providers.dart';
import '../domain/visit.dart';

/// This rep's own visit history. Scoped server-side to the token, so there
/// is nothing to filter by here.
class VisitsController extends AsyncNotifier<Paginated<Visit>> {
  @override
  Future<Paginated<Visit>> build() =>
      ref.watch(visitsRepositoryProvider).history();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(visitsRepositoryProvider).history(),
    );
  }
}

final visitsControllerProvider =
    AsyncNotifierProvider<VisitsController, Paginated<Visit>>(
  VisitsController.new,
);
