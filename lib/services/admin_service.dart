import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal() {
    _initDemoData();
  }

  final ValueNotifier<List<AdminUser>> users = ValueNotifier([]);
  final ValueNotifier<List<AdminDriver>> drivers = ValueNotifier([]);
  final ValueNotifier<AdminPricingConfig> pricing = ValueNotifier(
    AdminPricingConfig(),
  );
  final ValueNotifier<List<AdminActivity>> activities = ValueNotifier([]);
  final ValueNotifier<List<RideHistoryItem>> completedTrips = ValueNotifier([]);

  void _initDemoData() {
    users.value = [
      AdminUser(
        id: 'u1',
        name: 'Ayse Demir',
        email: 'ayse.demir@demo.com',
        role: 'passenger',
        phone: '+90 532 410 07 21',
        location: 'Lara, Antalya',
        tripCount: 14,
        totalSpent: 642,
        lastTrip: 'Antalya Airport -> Lara Beach',
        createdAt: DateTime(2026, 3, 8),
      ),
      AdminUser(
        id: 'u2',
        name: 'Mehmet Kaya',
        email: 'mehmet.kaya@demo.com',
        role: 'driver',
        phone: '+90 555 018 33 42',
        location: 'Konyaalti, Antalya',
        tripCount: 86,
        totalSpent: 0,
        lastTrip: 'Belek Resort -> Antalya Airport',
        createdAt: DateTime(2026, 2, 18),
      ),
      AdminUser(
        id: 'u3',
        name: 'Elena Petrova',
        email: 'elena.petrova@demo.com',
        role: 'passenger',
        phone: '+90 533 224 18 09',
        location: 'Kemer',
        tripCount: 5,
        totalSpent: 275,
        lastTrip: 'Antalya Airport -> Kemer Marina',
        createdAt: DateTime(2026, 4, 2),
      ),
      AdminUser(
        id: 'u4',
        name: 'Daniel Weber',
        email: 'daniel.weber@demo.com',
        role: 'passenger',
        phone: '+49 151 7712 4430',
        location: 'Belek',
        tripCount: 2,
        totalSpent: 158,
        lastTrip: 'Belek Golf Hotel -> Old Town',
        createdAt: DateTime(2026, 4, 22),
        isActive: false,
      ),
    ];

    drivers.value = [
      AdminDriver(
        id: 'd1',
        name: 'Ahmet Yilmaz',
        vehicle: 'Mercedes Vito',
        plate: '07 TRF 145',
        status: 'online',
        rating: 4.9,
        completedTrips: 128,
        phone: '+90 532 100 45 67',
        currentArea: 'Antalya Airport',
      ),
      AdminDriver(
        id: 'd2',
        name: 'Mehmet Kaya',
        vehicle: 'VW Transporter',
        plate: '07 VIP 320',
        status: 'offline',
        rating: 4.7,
        completedTrips: 86,
        phone: '+90 555 018 33 42',
        currentArea: 'Konyaalti',
      ),
      AdminDriver(
        id: 'd3',
        name: 'Can Arslan',
        vehicle: 'Renault Trafic',
        plate: '07 RAY 908',
        status: 'busy',
        rating: 4.8,
        completedTrips: 73,
        phone: '+90 544 209 61 15',
        currentArea: 'Belek',
      ),
      AdminDriver(
        id: 'd4',
        name: 'Selin Acar',
        vehicle: 'Mercedes Sprinter',
        plate: '07 BUS 517',
        status: 'offline',
        isApproved: false,
        rating: 5.0,
        completedTrips: 0,
        phone: '+90 538 441 20 10',
        currentArea: 'Muratpasa',
      ),
    ];

    completedTrips.value = [
      RideHistoryItem(
        id: 't1001',
        passengerName: 'Ayse Demir',
        driverName: 'Ahmet Yilmaz',
        route: 'Antalya Airport -> Lara Beach',
        price: 48.50,
        status: 'completed',
        completedAt: DateTime.now().subtract(
          const Duration(hours: 2, minutes: 20),
        ),
      ),
      RideHistoryItem(
        id: 't1002',
        passengerName: 'Elena Petrova',
        driverName: 'Can Arslan',
        route: 'Kemer Marina -> Antalya Airport',
        price: 72.00,
        status: 'completed',
        completedAt: DateTime.now().subtract(
          const Duration(hours: 5, minutes: 5),
        ),
      ),
      RideHistoryItem(
        id: 't1003',
        passengerName: 'Daniel Weber',
        driverName: 'Mehmet Kaya',
        route: 'Belek Golf Hotel -> Old Town',
        price: 37.50,
        status: 'completed',
        completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ),
    ];

    activities.value = [
      AdminActivity(
        id: 'a1',
        title: 'Trip completed',
        description: 'Ayse Demir arrived at Lara Beach.',
        type: 'trip',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      AdminActivity(
        id: 'a2',
        title: 'Driver online',
        description: 'Ahmet Yilmaz is waiting at Antalya Airport.',
        type: 'driver',
        timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      AdminActivity(
        id: 'a3',
        title: 'User suspended',
        description: 'Daniel Weber account marked inactive for demo.',
        type: 'user',
        timestamp: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 10),
        ),
      ),
      AdminActivity(
        id: 'a4',
        title: 'Pricing ready',
        description: 'Airport transfer fare is configured for presentation.',
        type: 'pricing',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  void activateDriver(String id) {
    drivers.value = drivers.value.map((d) {
      if (d.id == id) return d.copyWith(status: 'online', isApproved: true);
      return d;
    }).toList();
    _addActivity(
      'Driver activated',
      'Driver is now available for airport transfers.',
      'driver',
    );
  }

  void deactivateDriver(String id) {
    drivers.value = drivers.value.map((d) {
      if (d.id == id) return d.copyWith(status: 'offline');
      return d;
    }).toList();
    _addActivity(
      'Driver deactivated',
      'Driver was marked offline in the demo dashboard.',
      'driver',
    );
  }

  void toggleUserStatus(String id) {
    AdminUser? changed;
    users.value = users.value.map((u) {
      if (u.id == id) {
        changed = u.copyWith(isActive: !u.isActive);
        return changed!;
      }
      return u;
    }).toList();
    if (changed != null) {
      _addActivity(
        changed!.isActive ? 'User reactivated' : 'User suspended',
        '${changed!.name} is now ${changed!.isActive ? 'active' : 'suspended'}.',
        'user',
      );
    }
  }

  void updatePricing(AdminPricingConfig newConfig) {
    pricing.value = AdminPricingConfig(
      baseFare: newConfig.baseFare,
      serviceFeePercent: newConfig.serviceFeePercent,
      vipMultiplier: newConfig.vipMultiplier,
      airportRoutePrice: newConfig.airportRoutePrice,
      lastUpdated: DateTime.now(),
    );
    _addActivity(
      'Pricing updated',
      'New demo fares will use the latest pricing settings.',
      'pricing',
    );
  }

  void resetPricing() {
    pricing.value = AdminPricingConfig();
    _addActivity(
      'Pricing reset',
      'Pricing settings returned to default demo values.',
      'pricing',
    );
  }

  /// Computes a demo price based on the current pricing configuration.
  /// Uses baseFare + airportRoutePrice as the transfer fare, then applies
  /// the service fee percentage. For VIP requests, applies the VIP multiplier.
  double computeMockPrice({bool isVip = false}) {
    final config = pricing.value;
    double fare = config.baseFare + config.airportRoutePrice;
    if (isVip) {
      fare *= config.vipMultiplier;
    }
    final serviceFee = fare * (config.serviceFeePercent / 100);
    return double.parse((fare + serviceFee).toStringAsFixed(2));
  }

  double get todayRevenue =>
      completedTrips.value.fold(0, (sum, trip) => sum + trip.price);

  double get averageDriverRating {
    if (drivers.value.isEmpty) return 0;
    final total = drivers.value.fold<double>(
      0,
      (sum, driver) => sum + driver.rating,
    );
    return double.parse((total / drivers.value.length).toStringAsFixed(1));
  }

  void addMockRequestActivity(double price) {
    _addActivity(
      'Mock request created',
      'New Antalya Airport request added (${price.toStringAsFixed(2)} EUR).',
      'trip',
    );
  }

  void addTripCompletedActivity() {
    _addActivity(
      'Trip completed',
      'Active demo trip was marked as completed.',
      'trip',
    );
  }

  void addDemoResetActivity() {
    _addActivity(
      'Demo reset',
      'Pending and active trip simulation was cleared.',
      'system',
    );
  }

  void _addActivity(String title, String description, String type) {
    activities.value = [
      AdminActivity(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: description,
        type: type,
      ),
      ...activities.value,
    ].take(8).toList();
  }
}

class RideHistoryItem {
  final String id;
  final String passengerName;
  final String driverName;
  final String route;
  final double price;
  final String status;
  final DateTime completedAt;

  RideHistoryItem({
    required this.id,
    required this.passengerName,
    required this.driverName,
    required this.route,
    required this.price,
    required this.status,
    required this.completedAt,
  });
}
