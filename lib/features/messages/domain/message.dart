/// A message from a telecaller, as `MessageResource` sends it.
///
/// `is_read` is derived server-side from `read_at`, the only state stored —
/// the app shows the flag and never tries to keep its own (docs/api/v1-mr.md).
class Message {
  const Message({
    required this.id,
    required this.subject,
    required this.body,
    required this.isRead,
    this.sentAt,
    this.fromName,
    this.personName,
  });

  final int id;
  final String subject;
  final String body;
  final bool isRead;
  final DateTime? sentAt;
  final String? fromName;

  /// The person the telecaller was writing about, when they attached one.
  final String? personName;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: (json['id'] as num?)?.toInt() ?? 0,
        subject: json['subject'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isRead: json['is_read'] == true,
        sentAt: DateTime.tryParse(json['sent_at'] as String? ?? ''),
        fromName: (json['from'] as Map?)?['name'] as String?,
        personName: (json['person'] as Map?)?['name'] as String?,
      );
}
