import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/trip_models.dart';

class TripService {
  // Singleton pattern
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  // Mode state
  final ValueNotifier<bool> isDriverMode = ValueNotifier<bool>(false);

  // Core state
  final ValueNotifier<List<RideRequest>> pendingRequests = ValueNotifier<List<RideRequest>>([]);
  final ValueNotifier<TripSession?> activeTrip = ValueNotifier<TripSession?>(null);

  Timer? _simulationTimer;
  int _currentTick = 0;

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
      eta: 15,
    );

    // Start simulation
    _startSimulation();
  }

  void completeTrip() {
    _simulationTimer?.cancel();
    if (activeTrip.value != null) {
      activeTrip.value!.status = TripStatus.completed;
      activeTrip.notifyListeners(); // Force update
    }
    // We keep activeTrip for a moment so the UI can show completion
  }

  void resetService() {
    _simulationTimer?.cancel();
    activeTrip.value = null;
    pendingRequests.value = [];
    _currentTick = 0;
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
      if (_currentTick < 8) {
        // MOVING TO PICKUP
        trip.status = TripStatus.arriving;
        _interpolatePosition(
          trip,
          _initialDriverLat, _initialDriverLng,
          trip.request.pickupLat, trip.request.pickupLng,
          _currentTick, 8,
        );
        trip.eta = 8 - _currentTick;
      } else if (_currentTick == 8) {
        // AT PICKUP
        trip.status = TripStatus.started;
        trip.driverLat = trip.request.pickupLat;
        trip.driverLng = trip.request.pickupLng;
        trip.eta = 12; // Time to destination starts
      } else if (_currentTick > 8 && _currentTick < 20) {
        // MOVING TO DESTINATION
        trip.status = TripStatus.started;
        _interpolatePosition(
          trip,
          trip.request.pickupLat, trip.request.pickupLng,
          trip.request.destLat, trip.request.destLng,
          _currentTick - 8, 12,
        );
        trip.eta = 20 - _currentTick;
      } else if (_currentTick >= 20) {
        // ARRIVED
        trip.status = TripStatus.completed;
        trip.driverLat = trip.request.destLat;
        trip.driverLng = trip.request.destLng;
        trip.eta = 0;
        timer.cancel();
      }

      activeTrip.notifyListeners();
    });
  }

  void _interpolatePosition(
    TripSession trip,
    double startLat, double startLng,
    double endLat, double endLng,
    int step, int totalSteps,
  ) {
    double t = step / totalSteps;
    trip.driverLat = startLat + (endLat - startLat) * t;
    trip.driverLng = startLng + (endLng - startLng) * t;
  }
}
