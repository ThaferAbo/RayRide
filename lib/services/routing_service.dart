import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'http_client_factory.dart'
    if (dart.library.io) 'http_client_factory_native.dart';

class RouteSnapshot {
  const RouteSnapshot({
    required this.points,
    required this.duration,
  });

  final List<LatLng> points;
  final Duration duration;
}

class RoutingService {
  static const Duration _requestTimeout = Duration(seconds: 8);
  static final Map<String, RouteSnapshot> _routeCache = {};

  RoutingService({http.Client? httpClient})
      : _httpClient = httpClient ?? createHttpClient();

  final http.Client _httpClient;

  Future<RouteSnapshot?> fetchDrivingRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final cacheKey = _buildCacheKey(start, end);
    final cached = _routeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final coordinates =
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      const {
        'overview': 'full',
        'geometries': 'geojson',
      },
    );

    http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'RayRide/1.0 (personal-use routing)',
        },
      ).timeout(_requestTimeout);
    } on Exception {
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      return null;
    }

    final routes = body['routes'];
    if (routes is! List || routes.isEmpty) {
      return null;
    }

    final route = routes.first;
    if (route is! Map<String, dynamic>) {
      return null;
    }

    final geometry = route['geometry'];
    final durationSeconds = (route['duration'] as num?)?.toDouble();
    if (geometry is! Map<String, dynamic> || durationSeconds == null) {
      return null;
    }

    final coordinatesList = geometry['coordinates'];
    if (coordinatesList is! List || coordinatesList.isEmpty) {
      return null;
    }

    final points = <LatLng>[];
    for (final coordinate in coordinatesList) {
      if (coordinate is List && coordinate.length >= 2) {
        final lon = (coordinate[0] as num?)?.toDouble();
        final lat = (coordinate[1] as num?)?.toDouble();
        if (lat != null && lon != null) {
          points.add(LatLng(lat, lon));
        }
      }
    }

    if (points.isEmpty) {
      return null;
    }

    final snapshot = RouteSnapshot(
      points: points,
      duration: Duration(seconds: durationSeconds.round()),
    );
    _storeInCache(cacheKey, snapshot);
    return snapshot;
  }

  String _buildCacheKey(LatLng start, LatLng end) {
    String formatPoint(LatLng point) =>
        '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    return '${formatPoint(start)}->${formatPoint(end)}';
  }

  void _storeInCache(String key, RouteSnapshot snapshot) {
    if (_routeCache.length >= 50) {
      _routeCache.remove(_routeCache.keys.first);
    }
    _routeCache[key] = snapshot;
  }
}
