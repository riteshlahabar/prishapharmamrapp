import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../../../core/state/providers.dart';
import '../domain/message.dart';

/// The inbox badge.
///
/// No Firebase in this product: the app polls one indexed COUNT on a timer
/// and when the screen comes back to the foreground. Cheap by design, so the
/// interval can stay short (docs/api/v1-mr.md).
class UnreadCount extends AsyncNotifier<int> {
  Timer? _timer;

  @override
  Future<int> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(
      AppConstants.unreadPollInterval,
      (_) => refresh(),
    );
    ref.onDispose(() => _timer?.cancel());

    return ref.watch(messagesRepositoryProvider).unreadCount();
  }

  /// Silent on failure: a badge that cannot refresh should keep its last
  /// number, not replace the screen with an error.
  Future<void> refresh() async {
    try {
      final count = await ref.read(messagesRepositoryProvider).unreadCount();
      state = AsyncValue.data(count);
    } on Object {
      // Keep whatever the badge already shows.
    }
  }
}

final unreadCountProvider =
    AsyncNotifierProvider<UnreadCount, int>(UnreadCount.new);

/// The inbox list itself.
class InboxController extends AsyncNotifier<Paginated<Message>> {
  @override
  Future<Paginated<Message>> build() =>
      ref.watch(messagesRepositoryProvider).inbox();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(messagesRepositoryProvider).inbox(),
    );
  }

  Future<void> markRead(int id) async {
    await ref.read(messagesRepositoryProvider).markRead(id);
    await _afterChange();
  }

  Future<int> markAllRead() async {
    final marked = await ref.read(messagesRepositoryProvider).markAllRead();
    await _afterChange();

    return marked;
  }

  Future<void> _afterChange() async {
    // The badge is derived from the same rows, so refresh both together or
    // the count sits stale next to a list that has already changed.
    await Future.wait([
      reload(),
      ref.read(unreadCountProvider.notifier).refresh(),
    ]);
  }
}

final inboxControllerProvider =
    AsyncNotifierProvider<InboxController, Paginated<Message>>(
  InboxController.new,
);
