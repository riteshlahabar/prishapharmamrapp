import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../domain/visit.dart';
import '../state/visits_controller.dart';

class VisitsScreen extends ConsumerWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(visitsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My visits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/visits/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add visit'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visitsControllerProvider.notifier).reload(),
        child: visits.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              ErrorPanel(
                error: error,
                onRetry: () =>
                    ref.read(visitsControllerProvider.notifier).reload(),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                  const EmptyPanel(
                    icon: Icons.map_outlined,
                    title: 'No visits yet',
                    message: 'Visits you file will appear here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _VisitTile(visit: page.items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.personName ?? 'Unknown person',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (visit.isGeotagged)
                  const Icon(Icons.place, size: 16, color: AppTheme.success)
                else
                  const Icon(Icons.location_off_outlined,
                      size: 16, color: AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              visit.purposeLabel,
              style: const TextStyle(color: AppTheme.primary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            // A Wrap, not a Row: a long date beside a full in–out range
            // overflows a narrow handset, and these two facts are better
            // stacked than clipped.
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Fact(
                  icon: Icons.event,
                  text: visit.visitDate == null
                      ? '—'
                      : DateFormat('d MMM y').format(visit.visitDate!),
                ),
                _Fact(icon: Icons.schedule, text: visit.timeLabel),
              ],
            ),
            if ((visit.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                visit.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
