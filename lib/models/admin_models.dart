class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String location;
  final int tripCount;
  final double totalSpent;
  final String lastTrip;
  final DateTime createdAt;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.location = '',
    this.tripCount = 0,
    this.totalSpent = 0,
    this.lastTrip = 'No trips yet',
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? location,
    int? tripCount,
    double? totalSpent,
    String? lastTrip,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      tripCount: tripCount ?? this.tripCount,
      totalSpent: totalSpent ?? this.totalSpent,
      lastTrip: lastTrip ?? this.lastTrip,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AdminDriver {
  final String id;
  final String name;
  final String vehicle;
  final String plate;
  final String status; // "online", "offline", "busy"
  final bool isApproved;
  final double rating;
  final int completedTrips;
  final String phone;
  final String currentArea;

  AdminDriver({
    required this.id,
    required this.name,
    required this.vehicle,
    this.plate = '',
    this.status = "offline",
    this.isApproved = true,
    this.rating = 5.0,
    this.completedTrips = 0,
    this.phone = '',
    this.currentArea = '',
  });

  AdminDriver copyWith({
    String? id,
    String? name,
    String? vehicle,
    String? plate,
    String? status,
    bool? isApproved,
    double? rating,
    int? completedTrips,
    String? phone,
    String? currentArea,
  }) {
    return AdminDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      vehicle: vehicle ?? this.vehicle,
      plate: plate ?? this.plate,
      status: status ?? this.status,
      isApproved: isApproved ?? this.isApproved,
      rating: rating ?? this.rating,
      completedTrips: completedTrips ?? this.completedTrips,
      phone: phone ?? this.phone,
      currentArea: currentArea ?? this.currentArea,
    );
  }
}

class AdminPricingConfig {
  double baseFare;
  double serviceFeePercent;
  double vipMultiplier;
  double airportRoutePrice;
  DateTime lastUpdated;

  AdminPricingConfig({
    this.baseFare = 10.0,
    this.serviceFeePercent = 10.0,
    this.vipMultiplier = 1.5,
    this.airportRoutePrice = 35.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}

class AdminActivity {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime timestamp;

  AdminActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
