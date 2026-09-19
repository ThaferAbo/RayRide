import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_models.dart';
import '../models/trip_models.dart';
import 'auth_service.dart';
import 'http_client_factory.dart'
    if (dart.library.io) 'http_client_factory_native.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal() {
    _initDemoData();
    loadVehicleOptions();
  }

  static const _vehicleOptionsKey = 'admin_vehicle_options';

  final ValueNotifier<List<AdminUser>> users = ValueNotifier([]);
  final ValueNotifier<List<AdminDriver>> drivers = ValueNotifier([]);
  final ValueNotifier<AdminPricingConfig> pricing = ValueNotifier(
    AdminPricingConfig(),
  );
  final ValueNotifier<List<AdminVehicleOption>> vehicleOptions = ValueNotifier(
    [],
  );
  final ValueNotifier<List<AdminActivity>> activities = ValueNotifier([]);
  final ValueNotifier<List<RideHistoryItem>> completedTrips = ValueNotifier([]);
  final ValueNotifier<List<RideRequest>> trips = ValueNotifier([]);
  final ValueNotifier<AdminDashboardSummary> summary = ValueNotifier(
    const AdminDashboardSummary(),
  );
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final AuthService _authService = AuthService();
  final http.Client _httpClient = createHttpClient();

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

    vehicleOptions.value = [
      AdminVehicleOption(
        id: 'economy-sedan',
        name: 'Economy Sedan',
        subtitle: 'Toyota Corolla or similar',
        price: 25,
        time: '~25 min',
        pax: 3,
        bags: 2,
        isVip: false,
        imagePath: 'assets/toytaCorolla0.png',
      ),
      AdminVehicleOption(
        id: 'comfort-plus',
        name: 'Comfort Plus',
        subtitle: 'Mercedes E-Class',
        price: 38,
        time: '~25 min',
        pax: 3,
        bags: 3,
        isVip: false,
        imagePath: 'assets/classs.png',
      ),
      AdminVehicleOption(
        id: 'vip-vito',
        name: 'VIP Vito',
        subtitle: 'Mercedes-Benz Vito',
        price: 55,
        time: '~25 min',
        pax: 6,
        bags: 6,
        isVip: true,
        imagePath: 'assets/vito.png',
      ),
      AdminVehicleOption(
        id: 'sprinter',
        name: 'Mercedes Sprinter',
        subtitle: 'VIP Group Shuttle',
        price: 75,
        time: '~30 min',
        pax: 12,
        bags: 12,
        isVip: true,
        imagePath: 'assets/sprinter7.png',
      ),
      AdminVehicleOption(
        id: 'escalade',
        name: 'Cadillac Escalade',
        subtitle: 'Premium Luxury SUV',
        price: 90,
        time: '~25 min',
        pax: 4,
        bags: 4,
        isVip: true,
        imagePath: 'assets/cadil5.png',
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

  Future<void> loadBackendData() async {
    isLoading.value = true;
    error.value = null;
    try {
      final responses = await Future.wait([
        _httpClient.get(
          Uri.parse('${_authService.baseUrl}/api/v1/Admin/Users'),
          headers: await _headers(),
        ),
        _httpClient.get(
          Uri.parse('${_authService.baseUrl}/api/v1/Drivers'),
          headers: await _headers(),
        ),
        _httpClient.get(
          Uri.parse('${_authService.baseUrl}/api/v1/Trips'),
          headers: await _headers(),
        ),
        _httpClient.get(
          Uri.parse('${_authService.baseUrl}/api/v1/Admin/DashboardSummary'),
          headers: await _headers(),
        ),
      ]);

      for (final response in responses) {
        _throwIfFailed(response);
      }

      final usersJson = jsonDecode(responses[0].body) as List<dynamic>;
      users.value = usersJson
          .whereType<Map<String, dynamic>>()
          .map(AdminUser.fromJson)
          .toList();

      final driversJson = jsonDecode(responses[1].body) as List<dynamic>;
      drivers.value = driversJson
          .whereType<Map<String, dynamic>>()
          .map(AdminDriver.fromJson)
          .toList();

      final tripsJson = jsonDecode(responses[2].body) as List<dynamic>;
      final loadedTrips = tripsJson
          .whereType<Map<String, dynamic>>()
          .map(RideRequest.fromJson)
          .toList();
      trips.value = loadedTrips;
      completedTrips.value = loadedTrips
          .where((trip) => trip.status == 'completed')
          .map(
            (trip) => RideHistoryItem(
              id: trip.id,
              passengerName: trip.passengerName,
              driverName: trip.driverName ?? 'Unassigned',
              route: '${trip.pickupName} -> ${trip.dropoffName}',
              price: trip.price,
              status: trip.status ?? 'completed',
              completedAt: trip.completedAt ?? DateTime.now(),
            ),
          )
          .toList();

      summary.value = AdminDashboardSummary.fromJson(
        jsonDecode(responses[3].body) as Map<String, dynamic>,
      );

      activities.value = [
        AdminActivity(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: 'Backend data loaded',
          description: 'Dashboard refreshed from RayRide API.',
          type: 'system',
        ),
        ...activities.value,
      ].take(8).toList();
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDriverStatusBackend(String id, String status) async {
    final response = await _httpClient.put(
      Uri.parse('${_authService.baseUrl}/api/v1/Drivers/$id/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    _throwIfFailed(response);
    final updated = AdminDriver.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    drivers.value = drivers.value
        .map((driver) => driver.id == updated.id ? updated : driver)
        .toList();
    await loadBackendData();
  }

  Future<void> updateDriverApprovalBackend(String id, bool isApproved) async {
    final response = await _httpClient.put(
      Uri.parse('${_authService.baseUrl}/api/v1/Drivers/$id/approval'),
      headers: await _headers(),
      body: jsonEncode({'isApproved': isApproved}),
    );
    _throwIfFailed(response);
    final updated = AdminDriver.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    drivers.value = drivers.value
        .map((driver) => driver.id == updated.id ? updated : driver)
        .toList();
    await loadBackendData();
  }

  Future<void> cancelTripBackend(String id) async {
    final response = await _httpClient.put(
      Uri.parse('${_authService.baseUrl}/api/v1/Trips/$id/cancel'),
      headers: await _headers(),
    );
    _throwIfFailed(response);
    await loadBackendData();
  }

  Future<void> completeTripBackend(String id) async {
    final response = await _httpClient.put(
      Uri.parse('${_authService.baseUrl}/api/v1/Trips/$id/complete'),
      headers: await _headers(),
    );
    _throwIfFailed(response);
    await loadBackendData();
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

  double get todayRevenue => summary.value.todayRevenue > 0
      ? summary.value.todayRevenue
      : completedTrips.value.fold(0, (sum, trip) => sum + trip.price);

  double get averageDriverRating {
    if (summary.value.averageDriverRating > 0) {
      return summary.value.averageDriverRating;
    }
    if (drivers.value.isEmpty) return 0;
    final total = drivers.value.fold<double>(
      0,
      (sum, driver) => sum + driver.rating,
    );
    return double.parse((total / drivers.value.length).toStringAsFixed(1));
  }

  Future<void> addVehicleOption(AdminVehicleOption option) async {
    final response = await _httpClient.post(
      Uri.parse('${_authService.baseUrl}/api/v1/Admin/VehicleOptions'),
      headers: await _headers(),
      body: jsonEncode(_vehicleOptionPayload(option)),
    );
    _throwIfFailed(response);
    await loadVehicleOptions();
    _addActivity(
      'Car added',
      '${option.name} is now available to passengers.',
      'pricing',
    );
  }

  Future<void> updateVehicleOption(AdminVehicleOption option) async {
    final response = await _httpClient.put(
      Uri.parse(
        '${_authService.baseUrl}/api/v1/Admin/VehicleOptions/${option.id}',
      ),
      headers: await _headers(),
      body: jsonEncode(_vehicleOptionPayload(option)),
    );
    _throwIfFailed(response);
    await loadVehicleOptions();
    _addActivity(
      'Car updated',
      '${option.name} now costs ${option.displayPrice}.',
      'pricing',
    );
  }

  Future<void> deleteVehicleOption(String id) async {
    AdminVehicleOption? removed;
    for (final vehicle in vehicleOptions.value) {
      if (vehicle.id == id) {
        removed = vehicle;
        break;
      }
    }
    final response = await _httpClient.delete(
      Uri.parse('${_authService.baseUrl}/api/v1/Admin/VehicleOptions/$id'),
      headers: await _headers(),
    );
    _throwIfFailed(response);
    await loadVehicleOptions();
    _addActivity(
      'Car removed',
      '${removed?.name ?? 'Vehicle'} is no longer shown to passengers.',
      'pricing',
    );
  }

  Future<void> loadVehicleOptions() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('${_authService.baseUrl}/api/v1/Admin/VehicleOptions'),
        headers: await _headers(),
      );
      _throwIfFailed(response);
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map(AdminVehicleOption.fromJson)
            .where((vehicle) => vehicle.name.trim().isNotEmpty)
            .toList();
        if (_vehicleListsDiffer(vehicleOptions.value, loaded)) {
          vehicleOptions.value = loaded;
        }
        await _saveVehicleOptions();
        return;
      }
    } catch (_) {
      // Fall back to the last browser cache below if the shared API is down.
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vehicleOptionsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map(AdminVehicleOption.fromJson)
            .where((vehicle) => vehicle.name.trim().isNotEmpty)
            .toList();
        if (_vehicleListsDiffer(vehicleOptions.value, loaded)) {
          vehicleOptions.value = loaded;
        }
      }
    } catch (_) {
      // Keep default demo cars if stored data is malformed.
    }
  }

  bool _vehicleListsDiffer(
    List<AdminVehicleOption> current,
    List<AdminVehicleOption> next,
  ) {
    if (current.length != next.length) {
      return true;
    }
    for (var i = 0; i < current.length; i++) {
      if (jsonEncode(current[i].toJson()) != jsonEncode(next[i].toJson())) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveVehicleOptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _vehicleOptionsKey,
      jsonEncode(
        vehicleOptions.value.map((vehicle) => vehicle.toJson()).toList(),
      ),
    );
  }

  Map<String, dynamic> _vehicleOptionPayload(AdminVehicleOption option) => {
    'name': option.name,
    'subtitle': option.subtitle,
    'price': option.price,
    'time': option.time,
    'pax': option.pax,
    'bags': option.bags,
    'isVip': option.isVip,
    'imagePath': option.imagePath,
  };

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception(
      response.body.isNotEmpty
          ? response.body
          : 'Request failed with status ${response.statusCode}.',
    );
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
