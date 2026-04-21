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

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  // Persistent pricing controllers -- initialized once from AdminService,
  // written back on "Save Changes". This avoids the Flutter anti-pattern of
  // creating TextEditingControllers inside a builder (which discards edits
  // on every rebuild).
  late final TextEditingController _baseFareCtrl;
  late final TextEditingController _serviceFeeCtrl;
  late final TextEditingController _vipMultiplierCtrl;
  late final TextEditingController _airportPriceCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    final p = _adminService.pricing.value;
    _baseFareCtrl = TextEditingController(text: p.baseFare.toString());
    _serviceFeeCtrl = TextEditingController(text: p.serviceFeePercent.toString());
    _vipMultiplierCtrl = TextEditingController(text: p.vipMultiplier.toString());
    _airportPriceCtrl = TextEditingController(text: p.airportRoutePrice.toString());
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
      backgroundColor: const Color(0xFF151B2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2742),
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFF27A22),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFFF27A22),
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

  // ---------------------------------------------------------------------------
  // OVERVIEW TAB
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab() {
    return ValueListenableBuilder(
      valueListenable: _adminService.users,
      builder: (context, users, _) {
        return ValueListenableBuilder(
          valueListenable: _adminService.drivers,
          builder: (context, drivers, _) {
            return ValueListenableBuilder(
              valueListenable: TripService().pendingRequests,
              builder: (context, pending, _) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('Total Users', users.length.toString(), Icons.people)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSummaryCard('Total Drivers', drivers.length.toString(), Icons.directions_car)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('Pending Requests', pending.length.toString(), Icons.pending_actions)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ValueListenableBuilder(
                            valueListenable: TripService().activeTrip,
                            builder: (context, activeTrip, _) {
                              final isActive = activeTrip != null && activeTrip.status != TripStatus.completed;
                              return _buildSummaryCard('Active Trips', isActive ? '1' : '0', Icons.local_taxi);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addMockRequest,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Mock Request'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF27A22), foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            TripService().resetService();
                            _showSnackBar('Demo state has been reset.');
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Demo State'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          onPressed: _simulateCompleteTrip,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Simulate Complete Trip'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ],
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Creates a mock ride request with real, separated Antalya coordinates
  /// and a price computed from the current admin pricing configuration.
  void _addMockRequest() {
    final price = _adminService.computeMockPrice();
    TripService().createRequest(RideRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      passengerName: 'Demo Passenger',
      pickupName: 'Antalya Airport (AYT)',
      dropoffName: 'Belek Tourism District',
      // Antalya Airport -- far enough from the driver start position
      // (36.8840, 30.7050) to produce visible movement during simulation
      pickupLat: 36.9005,
      pickupLng: 30.7955,
      // Belek area -- ~25 km east of the airport
      destLat: 36.8550,
      destLng: 31.0450,
      price: price,
    ));
    _showSnackBar('Mock request added (${price.toStringAsFixed(2)} EUR).');
  }

  /// Attempts to complete the active trip and provides clear feedback.
  void _simulateCompleteTrip() {
    final completed = TripService().completeTrip();
    if (completed) {
      _showSnackBar('Trip has been marked as completed.');
    } else {
      _showSnackBar('No active trip to complete.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2742),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF27A22), size: 32),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TRIPS TAB
  // ---------------------------------------------------------------------------
  Widget _buildTripsTab() {
    return ValueListenableBuilder<List<RideRequest>>(
      valueListenable: TripService().pendingRequests,
      builder: (context, pending, _) {
        if (pending.isEmpty) {
          return const Center(
            child: Text('No pending requests.', style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final req = pending[index];
            return Card(
              color: const Color(0xFF1E2742),
              child: ListTile(
                title: Text('Trip ${req.id}', style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${req.pickupName} -> ${req.dropoffName}\nPrice: ${req.price.toStringAsFixed(2)} EUR',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: TextButton(
                  onPressed: () => TripService().rejectRequest(req.id),
                  child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DRIVERS TAB
  // ---------------------------------------------------------------------------
  Widget _buildDriversTab() {
    return ValueListenableBuilder(
      valueListenable: _adminService.drivers,
      builder: (context, drivers, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return Card(
              color: const Color(0xFF1E2742),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: driver.status == 'online' ? Colors.green : Colors.grey,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(driver.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('Vehicle: ${driver.vehicle}\nStatus: ${driver.status}', style: const TextStyle(color: Colors.white54)),
                trailing: driver.status == 'offline'
                    ? TextButton(
                        onPressed: () => _adminService.activateDriver(driver.id),
                        child: const Text('Activate', style: TextStyle(color: Color(0xFFF27A22))),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // USERS TAB
  // ---------------------------------------------------------------------------
  Widget _buildUsersTab() {
    return ValueListenableBuilder(
      valueListenable: _adminService.users,
      builder: (context, users, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              color: const Color(0xFF1E2742),
              child: ListTile(
                title: Text(user.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${user.email} - Role: ${user.role}\nTrips: ${user.tripCount}', style: const TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PRICING TAB
  // ---------------------------------------------------------------------------
  Widget _buildPricingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPricingField('Base Fare (EUR)', _baseFareCtrl),
        const SizedBox(height: 16),
        _buildPricingField('Service Fee (%)', _serviceFeeCtrl),
        const SizedBox(height: 16),
        _buildPricingField('VIP Multiplier', _vipMultiplierCtrl),
        const SizedBox(height: 16),
        _buildPricingField('Airport Route Price (EUR)', _airportPriceCtrl),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _savePricing,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF27A22),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }

  /// Reads the current text controller values, validates them, and writes
  /// the updated config to AdminService so that future mock requests
  /// use the new pricing.
  void _savePricing() {
    final baseFare = double.tryParse(_baseFareCtrl.text);
    final serviceFee = double.tryParse(_serviceFeeCtrl.text);
    final vipMultiplier = double.tryParse(_vipMultiplierCtrl.text);
    final airportPrice = double.tryParse(_airportPriceCtrl.text);

    if (baseFare == null || serviceFee == null || vipMultiplier == null || airportPrice == null) {
      _showSnackBar('Invalid input. Please enter valid numbers.');
      return;
    }

    _adminService.updatePricing(AdminPricingConfig(
      baseFare: baseFare,
      serviceFeePercent: serviceFee,
      vipMultiplier: vipMultiplier,
      airportRoutePrice: airportPrice,
    ));
    _showSnackBar('Pricing updated. New mock requests will use these values.');
  }

  Widget _buildPricingField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E2742),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
