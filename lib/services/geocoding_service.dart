import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_client_factory.dart'
    if (dart.library.io) 'http_client_factory_native.dart';

class GeocodingException implements Exception {
  GeocodingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeocodedLocation {
  const GeocodedLocation({
    required this.name,
    required this.displayLabel,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String displayLabel;
  final double latitude;
  final double longitude;
}

class GeocodingService {
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Map<String, String> _queryAliases = {
    'belek area': 'Belek, Serik, Antalya, Turkey',
    'belek hotel zone': 'Belek, Serik, Antalya, Turkey',
    'belek hotels': 'Belek, Serik, Antalya, Turkey',
    'lara area': 'Lara, Muratpasa, Antalya, Turkey',
    'lara beachhotels': 'Lara Beach, Muratpasa, Antalya, Turkey',
    'lara beach hotels': 'Lara Beach, Muratpasa, Antalya, Turkey',
    'lara hotels': 'Lara Beach, Muratpasa, Antalya, Turkey',
    'kundu area': 'Kundu, Aksu, Antalya, Turkey',
    'konyaalti area': 'Konyaalti, Antalya, Turkey',
    'konyaalti beach area': 'Konyaalti, Antalya, Turkey',
    'kaleici area': 'Kaleici, Muratpasa, Antalya, Turkey',
    'old town area': 'Kaleici, Muratpasa, Antalya, Turkey',
    'side area': 'Side, Manavgat, Antalya, Turkey',
    'side town center': 'Side, Manavgat, Antalya, Turkey',
    'side center': 'Side, Manavgat, Antalya, Turkey',
    'kemer area': 'Kemer, Antalya, Turkey',
    'alanya area': 'Alanya, Antalya, Turkey',
  };
  static final Map<String, List<GeocodedLocation>> _searchCache = {};

  GeocodingService({http.Client? httpClient})
      : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;

  Future<List<GeocodedLocation>> searchLocations(String query, {int limit = 5}) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final cacheKey = '${_buildSearchQuery(normalizedQuery).toLowerCase()}|$limit';
    final cached = _searchCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': _buildSearchQuery(normalizedQuery),
      'format': 'jsonv2',
      'limit': '$limit',
      'accept-language': 'en',
    });

    late final http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: const {
          'User-Agent': 'RayRide/1.0 (personal-use geocoding)',
          'Accept': 'application/json',
          'Accept-Language': 'en',
        },
      ).timeout(_requestTimeout);
    } on Exception {
      throw GeocodingException('Location search timed out. Please try again.');
    }

    if (response.statusCode != 200) {
      throw GeocodingException('Geocoding request failed. Please try again.');
    }

    final body = jsonDecode(response.body);
    if (body is! List || body.isEmpty) {
      return const [];
    }

    final results = body
        .whereType<Map<String, dynamic>>()
        .map(_toGeocodedLocation)
        .whereType<GeocodedLocation>()
        .toList();

    _storeInCache(cacheKey, results);
    return results;
  }

  Future<GeocodedLocation> searchLocation(String query) async {
    final results = await searchLocations(query, limit: 1);
    if (results.isEmpty) {
      throw GeocodingException('No location found for "$query".');
    }
    return results.first;
  }

  String _buildSearchQuery(String query) {
    final normalizedKey = query.trim().toLowerCase();
    final alias = _queryAliases[normalizedKey];
    if (alias != null) {
      return alias;
    }

    if (normalizedKey.contains(' area')) {
      final withoutArea = query.replaceAll(RegExp(r'\s+area$', caseSensitive: false), '').trim();
      if (withoutArea.isNotEmpty) {
        return '$withoutArea, Antalya, Turkey';
      }
    }

    if (normalizedKey.contains('antalya') || normalizedKey.contains('turkey')) {
      return query;
    }
    return '$query, Antalya, Turkey';
  }

  GeocodedLocation? _toGeocodedLocation(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');
    if (lat == null || lon == null) {
      return null;
    }

    final displayName = json['display_name']?.toString().trim();
    return GeocodedLocation(
      name: (displayName?.isNotEmpty ?? false) ? displayName! : 'Unknown location',
      displayLabel: _buildDisplayLabel(displayName),
      latitude: lat,
      longitude: lon,
    );
  }

  void _storeInCache(String key, List<GeocodedLocation> results) {
    if (_searchCache.length >= 50) {
      _searchCache.remove(_searchCache.keys.first);
    }
    _searchCache[key] = List<GeocodedLocation>.unmodifiable(results);
  }

  String _buildDisplayLabel(String? displayName) {
    final raw = (displayName ?? '').trim();
    if (raw.isEmpty) {
      return 'Unknown location';
    }

    final parts = raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return raw;
    }

    final first = parts[0];
    if (parts.length == 1) {
      return first;
    }

    final second = parts[1];
    if (first.length <= 24 && second.length <= 24) {
      return '$first, $second';
    }

    return first;
  }
}
