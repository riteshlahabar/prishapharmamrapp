import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/constants.dart';
import '../../../core/location/location_service.dart';
import '../../products/domain/product.dart';
import '../domain/visit.dart';
import '../domain/visit_purpose.dart';
import '../domain/visit_photo.dart';

class VisitsRepository {
  const VisitsRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Visit>> history({int page = 1}) async {
    final envelope = await _api.get(
      AppConstants.visits,
      query: {'page': page, 'per_page': AppConstants.pageSize},
    );

    return Paginated.from(envelope, Visit.fromJson);
  }

  /// Files a visit. `mr_id` is never sent: the server takes it from the
  /// token, so a tampered build cannot file under another rep's name.
  ///
  /// With a [photo] the whole thing goes as **one** multipart request rather
  /// than a visit followed by an upload: a second call that failed would
  /// leave a saved visit with no picture, and no obvious way for the rep to
  /// tell. One request means the visit and its photo arrive together or not
  /// at all.
  Future<Visit> create({
    required int personId,
    required VisitPurpose purpose,
    String? inTime,
    String? outTime,
    String? notes,
    GeoFix? fix,
    VisitPhoto? photo,
    List<ProductLineInput> products = const [],
  }) async {
    final fields = <String, dynamic>{
      'person_id': personId,
      'purpose': purpose.value,
      'in_time': ?inTime,
      'out_time': ?outTime,
      if ((notes ?? '').isNotEmpty) 'notes': notes,
      // Left out entirely when empty: the server reads an absent key as
      // "no products", and sending [] would say the same thing louder.
      if (products.isNotEmpty)
        'products': [for (final line in products) line.toJson()],
      // Both coordinates or neither; the timestamp says when the device
      // read them, which the server keeps beside its own receive time.
      if (fix != null) ...{
        'latitude': fix.latitude,
        'longitude': fix.longitude,
        'location_fetched_at': fix.takenAt.toUtc().toIso8601String(),
      },
      if (photo != null)
        'photo_taken_at': photo.takenAt.toUtc().toIso8601String(),
    };

    final envelope = await _api.post(
      AppConstants.visits,
      body: photo == null
          ? fields
          // FormData flattens the nested product rows to
          // `products[0][product_id]`, which Laravel reads back as the same
          // array it gets from JSON.
          : FormData.fromMap({
              ...fields,
              'photo': MultipartFile.fromBytes(
                photo.bytes,
                filename: photo.filename,
              ),
            }),
    );

    return Visit.fromJson(envelope.dataMap);
  }
}
