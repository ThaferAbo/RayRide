import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/trip_service.dart';
import '../../models/trip_models.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tripService = TripService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Reset Demo State',
            onPressed: () {
              tripService.resetService();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo state reset successfully')),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF27A22),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<TripSession?>(
        valueListenable: tripService.activeTrip,
        builder: (context, activeTrip, _) {
          return CustomScrollView(
            slivers: [
              // Active Trip Banner (Always at top if exists)
              if (activeTrip != null)
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: _ActiveTripCard(trip: activeTrip),
                  ),
                ),

              // Pending Requests Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Text(
                        'Available Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<List<RideRequest>>(
                        valueListenable: tripService.pendingRequests,
                        builder: (context, requests, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${requests.length}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Pending Requests List (Faded if on active trip)
              ValueListenableBuilder<List<RideRequest>>(
                valueListenable: tripService.pendingRequests,
                builder: (context, requests, _) {
                  if (requests.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hail_rounded,
                              size: 48,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Searching for pings...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.only(bottom: activeTrip != null ? 100 : 20),
                    sliver: SliverOpacity(
                      opacity: activeTrip != null ? 0.6 : 1.0,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final request = requests[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 6.0,
                              ),
                              child: _RequestCard(
                                request: request,
                                isInteractionDisabled: activeTrip != null,
                              ),
                            );
                          },
                          childCount: requests.length,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final TripSession trip;

  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate progress based on status and ETA
    double progress = 0.0;
    if (trip.status == TripStatus.accepted) progress = 0.05;
    else if (trip.status == TripStatus.arriving) progress = 0.1 + (0.3 * (8 - trip.eta) / 8);
    else if (trip.status == TripStatus.started) progress = 0.4 + (0.6 * (12 - trip.eta) / 12);
    else if (trip.status == TripStatus.completed) progress = 1.0;

    return Card(
      elevation: 6,
      shadowColor: Colors.blue.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE TRIP',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.request.passengerName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                _StatusBadge(status: trip.status),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationLine(label: 'FROM', value: trip.request.pickupName, isFirst: true),
                      const SizedBox(height: 8),
                      _LocationLine(label: 'TO', value: trip.request.dropoffName, isFirst: false),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('ETA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        '${trip.eta}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blue),
                      ),
                      const Text('MIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            if (trip.request.meetAndGreetName != null && trip.request.meetAndGreetName!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MEET & GREET REQUEST', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(trip.request.meetAndGreetName!, style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  trip.status == TripStatus.completed ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TripStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    if (status == TripStatus.completed) color = Colors.green;
    if (status == TripStatus.started) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isFirst;

  const _LocationLine({required this.label, required this.value, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isFirst ? Icons.radio_button_checked : Icons.location_on,
          size: 14,
          color: isFirst ? Colors.blue : Colors.redAccent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RideRequest request;
  final bool isInteractionDisabled;

  const _RequestCard({required this.request, this.isInteractionDisabled = false});

  @override
  Widget build(BuildContext context) {
    final tripService = TripService();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor.withOpacity(isInteractionDisabled ? 0.5 : 1.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.passengerName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.pickupName} → ${request.dropoffName}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (request.meetAndGreetName != null && request.meetAndGreetName!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.badge, color: Colors.orange, size: 12),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('Sign: ${request.meetAndGreetName}', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${request.price.toStringAsFixed(1)}€',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if (!isInteractionDisabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => tripService.rejectRequest(request.id),
                      child: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => tripService.acceptRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
