import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/brand.dart';
import '../domain/person.dart';
import '../state/persons_controller.dart';

/// My Clients: every client this rep is the assigned MR of.
///
/// That includes the ones a telecaller added and handed over, which is the
/// point — the two apps share a client, and each sees it from its own side.
/// The scope is the server's (`?mine=1`), so there is nothing to filter here
/// but the search box.
class MyClientsScreen extends ConsumerWidget {
  const MyClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(myClientsProvider);
    final search = ref.watch(myClientsSearchProvider);

    return Scaffold(
      appBar: const BrandAppBar(
        title: 'My clients',
        subtitle: 'Doctors, hospitals and stores assigned to you',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add client'),
      ),
      body: Column(
        children: [
          _SearchBar(
            value: search,
            onChanged: ref.read(myClientsSearchProvider.notifier).set,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myClientsProvider),
              child: clients.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                    ErrorPanel(
                      error: error,
                      onRetry: () => ref.invalidate(myClientsProvider),
                    ),
                  ],
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.18,
                        ),
                        EmptyPanel(
                          icon: Icons.people_outline,
                          title: search.isEmpty
                              ? 'No clients yet'
                              : 'Nobody matches that',
                          message: search.isEmpty
                              ? 'Clients you add, and the ones a telecaller '
                                    'assigns to you, will appear here.'
                              : 'Try a different name, mobile or city.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: page.items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => index == page.items.length
                        ? _CountFooter(shown: page.items.length, total: page.total)
                        : _ClientTile(client: page.items[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        // On submit, not on every keystroke: each search is one request, and
        // the list reloads under the rep's thumb as they type otherwise.
        onSubmitted: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Search name, mobile or city',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear',
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});

  final Person client;

  /// A colour per kind, so a long list is scannable before it is read. The
  /// hue is chosen by meaning, never by position in the list.
  Color get _hue => switch (client.type) {
    'hospital' => AppTheme.tileBlue,
    'medical' => AppTheme.tileGreen,
    _ => AppTheme.tileTeal,
  };

  IconData get _icon => switch (client.type) {
    'hospital' => Icons.local_hospital_outlined,
    'medical' => Icons.storefront_outlined,
    _ => Icons.person_outline,
  };

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
                IconPad(icon: _icon, colour: _hue, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        client.subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(label: client.typeLabel, colour: _hue),
              ],
            ),
            const SizedBox(height: 10),
            // A Wrap, not a Row: a mobile number beside a telecaller's name
            // and a region overflows a narrow handset.
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if ((client.mobile ?? '').isNotEmpty)
                  _Fact(icon: Icons.phone_outlined, text: client.mobile!),
                if ((client.regionName ?? '').isNotEmpty)
                  _Fact(icon: Icons.map_outlined, text: client.regionName!),
                // The other side of the client: who to talk to about it.
                if ((client.telecallerName ?? '').isNotEmpty)
                  _Fact(
                    icon: Icons.headset_mic_outlined,
                    text: client.telecallerName!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// How much of the list is on screen.
///
/// The server pages at 20 and this screen shows the first page, like every
/// other list in the app — so when there is more, say so plainly and point
/// at the search box rather than leaving the rep to wonder.
class _CountFooter extends StatelessWidget {
  const _CountFooter({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= shown) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Showing $shown of $total. Search to narrow the list.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
