import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../domain/message.dart';

class MessagesRepository {
  const MessagesRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Message>> inbox({int page = 1, bool unreadOnly = false}) async {
    final envelope = await _api.get(
      AppConstants.messages,
      query: {
        'page': page,
        'per_page': AppConstants.pageSize,
        if (unreadOnly) 'unread': 1,
      },
    );

    return Paginated.from(envelope, Message.fromJson);
  }

  /// One indexed COUNT server-side, which is what makes polling it cheap —
  /// there is no Firebase in this product.
  Future<int> unreadCount() async {
    final envelope = await _api.get(AppConstants.unreadCount);

    return (envelope.dataMap['unread'] as num?)?.toInt() ?? 0;
  }

  /// Idempotent server-side, so a retry on a flaky connection is not an
  /// error. Someone else's message answers 404, never 403.
  Future<Message> markRead(int id) async {
    final envelope = await _api.post(AppConstants.markRead(id));

    return Message.fromJson(envelope.dataMap);
  }

  /// Returns how many actually changed.
  Future<int> markAllRead() async {
    final envelope = await _api.post(AppConstants.readAll);

    return (envelope.dataMap['marked'] as num?)?.toInt() ?? 0;
  }
}
