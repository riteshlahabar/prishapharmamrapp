import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../domain/visit_photo.dart';

/// One picture of the shop, clinic or hospital, taken while filing the visit.
///
/// The camera is the point of it — the photo is evidence the rep stood at the
/// place — so **Camera** is the primary button and the gallery is the
/// fallback for a phone whose camera app misbehaves, or a picture taken a
/// minute earlier. Either way the app reports when it got the image
/// (`photo_taken_at`), and the server keeps that beside its own receive time.
///
/// Nothing here is required: a visit filed with no photo is still a visit,
/// and a refused camera permission is a notice rather than a dead end.
class VisitPhotoField extends StatefulWidget {
  const VisitPhotoField({required this.onChanged, this.error, super.key});

  /// Null when there is no photo, or the rep removed the one they took.
  final ValueChanged<VisitPhoto?> onChanged;

  /// What the server said about `photo` — too large, or not an image.
  final String? error;

  @override
  State<VisitPhotoField> createState() => _VisitPhotoFieldState();
}

class _VisitPhotoFieldState extends State<VisitPhotoField> {
  final _picker = ImagePicker();

  VisitPhoto? _photo;
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);

    try {
      // Shrunk and re-encoded on the device: a modern phone's full frame is
      // several megabytes, and a rep on a village 3G signal would be waiting
      // on it. 1600px wide still reads a shopfront board clearly.
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 70,
      );

      if (file == null) return; // Backed out of the camera.

      final bytes = await file.readAsBytes();

      final photo = VisitPhoto(
        bytes: bytes,
        filename: file.name.isEmpty ? 'visit.jpg' : file.name,
        takenAt: DateTime.now(),
      );

      if (mounted) setState(() => _photo = photo);
      widget.onChanged(photo);
    } on Object catch (error) {
      // A denied camera permission arrives here as a PlatformException; the
      // visit must still be fileable, so this is a notice, not a blocker.
      if (mounted) {
        showNotice(
          context,
          'Could not get that photo. $errorHint',
          isError: true,
        );
      }
      debugPrint('visit photo: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const errorHint = 'Check the app has camera and photo access.';

  void _remove() {
    setState(() => _photo = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.error == null ? AppTheme.line : AppTheme.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, size: 18, color: AppTheme.teal),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Shop / hospital photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (photo != null)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.danger,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            photo == null
                ? 'Optional — a picture of the place you visited'
                : 'Attached · ${photo.sizeLabel}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                photo.bytes,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (photo != null) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: Icon(
                    photo == null ? Icons.photo_camera : Icons.refresh,
                    size: 18,
                  ),
                  label: Text(photo == null ? 'Camera' : 'Retake'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (widget.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.error!,
                style: const TextStyle(fontSize: 12, color: AppTheme.danger),
              ),
            ),
        ],
      ),
    );
  }
}
