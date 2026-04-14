import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/trip_service.dart';
import '../../models/trip_models.dart';
import 'live_trip_dashboard.dart';

class WaitingScreen extends StatefulWidget {
  final RideRequest request;

  const WaitingScreen({super.key, required this.request});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  bool _navigationTriggered = false;

  @override
  Widget build(BuildContext context) {
    final tripService = TripService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF27A22),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<TripSession?>(
        valueListenable: tripService.activeTrip,
        builder: (context, activeTrip, _) {
          // Explicit navigation check:
          // 1. We have an active trip session
          // 2. It belongs to our current request
          // 3. The status is Accepted or later (Simulating driver interaction)
          if (activeTrip != null && 
              activeTrip.request.id == widget.request.id && 
              activeTrip.status != TripStatus.pending && 
              !_navigationTriggered) {
            
            _navigationTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LiveTripDashboard()),
              );
            });
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _LoadingIndicator(),
                  const SizedBox(height: 40),
                  const Text(
                    'Finding your driver...',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Searching for the best available ride in Antalya region',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  _BookingSummary(request: widget.request),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // Remove request from pending list and leave
                        tripService.rejectRequest(widget.request.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel Ride', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: SizedBox(
          height: 60,
          width: 60,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  final RideRequest request;
  const _BookingSummary({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.radio_button_checked,
            iconColor: Colors.blue,
            title: 'Pickup',
            subtitle: request.pickupName,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 20,
                child: VerticalDivider(thickness: 1),
              ),
            ),
          ),
          _SummaryRow(
            icon: Icons.location_on,
            iconColor: Colors.redAccent,
            title: 'Destination',
            subtitle: request.dropoffName,
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Fare', style: TextStyle(color: Colors.grey)),
              Text(
                '${request.price.toStringAsFixed(2)}€',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
