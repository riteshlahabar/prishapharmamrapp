import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../domain/message.dart';
import '../state/messages_controller.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxControllerProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                final marked = await ref
                    .read(inboxControllerProvider.notifier)
                    .markAllRead();

                if (context.mounted) {
                  showNotice(context, 'Marked $marked as read.');
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inboxControllerProvider.notifier).reload(),
        child: inbox.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              ErrorPanel(
                error: error,
                onRetry: () =>
                    ref.read(inboxControllerProvider.notifier).reload(),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                  const EmptyPanel(
                    icon: Icons.mark_email_read_outlined,
                    title: 'No messages',
                    message: 'Notes from the telecaller team land here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _MessageTile(
                message: page.items[index],
                onOpen: () => _open(context, ref, page.items[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Opening a message is what marks it read — the server is idempotent
  /// about it, so re-opening one costs nothing and a failed call is not
  /// worth interrupting the read for.
  Future<void> _open(BuildContext context, WidgetRef ref, Message message) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _MessageSheet(message: message),
    );

    if (!message.isRead) {
      try {
        await ref.read(inboxControllerProvider.notifier).markRead(message.id);
      } on Object {
        // Left unread; the next open or pull-to-refresh will try again.
      }
    }
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.onOpen});

  final Message message;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: message.isRead
                      ? Colors.transparent
                      : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: message.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              if (message.fromName != null) message.fromName!,
                              if (message.personName != null)
                                're: ${message.personName}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ),
                        Text(
                          message.sentAt == null
                              ? ''
                              : DateFormat('d MMM, h:mm a')
                                  .format(message.sentAt!.toLocal()),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageSheet extends StatelessWidget {
  const _MessageSheet({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.subject,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            [
              if (message.fromName != null) 'From ${message.fromName}',
              if (message.personName != null) 'about ${message.personName}',
              if (message.sentAt != null)
                DateFormat('d MMM y, h:mm a').format(message.sentAt!.toLocal()),
            ].join(' · '),
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const Divider(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: SingleChildScrollView(child: Text(message.body)),
          ),
        ],
      ),
    );
  }
}
