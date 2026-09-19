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

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>?)
            ?.map((role) => role.toString())
            .toList() ??
        const <String>[];
    final role = roles.contains('Driver')
        ? 'driver'
        : roles.contains('Admin') || roles.contains('SuperAdmin')
            ? 'admin'
            : 'passenger';
    final fullName = (json['fullName'] ?? '').toString().trim();
    return AdminUser(
      id: (json['id'] ?? '').toString(),
      name: fullName.isNotEmpty ? fullName : (json['userName'] ?? json['email'] ?? 'User').toString(),
      email: (json['email'] ?? '').toString(),
      role: role,
      phone: (json['phoneNumber'] ?? '').toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

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

  factory AdminDriver.fromJson(Map<String, dynamic> json) {
    return AdminDriver(
      id: (json['id'] ?? '').toString(),
      name: (json['fullName'] ?? 'Driver').toString(),
      vehicle: (json['vehicleModel'] ?? '').toString(),
      plate: (json['vehiclePlate'] ?? '').toString(),
      status: (json['status'] ?? 'offline').toString(),
      isApproved: json['isApproved'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
      phone: (json['phoneNumber'] ?? '').toString(),
      currentArea: 'Antalya',
    );
  }

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

class AdminVehicleOption {
  final String id;
  final String name;
  final String subtitle;
  final double price;
  final String time;
  final int pax;
  final int bags;
  final bool isVip;
  final String imagePath;

  AdminVehicleOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.time,
    required this.pax,
    required this.bags,
    required this.isVip,
    required this.imagePath,
  });

  String get displayPrice => '€${price.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'price': price,
        'time': time,
        'pax': pax,
        'bags': bags,
        'isVip': isVip,
        'imagePath': imagePath,
      };

  factory AdminVehicleOption.fromJson(Map<String, dynamic> json) {
    return AdminVehicleOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      time: (json['time'] ?? '~25 min').toString(),
      pax: (json['pax'] as num?)?.toInt() ?? 1,
      bags: (json['bags'] as num?)?.toInt() ?? 0,
      isVip: json['isVip'] as bool? ?? false,
      imagePath: (json['imagePath'] ?? 'assets/classs.png').toString(),
    );
  }

  AdminVehicleOption copyWith({
    String? id,
    String? name,
    String? subtitle,
    double? price,
    String? time,
    int? pax,
    int? bags,
    bool? isVip,
    String? imagePath,
  }) {
    return AdminVehicleOption(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      time: time ?? this.time,
      pax: pax ?? this.pax,
      bags: bags ?? this.bags,
      isVip: isVip ?? this.isVip,
      imagePath: imagePath ?? this.imagePath,
    );
  }
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

class AdminDashboardSummary {
  final int totalUsers;
  final int totalDrivers;
  final int pendingTrips;
  final int activeTrips;
  final int completedTrips;
  final double todayRevenue;
  final double averageDriverRating;

  const AdminDashboardSummary({
    this.totalUsers = 0,
    this.totalDrivers = 0,
    this.pendingTrips = 0,
    this.activeTrips = 0,
    this.completedTrips = 0,
    this.todayRevenue = 0,
    this.averageDriverRating = 0,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalDrivers: (json['totalDrivers'] as num?)?.toInt() ?? 0,
      pendingTrips: (json['pendingTrips'] as num?)?.toInt() ?? 0,
      activeTrips: (json['activeTrips'] as num?)?.toInt() ?? 0,
      completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0,
      averageDriverRating:
          (json['averageDriverRating'] as num?)?.toDouble() ?? 0,
    );
  }
}
