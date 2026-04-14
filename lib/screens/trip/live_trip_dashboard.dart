import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/trip_service.dart';
import '../../models/trip_models.dart';

class LiveTripDashboard extends StatefulWidget {
  // CONFIG: Toggle this to false once Google Maps API Keys are configured
  static const bool useMockMapFallback = true;

  const LiveTripDashboard({super.key});

  @override
  State<LiveTripDashboard> createState() => _LiveTripDashboardState();
}

class _LiveTripDashboardState extends State<LiveTripDashboard> {
  GoogleMapController? _mapController;
  bool _completionDialogShown = false;
  
  // Track last position to avoid redundant camera animations
  double? _lastLat;
  double? _lastLng;

  @override
  Widget build(BuildContext context) {
    final tripService = TripService();
    final theme = Theme.of(context);

    return Scaffold(
      body: ValueListenableBuilder<TripSession?>(
        valueListenable: tripService.activeTrip,
        builder: (context, trip, _) {
          if (trip == null) {
            return const Center(child: Text('No active trip session found'));
          }

          // Trigger Completion Dialog ONLY ONCE
          if (trip.status == TripStatus.completed && !_completionDialogShown) {
            _completionDialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCompletionDialog(context, trip);
            });
          }

          // Safe Camera Follow for Google Maps
          if (!LiveTripDashboard.useMockMapFallback && _mapController != null) {
            if (_lastLat != trip.driverLat || _lastLng != trip.driverLng) {
              _lastLat = trip.driverLat;
              _lastLng = trip.driverLng;
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(LatLng(trip.driverLat, trip.driverLng)),
              );
            }
          }

          return Stack(
            children: [
              // Map Background
              Positioned.fill(
                child: LiveTripDashboard.useMockMapFallback
                  ? MockMapWidget(trip: trip)
                  : _buildGoogleMap(trip),
              ),

              // Top Status Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopStatusBar(trip, theme),
              ),

              // Bottom Info Card
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: _buildBottomInfoCard(trip, theme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoogleMap(TripSession trip) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(trip.driverLat, trip.driverLng),
        zoom: 14,
      ),
      onMapCreated: (controller) => _mapController = controller,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(trip.driverLat, trip.driverLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Driver'),
        ),
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(trip.request.pickupLat, trip.request.pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(trip.request.destLat, trip.request.destLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
    );
  }

  Widget _buildTopStatusBar(TripSession trip, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
            ),
            child: Text(
              trip.status.name.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.security, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoCard(TripSession trip, ThemeData theme) {
    return Card(
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person_rounded, size: 30, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('George R.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('4.9 (1.2k)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Text('${trip.eta}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue)),
                      const Text('MINS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(icon: Icons.chat_outlined, label: 'Chat'),
                _ActionButton(icon: Icons.call_outlined, label: 'Call'),
                _ActionButton(icon: Icons.cancel_outlined, label: 'Cancel', color: Colors.red.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, TripSession trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 70, color: Colors.green),
              const SizedBox(height: 20),
              const Text('Ride Completed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('You reached ${trip.request.dropoffName}!', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Text('${trip.request.price.toStringAsFixed(2)}€', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    TripService().resetService();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('New Ride'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _ActionButton({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 22),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: color ?? Colors.blue, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class MockMapWidget extends StatelessWidget {
  final TripSession trip;
  const MockMapWidget({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                itemBuilder: (_, __) => Container(decoration: BoxDecoration(border: Border.all())),
              ),
            ),
          ),
          _buildMarker(trip.driverLat, trip.driverLng, trip.request, Icons.local_taxi_rounded, Colors.blue, true),
          _buildMarker(trip.request.pickupLat, trip.request.pickupLng, trip.request, Icons.person_pin_circle_rounded, Colors.green, false),
          _buildMarker(trip.request.destLat, trip.request.destLng, trip.request, Icons.flag_rounded, Colors.red, false),
        ],
      ),
    );
  }

  Widget _buildMarker(double lat, double lng, RideRequest req, IconData icon, Color color, bool isDriver) {
    double minLat = [req.pickupLat, req.destLat, 36.884].reduce((a, b) => a < b ? a : b) - 0.01;
    double maxLat = [req.pickupLat, req.destLat, 36.884].reduce((a, b) => a > b ? a : b) + 0.01;
    double minLng = [req.pickupLng, req.destLng, 30.705].reduce((a, b) => a < b ? a : b) - 0.01;
    double maxLng = [req.pickupLng, req.destLng, 30.705].reduce((a, b) => a > b ? a : b) + 0.01;

    double y = 1.0 - (lat - minLat) / (maxLat - minLat);
    double x = (lng - minLng) / (maxLng - minLng);

    return AnimatedAlign(
      duration: isDriver ? const Duration(seconds: 2) : Duration.zero,
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: Icon(icon, color: Colors.white, size: isDriver ? 24 : 18),
          ),
        ],
      ),
    );
  }
}
