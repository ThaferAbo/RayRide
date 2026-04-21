import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_role.dart';
import '../models/trip_models.dart';
import 'routing_service.dart';

class TripService {
  static const int _pickupSteps = 8;
  static const int _destinationSteps = 12;

  // Singleton pattern
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  // Mode state
  final ValueNotifier<AppRole> currentRole = ValueNotifier<AppRole>(AppRole.passenger);

  // Core state
  final ValueNotifier<List<RideRequest>> pendingRequests = ValueNotifier<List<RideRequest>>([]);
  final ValueNotifier<TripSession?> activeTrip = ValueNotifier<TripSession?>(null);

  final RoutingService _routingService = RoutingService();
  Timer? _simulationTimer;
  int _currentTick = 0;
  List<LatLng> _pickupLegPositions = const [];
  List<LatLng> _destinationLegPositions = const [];
  int _pickupLegEtaMinutes = 15;
  int _destinationLegEtaMinutes = 12;

  // Constants for simulation (Antalya region)
  final double _initialDriverLat = 36.8840;
  final double _initialDriverLng = 30.7050;

  void createRequest(RideRequest request) {
    pendingRequests.value = [...pendingRequests.value, request];
  }

  void rejectRequest(String requestId) {
    pendingRequests.value = pendingRequests.value.where((r) => r.id != requestId).toList();
  }

  void acceptRequest(RideRequest request) {
    // Remove accepted request from pending
    pendingRequests.value = pendingRequests.value.where((r) => r.id != request.id).toList();
    
    // Initialize session
    activeTrip.value = TripSession(
      request: request,
      status: TripStatus.accepted,
      driverLat: _initialDriverLat,
      driverLng: _initialDriverLng,
      eta: _pickupLegEtaMinutes,
    );

    _prepareSimulationAndStart(request);
  }

  bool completeTrip() {
    _simulationTimer?.cancel();
    if (activeTrip.value == null) {
      return false;
    }
    final trip = activeTrip.value!;
    trip.status = TripStatus.completed;
    trip.eta = 0;
    _publishTrip(trip);
    // Keep the completed trip visible for 3 seconds, then clear so
    // all dashboards (admin, driver, passenger) transition cleanly.
    _scheduleClearAfterCompletion();
    return true;
  }

  void resetService() {
    _simulationTimer?.cancel();
    activeTrip.value = null;
    pendingRequests.value = [];
    _currentTick = 0;
    _pickupLegPositions = const [];
    _destinationLegPositions = const [];
    _pickupLegEtaMinutes = 15;
    _destinationLegEtaMinutes = 12;
  }

