import 'dart:typed_data';

/// A picture of the shop, clinic or hospital, ready to go up with the visit.
///
/// Bytes, not a file path: [Image.file] and `MultipartFile.fromFile` do not
/// exist on the web, and the app is verified by a headless web build. Reading
/// the bytes once serves both the on-screen preview and the upload.
class VisitPhoto {
  const VisitPhoto({
    required this.bytes,
    required this.filename,
    required this.takenAt,
  });

  final Uint8List bytes;
  final String filename;

  /// When the app got the image. It travels as `photo_taken_at`, which the
  /// server keeps beside its own receive time — the same pairing as the GPS
  /// fix, and for the same reason.
  final DateTime takenAt;

  /// Roughly what the upload will weigh, for the hint under the preview.
  String get sizeLabel => bytes.length < 1024 * 1024
      ? '${(bytes.length / 1024).round()} KB'
      : '${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB';
}
