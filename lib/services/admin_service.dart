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
  final ValueNotifier<AdminPricingConfig> pricing = ValueNotifier(AdminPricingConfig());

  void _initDemoData() {
    users.value = [
      AdminUser(id: 'u1', name: 'Alice Smith', email: 'alice@demo.com', role: 'passenger', tripCount: 12),
      AdminUser(id: 'u2', name: 'Bob Johnson', email: 'bob@demo.com', role: 'driver', tripCount: 8),
      AdminUser(id: 'u3', name: 'Charlie Dave', email: 'charlie@demo.com', role: 'passenger', tripCount: 1),
    ];

    drivers.value = [
      AdminDriver(id: 'd1', name: 'Ahmet Yilmaz', vehicle: 'Mercedes Vito', status: 'online'),
      AdminDriver(id: 'd2', name: 'Mehmet Kaya', vehicle: 'VW Transporter', status: 'offline'),
      AdminDriver(id: 'd3', name: 'Bob Johnson', vehicle: 'Renault Trafic', status: 'busy'),
    ];
  }

  void activateDriver(String id) {
    drivers.value = drivers.value.map((d) {
      if (d.id == id) return AdminDriver(id: d.id, name: d.name, vehicle: d.vehicle, status: 'online');
      return d;
    }).toList();
  }

  void updatePricing(AdminPricingConfig newConfig) {
    pricing.value = newConfig;
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
}
