import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/brand.dart';
import '../../auth/state/auth_controller.dart';
import '../domain/attendance.dart';
import '../state/attendance_controller.dart';

/// The rep's day: who they are, whether they are on duty, and the one
/// button that is valid right now.
///
/// Which button that is comes from the server (`can_check_in` /
/// `can_check_out`), never from comparing timestamps here — the day's
/// sequence is the server's rule and a device clock cannot be trusted.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _punching = false;

  Future<void> _punch({required bool checkingIn}) async {
    setState(() => _punching = true);

    try {
      final controller = ref.read(attendanceControllerProvider.notifier);
      checkingIn ? await controller.checkIn() : await controller.checkOut();

      if (mounted) {
        showNotice(context, checkingIn ? 'Checked in.' : 'Checked out.');
      }
    } on Object catch (error) {
      if (mounted) showNotice(context, describeError(error), isError: true);
      // The server may have moved the day on even when this failed (a 409
      // means it is already where we tried to put it), so re-read rather
      // than leave the buttons showing a state that no longer holds.
      await ref.read(attendanceControllerProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => _punching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final today = ref.watch(attendanceControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(attendanceControllerProvider.notifier).reload(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            BrandHeader(
              title: 'Hello, ${user?.firstName ?? 'there'}',
              subtitle: user?.regionLabel ?? 'Prisha Pharma field team',
              trailing: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.tint(AppTheme.teal)),
                ),
                alignment: Alignment.center,
                child: Text(
                  user?.initials ?? '?',
                  style: const TextStyle(
                    color: AppTheme.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today, size: 15, color: AppTheme.teal),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, d MMMM').format(ref.watch(todayProvider)),
                    style: const TextStyle(
                      color: AppTheme.tealDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: today.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorPanel(
                  error: error,
                  onRetry: () =>
                      ref.read(attendanceControllerProvider.notifier).reload(),
                ),
                data: (attendance) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DayStats(attendance: attendance),
                    const SizedBox(height: 14),
                    _PresenceCard(
                      attendance: attendance,
                      busy: _punching,
                      onCheckIn: () => _punch(checkingIn: true),
                      onCheckOut: () => _punch(checkingIn: false),
                    ),
                    const SizedBox(height: 14),
                    const _QuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day in three figures: in, out, and how long that was. The labels are
/// one word because three cards across a handset leave room for one; each
/// keeps its own hue wherever it appears, so the rep learns the colours
/// rather than re-reading the words.
class _DayStats extends StatelessWidget {
  const _DayStats({required this.attendance});

  final Attendance attendance;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a');

    String stamp(DateTime? at) => at == null ? '—' : time.format(at.toLocal());

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'In',
            value: stamp(attendance.checkInAt),
            icon: Icons.login,
            colour: AppTheme.tileTeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            label: 'Out',
            value: stamp(attendance.checkOutAt),
            icon: Icons.logout,
            colour: AppTheme.tileBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            label: 'Worked',
            value: attendance.workedLabel,
            icon: Icons.timelapse,
            colour: AppTheme.tileGreen,
          ),
        ),
      ],
    );
  }
}

/// The two things a rep does after punching in. The tabs reach both, but
/// from here they are one tap rather than two.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const IconPad(
              icon: Icons.add_location_alt_outlined,
              colour: AppTheme.tileGreen,
              size: 38,
            ),
            title: const Text('File a visit'),
            subtitle: const Text('Geo-stamped where you are now'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/visits/new'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const IconPad(
              icon: Icons.mark_email_unread_outlined,
              colour: AppTheme.tileBlue,
              size: 38,
            ),
            title: const Text('Messages'),
            subtitle: const Text('Notes from the telecaller team'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/messages'),
          ),
        ],
      ),
    );
  }
}

class _PresenceCard extends StatelessWidget {
  const _PresenceCard({
    required this.attendance,
    required this.busy,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final Attendance attendance;
  final bool busy;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconPad(
                  icon: attendance.isOnDuty
                      ? Icons.directions_walk
                      : Icons.event_available,
                  colour: attendance.isOnDuty
                      ? AppTheme.success
                      : AppTheme.tileTeal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text(
                        'Your location is recorded with each punch.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: attendance.status,
                  colour: attendance.isOnDuty
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (attendance.canCheckIn)
              FilledButton.icon(
                onPressed: busy ? null : onCheckIn,
                icon: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(busy ? 'Getting location…' : 'Check in'),
              )
            else if (attendance.canCheckOut)
              FilledButton.icon(
                onPressed: busy ? null : onCheckOut,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                icon: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(busy ? 'Getting location…' : 'Check out'),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.tint(AppTheme.success),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppTheme.success,
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Text("That's your day recorded.")),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
