import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(attendanceControllerProvider.notifier).reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Signed in',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          user?.regionLabel ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('EEE, d MMM').format(DateTime.now()),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              today.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorPanel(
                  error: error,
                  onRetry: () =>
                      ref.read(attendanceControllerProvider.notifier).reload(),
                ),
                data: (attendance) => _PresenceCard(
                  attendance: attendance,
                  busy: _punching,
                  onCheckIn: () => _punch(checkingIn: true),
                  onCheckOut: () => _punch(checkingIn: false),
                ),
              ),
            ],
          ),
        ),
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
    final time = DateFormat('h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: attendance.isOnDuty
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.textSecondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendance.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: attendance.isOnDuty
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Worked ${attendance.workedLabel}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Stamp(
                    label: 'Check in',
                    value: attendance.checkInAt == null
                        ? '—'
                        : time.format(attendance.checkInAt!.toLocal()),
                    icon: Icons.login,
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFFEDEFF5)),
                Expanded(
                  child: _Stamp(
                    label: 'Check out',
                    value: attendance.checkOutAt == null
                        ? '—'
                        : time.format(attendance.checkOutAt!.toLocal()),
                    icon: Icons.logout,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (attendance.canCheckIn)
              FilledButton.icon(
                onPressed: busy ? null : onCheckIn,
                icon: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.my_location),
                label: Text(busy ? 'Getting location…' : 'Check out'),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: AppTheme.success),
                    SizedBox(width: 8),
                    Expanded(child: Text("That's your day recorded.")),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Your location is recorded with each punch.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