  Future<void> _prepareSimulationAndStart(RideRequest request) async {
    _pickupLegPositions = _buildLinearStepPositions(
      start: LatLng(_initialDriverLat, _initialDriverLng),
      end: LatLng(request.pickupLat, request.pickupLng),
      totalSteps: _pickupSteps,
    );
    _destinationLegPositions = _buildLinearStepPositions(
      start: LatLng(request.pickupLat, request.pickupLng),
      end: LatLng(request.destLat, request.destLng),
      totalSteps: _destinationSteps,
    );
    _pickupLegEtaMinutes = 15;
    _destinationLegEtaMinutes = 12;

    final pickupRoute = await _routingService.fetchDrivingRoute(
      start: LatLng(_initialDriverLat, _initialDriverLng),
      end: LatLng(request.pickupLat, request.pickupLng),
    );
    if (pickupRoute != null) {
      _pickupLegPositions = _buildStepPositionsFromRoute(
        routePoints: pickupRoute.points,
        totalSteps: _pickupSteps,
      );
      _pickupLegEtaMinutes = pickupRoute.duration.inMinutes.clamp(1, 9999).toInt();
    }

    final destinationRoute = await _routingService.fetchDrivingRoute(
      start: LatLng(request.pickupLat, request.pickupLng),
      end: LatLng(request.destLat, request.destLng),
    );
    if (destinationRoute != null) {
      _destinationLegPositions = _buildStepPositionsFromRoute(
        routePoints: destinationRoute.points,
        totalSteps: _destinationSteps,
      );
      _destinationLegEtaMinutes = destinationRoute.duration.inMinutes.clamp(1, 9999).toInt();
    }

    final trip = activeTrip.value;
    if (trip == null || trip.request.id != request.id) {
      return;
    }

    trip.eta = _pickupLegEtaMinutes;
    _publishTrip(trip);
    _startSimulation();
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _currentTick = 0;
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final trip = activeTrip.value;
      if (trip == null) {
        timer.cancel();
        return;
      }

      _currentTick++;

      // Simulating Lifecycle
      if (_currentTick < _pickupSteps) {
        // MOVING TO PICKUP
        trip.status = TripStatus.arriving;
        _applyStepPosition(trip, _pickupLegPositions, _currentTick);
        trip.eta = _remainingEtaMinutes(
          fullEtaMinutes: _pickupLegEtaMinutes,
          currentStep: _currentTick,
          totalSteps: _pickupSteps,
        );
      } else if (_currentTick == _pickupSteps) {
        // AT PICKUP
        trip.status = TripStatus.started;
        trip.driverLat = trip.request.pickupLat;
        trip.driverLng = trip.request.pickupLng;
        trip.eta = _destinationLegEtaMinutes;
      } else if (_currentTick > _pickupSteps && _currentTick < _pickupSteps + _destinationSteps) {
        // MOVING TO DESTINATION
        trip.status = TripStatus.started;
        final destinationStep = _currentTick - _pickupSteps;
        _applyStepPosition(
          trip,
          _destinationLegPositions,
          destinationStep,
        );
        trip.eta = _remainingEtaMinutes(
          fullEtaMinutes: _destinationLegEtaMinutes,
          currentStep: destinationStep,
          totalSteps: _destinationSteps,
        );
      } else if (_currentTick >= _pickupSteps + _destinationSteps) {
        // ARRIVED
        trip.status = TripStatus.completed;
        trip.driverLat = trip.request.destLat;
        trip.driverLng = trip.request.destLng;
        trip.eta = 0;
        timer.cancel();
        _publishTrip(trip);
        _scheduleClearAfterCompletion();
        return;
      }

      _publishTrip(trip);
    });
  }

  void _applyStepPosition(TripSession trip, List<LatLng> positions, int step) {
    if (positions.isEmpty) {
      return;
    }
    final index = step.clamp(1, positions.length) - 1;
    final point = positions[index];
    trip.driverLat = point.latitude;
    trip.driverLng = point.longitude;
  }

  List<LatLng> _buildStepPositionsFromRoute({
    required List<LatLng> routePoints,
    required int totalSteps,
  }) {
    if (routePoints.isEmpty) {
      return const [];
    }

    if (routePoints.length == 1) {
      return List<LatLng>.filled(totalSteps, routePoints.first);
    }

    final positions = <LatLng>[];
    for (var step = 1; step <= totalSteps; step++) {
      final progress = step / totalSteps;
      final rawIndex = ((routePoints.length - 1) * progress).round();
      final boundedIndex = rawIndex.clamp(0, routePoints.length - 1);
      positions.add(routePoints[boundedIndex]);
    }
    return positions;
  }

  List<LatLng> _buildLinearStepPositions({
    required LatLng start,
    required LatLng end,
    required int totalSteps,
  }) {
    final positions = <LatLng>[];
    for (var step = 1; step <= totalSteps; step++) {
      final t = step / totalSteps;
      positions.add(
        LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          start.longitude + (end.longitude - start.longitude) * t,
        ),
      );
    }
    return positions;
  }

  int _remainingEtaMinutes({
    required int fullEtaMinutes,
    required int currentStep,
    required int totalSteps,
  }) {
    final remainingRatio = (totalSteps - currentStep) / totalSteps;
    final eta = (fullEtaMinutes * remainingRatio).ceil();
    return eta.clamp(0, 9999).toInt();
  }

  void _publishTrip(TripSession trip) {
    activeTrip.value = TripSession(
      request: trip.request,
      status: trip.status,
      driverLat: trip.driverLat,
      driverLng: trip.driverLng,
      eta: trip.eta,
    );
  }

  void _scheduleClearAfterCompletion() {
    Future.delayed(const Duration(seconds: 3), () {
      if (activeTrip.value?.status == TripStatus.completed) {
        activeTrip.value = null;
      }
    });
  }
}
