import 'package:flutter/material.dart';

import '../../models/trip_models.dart';
import '../../services/trip_service.dart';
import 'trip_arrival_summary_screen.dart';
import 'widgets/trip_live_map.dart';

class LiveTripDashboard extends StatefulWidget {
  const LiveTripDashboard({super.key});

  @override
  State<LiveTripDashboard> createState() => _LiveTripDashboardState();
}

class _LiveTripDashboardState extends State<LiveTripDashboard> {
  bool _completionNavigationTriggered = false;

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

          if (trip.status == TripStatus.completed && !_completionNavigationTriggered) {
            _completionNavigationTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TripArrivalSummaryScreen(trip: trip),
                ),
              );
            });
          }

          return Stack(
            children: [
              Positioned.fill(
                child: TripLiveMap(trip: trip),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopStatusBar(trip, theme),
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: _buildBottomInfoCard(trip, theme, trip.eta),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopStatusBar(TripSession trip, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
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

  Widget _buildBottomInfoCard(TripSession trip, ThemeData theme, int displayedEta) {
    return Card(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.2),
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
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                      Text('$displayedEta', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue)),
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
