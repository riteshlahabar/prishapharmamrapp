import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/app_theme.dart';
import '../../../core/location/location_service.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../persons/domain/person.dart';
import '../../persons/state/persons_controller.dart';
import '../../products/domain/product.dart';
import '../../products/ui/product_lines_field.dart';
import '../domain/visit_photo.dart';
import '../domain/visit_purpose.dart';
import '../state/visits_controller.dart';
import 'visit_photo_field.dart';

/// Files one visit.
///
/// The person list is the rep's own assignments, fetched from the server —
/// there is no free-text name, because the server will only accept a
/// `person_id` that exists and is active.
class VisitFormScreen extends ConsumerStatefulWidget {
  const VisitFormScreen({super.key});

  @override
  ConsumerState<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends ConsumerState<VisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();

  Person? _person;
  VisitPurpose? _purpose;
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  GeoFix? _fix;
  VisitPhoto? _photo;
  List<ProductLineInput> _products = const [];

  bool _busy = false;
  bool _locating = false;
  String? _locationNote;

  /// Field errors the server sent back, keyed as it named them.
  Map<String, List<String>> _serverErrors = const {};

  @override
  void initState() {
    super.initState();
    // Start the fix early: by the time the form is filled in it is usually
    // ready, so saving does not sit waiting on the GPS.
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationNote = null;
    });

    try {
      final fix = await ref.read(locationServiceProvider).current();
      if (mounted) setState(() => _fix = fix);
    } on LocationException catch (problem) {
      if (mounted) setState(() => _locationNote = problem.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String? _format(TimeOfDay? time) => time == null
      ? null
      : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) return;
    setState(() => isIn ? _inTime = picked : _outTime = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_person == null || _purpose == null) {
      showNotice(context, 'Pick a person and a purpose.', isError: true);

      return;
    }

    setState(() {
      _busy = true;
      _serverErrors = const {};
    });

    try {
      await ref
          .read(visitsRepositoryProvider)
          .create(
            personId: _person!.id,
            purpose: _purpose!,
            inTime: _format(_inTime),
            outTime: _format(_outTime),
            notes: _notes.text,
            fix: _fix,
            photo: _photo,
            products: _products,
          );

      // The history behind this screen is now stale.
      await ref.read(visitsControllerProvider.notifier).reload();

      if (mounted) {
        showNotice(context, 'Visit recorded.');
        Navigator.of(context).pop();
      }
    } on ApiFailure catch (failure) {
      setState(() => _serverErrors = failure.fieldErrors);
      if (mounted) showNotice(context, failure.message, isError: true);
    } on Object catch (error) {
      if (mounted) showNotice(context, describeError(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final persons = ref.watch(personsSearchProvider(''));

    return Scaffold(
      appBar: AppBar(title: const Text('Add visit')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _locationBanner(),
              const SizedBox(height: 16),
              persons.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => ErrorPanel(
                  error: error,
                  onRetry: () => ref.invalidate(personsSearchProvider('')),
                ),
                data: (list) => DropdownButtonFormField<Person>(
                  initialValue: _person,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Person',
                    prefixIcon: const Icon(Icons.person_outline),
                    errorText: _serverErrors['person_id']?.first,
                  ),
                  items: [
                    for (final person in list)
                      DropdownMenuItem(
                        value: person,
                        child: Text(
                          person.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _person = value),
                  validator: (value) =>
                      value == null ? 'Pick who you visited' : null,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<VisitPurpose>(
                initialValue: _purpose,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Purpose',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  errorText: _serverErrors['purpose']?.first,
                ),
                items: [
                  for (final purpose in VisitPurpose.values)
                    DropdownMenuItem(
                      value: purpose,
                      child: Text(purpose.label),
                    ),
                ],
                onChanged: (value) => setState(() => _purpose = value),
                validator: (value) =>
                    value == null ? 'Pick why you went' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'In time',
                      value: _format(_inTime),
                      error: _serverErrors['in_time']?.first,
                      onTap: () => _pickTime(isIn: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Out time',
                      value: _format(_outTime),
                      // The server rejects an out before an in; show that
                      // here rather than only in a snackbar.
                      error: _serverErrors['out_time']?.first,
                      onTap: () => _pickTime(isIn: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  errorText: _serverErrors['notes']?.first,
                ),
              ),
              const SizedBox(height: 14),
              // Above the products: the photo belongs with where the rep is
              // standing, not with what they detailed.
              VisitPhotoField(
                error: _serverErrors['photo']?.first,
                onChanged: (photo) => _photo = photo,
              ),
              const SizedBox(height: 14),
              // Below the notes, as on the telecaller's call sheet: the
              // same field in both apps.
              ProductLinesField(
                subtitle: 'Optional — what you detailed, and how many boxes',
                onChanged: (lines) => _products = lines,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save visit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationBanner() {
    final (icon, colour, text) = switch ((_locating, _fix, _locationNote)) {
      (true, _, _) => (
        Icons.my_location,
        AppTheme.textSecondary,
        'Getting your location…',
      ),
      (_, final GeoFix fix, _) => (
        Icons.place,
        AppTheme.success,
        'Location captured (±${fix.accuracy?.round() ?? '?'} m)',
      ),
      (_, _, final String note) => (
        Icons.location_off_outlined,
        AppTheme.warning,
        note,
      ),
      _ => (
        Icons.location_off_outlined,
        AppTheme.warning,
        'No location yet. The visit will be saved without one.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colour.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colour),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          if (!_locating && _fix == null)
            TextButton(onPressed: _locate, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
  });

  final String label;
  final String? value;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule),
          errorText: error,
        ),
        child: Text(value ?? '--:--'),
      ),
    );
  }
}
