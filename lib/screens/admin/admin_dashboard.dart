import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/trip_service.dart';
import '../../models/trip_models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF151B2D);
  static const _panel = Color(0xFF1E2742);
  static const _orange = Color(0xFFF27A22);

  late TabController _tabController;
  final AdminService _adminService = AdminService();
  String _driverFilter = 'all';
  String _userFilter = 'all';
  String _userSearch = '';

  late final TextEditingController _baseFareCtrl;
  late final TextEditingController _serviceFeeCtrl;
  late final TextEditingController _vipMultiplierCtrl;
  late final TextEditingController _airportPriceCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _syncPricingControllers();
  }

  void _syncPricingControllers() {
    final p = _adminService.pricing.value;
    _baseFareCtrl = TextEditingController(text: p.baseFare.toStringAsFixed(2));
    _serviceFeeCtrl = TextEditingController(
      text: p.serviceFeePercent.toStringAsFixed(2),
    );
    _vipMultiplierCtrl = TextEditingController(
      text: p.vipMultiplier.toStringAsFixed(2),
    );
    _airportPriceCtrl = TextEditingController(
      text: p.airportRoutePrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _baseFareCtrl.dispose();
    _serviceFeeCtrl.dispose();
    _vipMultiplierCtrl.dispose();
    _airportPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _panel,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _orange,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _orange,
          unselectedLabelColor: Colors.white54,
          indicatorColor: _orange,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trips'),
            Tab(text: 'Drivers'),
            Tab(text: 'Users'),
            Tab(text: 'Pricing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTripsTab(),
          _buildDriversTab(),
          _buildUsersTab(),
          _buildPricingTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ValueListenableBuilder<List<AdminUser>>(
      valueListenable: _adminService.users,
      builder: (context, users, _) {
        return ValueListenableBuilder<List<AdminDriver>>(
          valueListenable: _adminService.drivers,
          builder: (context, drivers, _) {
            return ValueListenableBuilder<List<RideRequest>>(
              valueListenable: TripService().pendingRequests,
              builder: (context, pending, _) {
                return ValueListenableBuilder<TripSession?>(
                  valueListenable: TripService().activeTrip,
                  builder: (context, activeTrip, _) {
                    final activeDrivers = drivers
                        .where(
                          (d) => d.status == 'online' || d.status == 'busy',
                        )
                        .length;
                    final isActiveTrip =
                        activeTrip != null &&
                        activeTrip.status != TripStatus.completed;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth > 680;
                            return GridView.count(
                              crossAxisCount: wide ? 4 : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: wide ? 1.45 : 1.25,
                              children: [
                                _buildSummaryCard(
                                  'Users',
                                  users.length.toString(),
                                  Icons.people,
                                ),
                                _buildSummaryCard(
                                  'Active Drivers',
                                  activeDrivers.toString(),
                                  Icons.local_taxi,
                                ),
                                _buildSummaryCard(
                                  'Pending Trips',
                                  pending.length.toString(),
                                  Icons.pending_actions,
                                ),
                                _buildSummaryCard(
                                  'Active Trips',
                                  isActiveTrip ? '1' : '0',
                                  Icons.route,
                                ),
                                _buildSummaryCard(
                                  'Completed',
                                  _adminService.completedTrips.value.length
                                      .toString(),
                                  Icons.check_circle,
                                ),
                                _buildSummaryCard(
                                  'Today Revenue',
                                  '${_adminService.todayRevenue.toStringAsFixed(0)} EUR',
                                  Icons.payments,
                                ),
                                _buildSummaryCard(
                                  'Avg Rating',
                                  _adminService.averageDriverRating
                                      .toStringAsFixed(1),
                                  Icons.star,
                                ),
                                _buildSummaryCard(
                                  'Suspended',
                                  users
                                      .where((u) => !u.isActive)
                                      .length
                                      .toString(),
                                  Icons.block,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Quick Actions'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _actionButton(
                              'Add Mock Request',
                              Icons.add,
                              _addMockRequest,
                            ),
                            _actionButton(
                              'Reset Demo State',
                              Icons.refresh,
                              () {
                                TripService().resetService();
                                _adminService.addDemoResetActivity();
                                _showSnackBar('Demo state has been reset.');
                              },
                              color: Colors.redAccent,
                            ),
                            _actionButton(
                              'Complete Active Trip',
                              Icons.check_circle,
                              _simulateCompleteTrip,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Recent Activity'),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<List<AdminActivity>>(
                          valueListenable: _adminService.activities,
                          builder: (context, activities, _) {
                            if (activities.isEmpty) {
                              return _emptyState(
                                'No activity yet.',
                                Icons.history,
                              );
                            }
                            return Column(
                              children: activities.map(_activityTile).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTripsTab() {
    return ValueListenableBuilder<List<RideRequest>>(
      valueListenable: TripService().pendingRequests,
      builder: (context, pending, _) {
        return ValueListenableBuilder<TripSession?>(
          valueListenable: TripService().activeTrip,
          builder: (context, activeTrip, _) {
            return ValueListenableBuilder<List<RideHistoryItem>>(
              valueListenable: _adminService.completedTrips,
              builder: (context, completed, _) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle('Active Trip'),
                    const SizedBox(height: 12),
                    if (activeTrip == null)
                      _emptyState(
                        'No active trip. Add a mock request, then accept it from Driver flow.',
                        Icons.route,
                      )
                    else
                      _activeTripCard(activeTrip),
                    const SizedBox(height: 24),
                    _sectionTitle('Pending Requests'),
                    const SizedBox(height: 12),
                    if (pending.isEmpty)
                      _emptyState(
                        'No pending ride requests.',
                        Icons.pending_actions,
                      )
                    else
                      ...pending.map(_pendingTripCard),
                    const SizedBox(height: 24),
                    _sectionTitle('Completed Trip History'),
                    const SizedBox(height: 12),
                    if (completed.isEmpty)
                      _emptyState(
                        'No completed trips yet.',
                        Icons.check_circle_outline,
                      )
                    else
                      ...completed.map(_historyTripCard),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDriversTab() {
    return ValueListenableBuilder<List<AdminDriver>>(
      valueListenable: _adminService.drivers,
      builder: (context, drivers, _) {
        final filtered = _driverFilter == 'all'
            ? drivers
            : drivers.where((d) => d.status == _driverFilter).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _filterRow(
              values: const ['all', 'online', 'offline', 'busy'],
              selected: _driverFilter,
              onSelected: (value) => setState(() => _driverFilter = value),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _emptyState('No drivers match this filter.', Icons.local_taxi)
            else
              ...filtered.map(_driverCard),
          ],
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return ValueListenableBuilder<List<AdminUser>>(
      valueListenable: _adminService.users,
      builder: (context, users, _) {
        final filtered = users.where((u) {
          final matchesRole = _userFilter == 'all' || u.role == _userFilter;
          final q = _userSearch.toLowerCase().trim();
          final matchesSearch =
              q.isEmpty ||
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
          return matchesRole && matchesSearch;
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _userSearch = value),
              decoration: _inputDecoration('Search users', Icons.search),
            ),
            const SizedBox(height: 12),
            _filterRow(
              values: const ['all', 'passenger', 'driver'],
              selected: _userFilter,
              onSelected: (value) => setState(() => _userFilter = value),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _emptyState('No users match this search.', Icons.people_outline)
            else
              ...filtered.map(_userCard),
          ],
        );
      },
    );
  }

  Widget _buildPricingTab() {
    return ValueListenableBuilder<AdminPricingConfig>(
      valueListenable: _adminService.pricing,
      builder: (context, pricing, _) {
        final standardPreview = _previewPrice(isVip: false);
        final vipPreview = _previewPrice(isVip: true);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Pricing Controls'),
            const SizedBox(height: 12),
            _buildPricingField('Base Fare (EUR)', _baseFareCtrl),
            const SizedBox(height: 12),
            _buildPricingField('Service Fee (%)', _serviceFeeCtrl),
            const SizedBox(height: 12),
            _buildPricingField('VIP Multiplier', _vipMultiplierCtrl),
            const SizedBox(height: 12),
            _buildPricingField('Airport Route Price (EUR)', _airportPriceCtrl),
            const SizedBox(height: 18),
            _panelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sample Fare Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _smallMetric(
                          'Standard',
                          '${standardPreview.toStringAsFixed(2)} EUR',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _smallMetric(
                          'VIP',
                          '${vipPreview.toStringAsFixed(2)} EUR',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Last updated: ${_formatDateTime(pricing.lastUpdated)}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'Save Changes',
                    Icons.save,
                    _savePricing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    'Reset Defaults',
                    Icons.restore,
                    _resetPricing,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _addMockRequest() {
    final price = _adminService.computeMockPrice();
    TripService().createRequest(
      RideRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        passengerName: 'Demo Passenger',
        pickupName: 'Antalya Airport (AYT)',
        dropoffName: 'Belek Tourism District',
        pickupLat: 36.9005,
        pickupLng: 30.7955,
        destLat: 36.8550,
        destLng: 31.0450,
        price: price,
      ),
    );
    _adminService.addMockRequestActivity(price);
    _showSnackBar('Mock request added (${price.toStringAsFixed(2)} EUR).');
  }

  void _simulateCompleteTrip() {
    final completed = TripService().completeTrip();
    if (completed) {
      _adminService.addTripCompletedActivity();
      _showSnackBar('Trip has been marked as completed.');
    } else {
      _showSnackBar('No active trip to complete.');
    }
  }

  void _savePricing() {
    final baseFare = double.tryParse(_baseFareCtrl.text);
    final serviceFee = double.tryParse(_serviceFeeCtrl.text);
    final vipMultiplier = double.tryParse(_vipMultiplierCtrl.text);
    final airportPrice = double.tryParse(_airportPriceCtrl.text);

    if (baseFare == null ||
        serviceFee == null ||
        vipMultiplier == null ||
        airportPrice == null) {
      _showSnackBar('Invalid input. Please enter valid numbers.');
      return;
    }
    if (baseFare < 0 ||
        serviceFee < 0 ||
        serviceFee > 50 ||
        vipMultiplier < 1 ||
        airportPrice < 0) {
      _showSnackBar(
        'Check pricing values: fees must be positive and service fee must be under 50%.',
      );
      return;
    }

    _adminService.updatePricing(
      AdminPricingConfig(
        baseFare: baseFare,
        serviceFeePercent: serviceFee,
        vipMultiplier: vipMultiplier,
        airportRoutePrice: airportPrice,
      ),
    );
    _showSnackBar('Pricing updated. New mock requests will use these values.');
  }

  void _resetPricing() {
    _adminService.resetPricing();
    final p = _adminService.pricing.value;
    _baseFareCtrl.text = p.baseFare.toStringAsFixed(2);
    _serviceFeeCtrl.text = p.serviceFeePercent.toStringAsFixed(2);
    _vipMultiplierCtrl.text = p.vipMultiplier.toStringAsFixed(2);
    _airportPriceCtrl.text = p.airportRoutePrice.toStringAsFixed(2);
    _showSnackBar('Pricing reset to defaults.');
  }

  double _previewPrice({required bool isVip}) {
    final baseFare = double.tryParse(_baseFareCtrl.text);
    final serviceFee = double.tryParse(_serviceFeeCtrl.text);
    final vipMultiplier = double.tryParse(_vipMultiplierCtrl.text);
    final airportPrice = double.tryParse(_airportPriceCtrl.text);
    if (baseFare == null ||
        serviceFee == null ||
        vipMultiplier == null ||
        airportPrice == null) {
      return 0;
    }
    var fare = baseFare + airportPrice;
    if (isVip) fare *= vipMultiplier;
    return fare + (fare * serviceFee / 100);
  }

  Widget _pendingTripCard(RideRequest req) {
    return _panelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          req.passengerName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${req.pickupName}\n${req.dropoffName}\n${req.price.toStringAsFixed(2)} EUR',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statusChip('pending', Colors.orange),
            TextButton(
              onPressed: () {
                TripService().rejectRequest(req.id);
                _showSnackBar('Pending request cancelled.');
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeTripCard(TripSession trip) {
    return _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.request.passengerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusChip(trip.status.name, Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${trip.request.pickupName} -> ${trip.request.dropoffName}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'ETA: ${trip.eta} min | Driver location: ${trip.driverLat.toStringAsFixed(4)}, ${trip.driverLng.toStringAsFixed(4)}',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _historyTripCard(RideHistoryItem trip) {
    return _panelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          trip.route,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${trip.passengerName} with ${trip.driverName}\n${_formatDateTime(trip.completedAt)}',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statusChip(trip.status, Colors.green),
            const SizedBox(height: 6),
            Text(
              '${trip.price.toStringAsFixed(2)} EUR',
              style: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverCard(AdminDriver driver) {
    final statusColor = driver.status == 'online'
        ? Colors.green
        : driver.status == 'busy'
        ? Colors.orange
        : Colors.grey;
    return _panelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${driver.vehicle} | ${driver.plate}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              _statusChip(
                driver.isApproved ? 'approved' : 'pending',
                driver.isApproved ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _smallMetric('Status', driver.status)),
              Expanded(
                child: _smallMetric('Rating', driver.rating.toStringAsFixed(1)),
              ),
              Expanded(
                child: _smallMetric('Trips', driver.completedTrips.toString()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${driver.currentArea} | ${driver.phone}',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                if (driver.status == 'offline') {
                  _adminService.activateDriver(driver.id);
                  _showSnackBar('${driver.name} activated.');
                } else {
                  _adminService.deactivateDriver(driver.id);
                  _showSnackBar('${driver.name} marked offline.');
                }
              },
              child: Text(
                driver.status == 'offline' ? 'Activate' : 'Deactivate',
                style: const TextStyle(color: _orange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(AdminUser user) {
    return _panelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: _orange,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${user.email} | ${user.phone}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              _statusChip(
                user.isActive ? 'active' : 'suspended',
                user.isActive ? Colors.green : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _smallMetric('Role', user.role)),
              Expanded(child: _smallMetric('Trips', user.tripCount.toString())),
              Expanded(
                child: _smallMetric(
                  'Spent',
                  '${user.totalSpent.toStringAsFixed(0)} EUR',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${user.location}\nLast trip: ${user.lastTrip}',
            style: const TextStyle(color: Colors.white54),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _adminService.toggleUserStatus(user.id);
                _showSnackBar(
                  user.isActive
                      ? '${user.name} suspended.'
                      : '${user.name} reactivated.',
                );
              },
              child: Text(
                user.isActive ? 'Suspend' : 'Reactivate',
                style: TextStyle(
                  color: user.isActive ? Colors.redAccent : _orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTile(AdminActivity activity) {
    final icon = activity.type == 'driver'
        ? Icons.local_taxi
        : activity.type == 'user'
        ? Icons.person
        : activity.type == 'pricing'
        ? Icons.payments
        : Icons.route;
    return _panelCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: _orange.withValues(alpha: 0.18),
          child: Icon(icon, color: _orange),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          activity.description,
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Text(
          _relativeTime(activity.timestamp),
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _orange, size: 28),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _panelCard({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return _panelCard(
      child: Row(
        children: [
          Icon(icon, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color color = _orange,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _filterRow({
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      children: values.map((value) {
        final active = selected == value;
        return FilterChip(
          selected: active,
          label: Text(_titleCase(value)),
          onSelected: (_) => onSelected(value),
          backgroundColor: _panel,
          selectedColor: _orange,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: active ? Colors.white : Colors.white70),
          side: const BorderSide(color: Colors.white12),
        );
      }).toList(),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        _titleCase(label),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _smallMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(label, Icons.euro),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: _panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _formatDateTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.day}/${time.month}/${time.year} $hour:$minute';
  }
}
