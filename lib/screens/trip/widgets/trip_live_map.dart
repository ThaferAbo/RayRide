import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/trip_models.dart';
import '../../../services/routing_service.dart';

class TripLiveMap extends StatefulWidget {
  const TripLiveMap({
    super.key,
    required this.trip,
    this.onEtaChanged,
  });

  final TripSession trip;
  final ValueChanged<int?>? onEtaChanged;

  @override
  State<TripLiveMap> createState() => _TripLiveMapState();
}

class _TripLiveMapState extends State<TripLiveMap> {
  static const double _defaultZoom = 14;
  static const Duration _autoFollowCooldown = Duration(seconds: 8);

  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();
  DateTime? _autoFollowPausedUntil;
  List<LatLng> _routePoints = const [];
  String? _activeLegKey;
  int _routeRequestId = 0;
  double? _lastLat;
  double? _lastLng;

  @override
  void initState() {
    super.initState();
    _syncRouteForTrip(widget.trip);
  }

  @override
  void didUpdateWidget(covariant TripLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRouteForTrip(widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    if (_lastLat != trip.driverLat || _lastLng != trip.driverLng) {
      _lastLat = trip.driverLat;
      _lastLng = trip.driverLng;
      if (_shouldAutoFollowDriver()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final zoom = _mapController.camera.zoom.clamp(12.0, 16.0).toDouble();
          _mapController.move(
            LatLng(trip.driverLat, trip.driverLng),
            zoom,
          );
        });
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: _tripPoints(trip),
          padding: const EdgeInsets.fromLTRB(48, 96, 48, 220),
          maxZoom: 15,
        ),
        initialCenter: LatLng(trip.driverLat, trip.driverLng),
        initialZoom: _defaultZoom,
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) {
            _autoFollowPausedUntil = DateTime.now().add(_autoFollowCooldown);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.rayride.app',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5,
                color: Colors.blue.withValues(alpha: 0.75),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            _buildMarker(
              point: LatLng(trip.driverLat, trip.driverLng),
              icon: Icons.local_taxi_rounded,
              color: Colors.blue,
              size: 42,
            ),
            _buildMarker(
              point: LatLng(trip.request.pickupLat, trip.request.pickupLng),
              icon: Icons.person_pin_circle_rounded,
              color: Colors.green,
            ),
            _buildMarker(
              point: LatLng(trip.request.destLat, trip.request.destLng),
              icon: Icons.flag_rounded,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Marker _buildMarker({
    required LatLng point,
    required IconData icon,
    required Color color,
    double size = 36,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      ),
    );
  }

  List<LatLng> _tripPoints(TripSession trip) {
    return [
      LatLng(trip.driverLat, trip.driverLng),
      LatLng(trip.request.pickupLat, trip.request.pickupLng),
      LatLng(trip.request.destLat, trip.request.destLng),
    ];
  }

  bool _shouldAutoFollowDriver() {
    final pausedUntil = _autoFollowPausedUntil;
    if (pausedUntil == null) {
      return true;
    }
    return DateTime.now().isAfter(pausedUntil);
  }

  Future<void> _syncRouteForTrip(TripSession trip) async {
    final leg = _currentLeg(trip);
    if (leg == null) {
      _activeLegKey = null;
      if (_routePoints.isNotEmpty && mounted) {
        setState(() => _routePoints = const []);
      }
      widget.onEtaChanged?.call(null);
      return;
    }

    if (_activeLegKey == leg.key) {
      return;
    }

    _activeLegKey = leg.key;
    final requestId = ++_routeRequestId;
    final snapshot = await _routingService.fetchDrivingRoute(
      start: LatLng(trip.driverLat, trip.driverLng),
      end: leg.target,
    );

    if (!mounted || requestId != _routeRequestId || _activeLegKey != leg.key) {
      return;
    }

    if (snapshot == null) {
      setState(() => _routePoints = const []);
      widget.onEtaChanged?.call(null);
      return;
    }

    setState(() => _routePoints = snapshot.points);
    final etaMinutes = snapshot.duration.inMinutes.clamp(1, 9999).toInt();
    widget.onEtaChanged?.call(etaMinutes);
  }

  _TripLeg? _currentLeg(TripSession trip) {
    switch (trip.status) {
      case TripStatus.pending:
      case TripStatus.accepted:
      case TripStatus.arriving:
        return _TripLeg(
          key: 'pickup:${trip.request.pickupLat},${trip.request.pickupLng}',
          target: LatLng(trip.request.pickupLat, trip.request.pickupLng),
        );
      case TripStatus.started:
        return _TripLeg(
          key: 'destination:${trip.request.destLat},${trip.request.destLng}',
          target: LatLng(trip.request.destLat, trip.request.destLng),
        );
      case TripStatus.completed:
        return null;
    }
  }
}

class _TripLeg {
  const _TripLeg({
    required this.key,
    required this.target,
  });

  final String key;
  final LatLng target;
}
