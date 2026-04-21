class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final int tripCount;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.tripCount = 0,
    this.isActive = true,
  });
}

class AdminDriver {
  final String id;
  final String name;
  final String vehicle;
  final String status; // "online", "offline", "busy"

  AdminDriver({
    required this.id,
    required this.name,
    required this.vehicle,
    this.status = "offline",
  });
}

class AdminPricingConfig {
  double baseFare;
  double serviceFeePercent;
  double vipMultiplier;
  double airportRoutePrice;

  AdminPricingConfig({
    this.baseFare = 10.0,
    this.serviceFeePercent = 10.0,
    this.vipMultiplier = 1.5,
    this.airportRoutePrice = 35.0,
  });
}
