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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _adminService.loadBackendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          ValueListenableBuilder<bool>(
            valueListenable: _adminService.isLoading,
            builder: (context, loading, _) {
              return IconButton(
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: Colors.white70),
                onPressed: loading ? null : _adminService.loadBackendData,
              );
            },
          ),
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
      body: ValueListenableBuilder<String?>(
        valueListenable: _adminService.error,
        builder: (context, error, _) {
          return Column(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _inlineNotice(error, Colors.redAccent),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildTripsTab(),
                    _buildDriversTab(),
                    _buildUsersTab(),
                    _buildPricingTab(),
                  ],
                ),
              ),
            ],
          );
        },
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
              valueListenable: _adminService.trips,
              builder: (context, trips, _) {
                return ValueListenableBuilder<AdminDashboardSummary>(
                  valueListenable: _adminService.summary,
                  builder: (context, summary, _) {
                    final pending = trips
                        .where((trip) => trip.status == 'pending')
                        .length;
                    final activeDrivers = drivers
                        .where(
                          (d) => d.status == 'online' || d.status == 'busy',
                        )
                        .length;
                    final activeTrips = trips
                        .where(
                          (trip) =>
                              trip.status == 'accepted' ||
                              trip.status == 'arriving' ||
                              trip.status == 'started',
                        )
                        .length;
                    return _adminList(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final columns = width >= 1000
                                ? 4
                                : width >= 620
                                ? 2
                                : 1;
                            return GridView.count(
                              crossAxisCount: columns,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: columns == 1 ? 3.2 : 2.15,
                              children: [
                                _buildSummaryCard(
                                  'Users',
                                  (summary.totalUsers == 0
                                          ? users.length
                                          : summary.totalUsers)
                                      .toString(),
                                  Icons.people,
                                ),
                                _buildSummaryCard(
                                  'Active Drivers',
                                  activeDrivers.toString(),
                                  Icons.local_taxi,
                                ),
                                _buildSummaryCard(
                                  'Pending Trips',
                                  (summary.pendingTrips == 0
                                          ? pending
                                          : summary.pendingTrips)
                                      .toString(),
                                  Icons.pending_actions,
                                ),
                                _buildSummaryCard(
                                  'Active Trips',
                                  (summary.activeTrips == 0
                                          ? activeTrips
                                          : summary.activeTrips)
                                      .toString(),
                                  Icons.route,
                                ),
                                _buildSummaryCard(
                                  'Completed',
                                  (summary.completedTrips == 0
                                          ? _adminService
                                                .completedTrips
                                                .value
                                                .length
                                          : summary.completedTrips)
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
      valueListenable: _adminService.trips,
      builder: (context, trips, _) {
        final pending = trips
            .where((trip) => trip.status == 'pending')
            .toList();
        final active = trips.where((trip) {
          return trip.status == 'accepted' ||
              trip.status == 'arriving' ||
              trip.status == 'started';
        }).toList();
        return ValueListenableBuilder<List<RideHistoryItem>>(
          valueListenable: _adminService.completedTrips,
          builder: (context, completed, _) {
            return _adminList(
              children: [
                _sectionTitle('Active Trip'),
                const SizedBox(height: 12),
                if (active.isEmpty)
                  _emptyState('No active accepted trips.', Icons.route)
                else
                  ...active.map(
                    (trip) => _activeTripCard(
                      TripSession(
                        request: trip,
                        status: tripStatusFromString(trip.status),
                        driverLat: trip.pickupLat,
                        driverLng: trip.pickupLng,
                        eta: 0,
                      ),
                    ),
                  ),
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
  }

  Widget _buildDriversTab() {
    return ValueListenableBuilder<List<AdminDriver>>(
      valueListenable: _adminService.drivers,
      builder: (context, drivers, _) {
        final filtered = _driverFilter == 'all'
            ? drivers
            : drivers.where((d) => d.status == _driverFilter).toList();
        return _adminList(
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
        return _adminList(
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
    return ValueListenableBuilder<List<AdminVehicleOption>>(
      valueListenable: _adminService.vehicleOptions,
      builder: (context, vehicles, _) {
        return _adminList(
          children: [
            _sectionTitle('Passenger Cars'),
            const SizedBox(height: 12),
            _panelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'These cars are shown to passengers on the vehicle selection and payment flow.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Admins can add cars, delete cars, and change visible prices for the demo.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _actionButton('Add Car', Icons.add, () => _showVehicleEditor()),
            const SizedBox(height: 18),
            if (vehicles.isEmpty)
              _emptyState('No passenger cars configured.', Icons.directions_car)
            else
              ...vehicles.map(_vehicleOptionCard),
          ],
        );
      },
    );
  }

  Widget _vehicleOptionCard(AdminVehicleOption vehicle) {
    return _panelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final details = Row(
            children: [
              SizedBox(
                width: 96,
                height: 58,
                child: AntiInvertFilter(
                  child: Image.asset(vehicle.imagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vehicle.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vehicle.isVip) ...[
                          const SizedBox(width: 8),
                          _statusChip('VIP', _orange),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.subtitle,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _smallMetric('Price', vehicle.displayPrice),
                        _smallMetric('ETA', vehicle.time),
                        _smallMetric('Pax', vehicle.pax.toString()),
                        _smallMetric('Bags', vehicle.bags.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _showVehicleEditor(vehicle: vehicle),
                icon: const Icon(Icons.edit, color: _orange),
                label: const Text('Edit', style: TextStyle(color: _orange)),
              ),
              TextButton.icon(
                onPressed: () => _deleteVehicle(vehicle),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  Future<void> _showVehicleEditor({AdminVehicleOption? vehicle}) async {
    final nameCtrl = TextEditingController(text: vehicle?.name ?? '');
    final subtitleCtrl = TextEditingController(text: vehicle?.subtitle ?? '');
    final priceCtrl = TextEditingController(
      text: vehicle == null ? '' : vehicle.price.toStringAsFixed(2),
    );
    final timeCtrl = TextEditingController(text: vehicle?.time ?? '~25 min');
    final paxCtrl = TextEditingController(text: '${vehicle?.pax ?? 3}');
    final bagsCtrl = TextEditingController(text: '${vehicle?.bags ?? 2}');
    final imageCtrl = TextEditingController(
      text: vehicle?.imagePath ?? 'assets/classs.png',
    );
    var isVip = vehicle?.isVip ?? false;

    final saved = await showDialog<AdminVehicleOption>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _panel,
              title: Text(
                vehicle == null ? 'Add Car' : 'Edit Car',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogField('Name', nameCtrl, Icons.directions_car),
                      const SizedBox(height: 10),
                      _dialogField('Subtitle', subtitleCtrl, Icons.notes),
                      const SizedBox(height: 10),
                      _dialogField(
                        'Price (EUR)',
                        priceCtrl,
                        Icons.euro,
                        number: true,
                      ),
                      const SizedBox(height: 10),
                      _dialogField('ETA text', timeCtrl, Icons.timer),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogField(
                              'Pax',
                              paxCtrl,
                              Icons.person,
                              number: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dialogField(
                              'Bags',
                              bagsCtrl,
                              Icons.work,
                              number: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _dialogField('Asset image path', imageCtrl, Icons.image),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: isVip,
                        onChanged: (value) =>
                            setDialogState(() => isVip = value),
                        activeThumbColor: _orange,
                        title: const Text(
                          'VIP car',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final subtitle = subtitleCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim());
                    final pax = int.tryParse(paxCtrl.text.trim());
                    final bags = int.tryParse(bagsCtrl.text.trim());
                    final imagePath = imageCtrl.text.trim();
                    if (name.isEmpty ||
                        subtitle.isEmpty ||
                        price == null ||
                        price < 0 ||
                        pax == null ||
                        pax <= 0 ||
                        bags == null ||
                        bags < 0 ||
                        imagePath.isEmpty) {
                      _showSnackBar('Please enter valid car details.');
                      return;
                    }
                    Navigator.pop(
                      context,
                      AdminVehicleOption(
                        id:
                            vehicle?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        subtitle: subtitle,
                        price: price,
                        time: timeCtrl.text.trim().isEmpty
                            ? '~25 min'
                            : timeCtrl.text.trim(),
                        pax: pax,
                        bags: bags,
                        isVip: isVip,
                        imagePath: imagePath,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    subtitleCtrl.dispose();
    priceCtrl.dispose();
    timeCtrl.dispose();
    paxCtrl.dispose();
    bagsCtrl.dispose();
    imageCtrl.dispose();

    if (saved == null) return;
    try {
      if (vehicle == null) {
        await _adminService.addVehicleOption(saved);
        _showSnackBar('${saved.name} added.');
      } else {
        await _adminService.updateVehicleOption(saved);
        _showSnackBar('${saved.name} updated.');
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteVehicle(AdminVehicleOption vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Delete Car', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${vehicle.name} from the passenger car list?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _adminService.deleteVehicleOption(vehicle.id);
      _showSnackBar('${vehicle.name} deleted.');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _dialogField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _inputDecoration(label, icon),
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
    final activeTrips = _adminService.trips.value.where((trip) {
      return trip.status == 'accepted' ||
          trip.status == 'arriving' ||
          trip.status == 'started';
    }).toList();
    if (activeTrips.isEmpty) {
      _showSnackBar('No active trip to complete.');
      return;
    }
    _adminService
        .completeTripBackend(activeTrips.first.id)
        .then((_) {
          _adminService.addTripCompletedActivity();
          _showSnackBar('Trip has been marked as completed.');
        })
        .catchError((e) {
          _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
        });
  }

  Widget _pendingTripCard(RideRequest req) {
    return _panelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                req.passengerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${req.pickupName} -> ${req.dropoffName}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                '${req.price.toStringAsFixed(2)} EUR',
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statusChip('pending', Colors.orange),
              TextButton(
                onPressed: () async {
                  try {
                    await _adminService.cancelTripBackend(req.id);
                    _showSnackBar('Pending request cancelled.');
                  } catch (e) {
                    _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 10), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.route,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${trip.passengerName} with ${trip.driverName}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(trip.completedAt),
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          );
          final meta = Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statusChip(trip.status, Colors.green),
              Text(
                '${trip.price.toStringAsFixed(2)} EUR',
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 10), meta],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              meta,
            ],
          );
        },
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
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _metricBox('Status', driver.status),
              _metricBox('Rating', driver.rating.toStringAsFixed(1)),
              _metricBox('Trips', driver.completedTrips.toString()),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${driver.currentArea} | ${driver.phone}',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              if (!driver.isApproved)
                TextButton(
                  onPressed: () {
                    _adminService
                        .updateDriverApprovalBackend(driver.id, true)
                        .then((_) => _showSnackBar('${driver.name} approved.'))
                        .catchError(
                          (e) => _showSnackBar(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        );
                  },
                  child: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.green),
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    _adminService
                        .updateDriverApprovalBackend(driver.id, false)
                        .then(
                          (_) =>
                              _showSnackBar('${driver.name} approval removed.'),
                        )
                        .catchError(
                          (e) => _showSnackBar(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        );
                  },
                  child: const Text(
                    'Revoke',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              TextButton(
                onPressed: () {
                  if (driver.status == 'offline') {
                    _adminService
                        .updateDriverStatusBackend(driver.id, 'online')
                        .then((_) => _showSnackBar('${driver.name} activated.'))
                        .catchError(
                          (e) => _showSnackBar(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        );
                  } else {
                    _adminService
                        .updateDriverStatusBackend(driver.id, 'offline')
                        .then(
                          (_) =>
                              _showSnackBar('${driver.name} marked offline.'),
                        )
                        .catchError(
                          (e) => _showSnackBar(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        );
                  }
                },
                child: Text(
                  driver.status == 'offline' ? 'Activate' : 'Deactivate',
                  style: const TextStyle(color: _orange),
                ),
              ),
            ],
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
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _metricBox('Role', user.role),
              _metricBox('Trips', user.tripCount.toString()),
              _metricBox('Spent', '${user.totalSpent.toStringAsFixed(0)} EUR'),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _orange, size: 24),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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

  Widget _adminList({required List<Widget> children}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(padding: const EdgeInsets.all(16), children: children),
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

  Widget _inlineNotice(String message, Color color) {
    return _panelCard(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
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

  Widget _metricBox(String label, String value) {
    return SizedBox(width: 120, child: _smallMetric(label, value));
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
