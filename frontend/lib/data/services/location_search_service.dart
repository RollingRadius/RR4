import 'package:dio/dio.dart';
import 'package:fleet_management/core/config/app_config.dart';

/// A single autocomplete suggestion returned by LocationIQ.
class LocationSuggestion {
  final String placeId;
  final String displayPlace;   // short name, e.g. "Jaipur"
  final String displayAddress; // full address, e.g. "Jaipur, Rajasthan, India"
  final double lat;
  final double lon;

  const LocationSuggestion({
    required this.placeId,
    required this.displayPlace,
    required this.displayAddress,
    required this.lat,
    required this.lon,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> j) {
    return LocationSuggestion(
      placeId: j['place_id']?.toString() ?? '',
      displayPlace: j['display_place'] as String? ?? j['display_name'] as String? ?? '',
      displayAddress: j['display_address'] as String? ?? j['display_name'] as String? ?? '',
      lat: double.tryParse(j['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(j['lon']?.toString() ?? '') ?? 0,
    );
  }
}

/// Calls LocationIQ autocomplete API.
/// Returns up to [limit] suggestions for [query], filtered to India.
class LocationSearchService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.locationiq.com/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  static Future<List<LocationSuggestion>> search(
    String query, {
    int limit = 5,
  }) async {
    if (query.trim().length < 2) return [];

    try {
      final resp = await _dio.get('/autocomplete', queryParameters: {
        'key': AppConfig.locationIqKey,
        'q': query.trim(),
        'countrycodes': 'in',
        'limit': limit,
        'dedupe': 1,
        'tag': 'place:city,place:town,place:village,place:hamlet,place:state',
      });

      final list = resp.data as List<dynamic>? ?? [];
      return list
          .map((e) => LocationSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }
}
