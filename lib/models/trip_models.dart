enum TripStatus { pending, accepted, arriving, started, completed, cancelled }

TripStatus tripStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'accepted':
      return TripStatus.accepted;
    case 'arriving':
      return TripStatus.arriving;
    case 'started':
      return TripStatus.started;
    case 'completed':
      return TripStatus.completed;
    case 'cancelled':
      return TripStatus.cancelled;
    case 'pending':
    default:
      return TripStatus.pending;
  }
}

class RideRequest {
  final String id;
  final String passengerName;
  final String pickupName;
  final String dropoffName;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  final double price;
  final String? meetAndGreetName;
  final List<String>? customStops;
  final bool? requiresGuide;
  final String? status;
  final String? driverName;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? vehicleType;

  RideRequest({
    required this.id,
    required this.passengerName,
    required this.pickupName,
    required this.dropoffName,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    required this.price,
    this.meetAndGreetName,
    this.customStops,
    this.requiresGuide,
    this.status,
    this.driverName,
    this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.vehicleType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'passengerName': passengerName,
        'pickupName': pickupName,
        'dropoffName': dropoffName,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destLat': destLat,
        'destLng': destLng,
        'price': price,
        'meetAndGreetName': meetAndGreetName,
        'customStops': customStops,
        'requiresGuide': requiresGuide,
        'status': status,
        'driverName': driverName,
        'createdAt': createdAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'vehicleType': vehicleType,
      };

  factory RideRequest.fromJson(Map<String, dynamic> json) => RideRequest(
        id: json['id'].toString(),
        passengerName: json['passengerName'] ?? 'Passenger',
        pickupName: json['pickupName'] ?? '',
        dropoffName: json['dropoffName'] ?? '',
        pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 0,
        pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 0,
        destLat: ((json['destLat'] ?? json['dropoffLat']) as num?)?.toDouble() ?? 0,
        destLng: ((json['destLng'] ?? json['dropoffLng']) as num?)?.toDouble() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        meetAndGreetName: json['meetAndGreetName'] as String?,
        customStops: (json['customStops'] as List<dynamic>?)?.map((e) => e as String).toList(),
        requiresGuide: json['requiresGuide'] as bool?,
        status: json['status'] as String?,
        driverName: json['driverName'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
        acceptedAt: DateTime.tryParse((json['acceptedAt'] ?? '').toString()),
        completedAt: DateTime.tryParse((json['completedAt'] ?? '').toString()),
        vehicleType: json['vehicleType'] as String?,
      );
}

class TripSession {
  final RideRequest request;
  TripStatus status;
  double driverLat;
  double driverLng;
  int eta;

  TripSession({
    required this.request,
    required this.status,
    required this.driverLat,
    required this.driverLng,
    required this.eta,
  });
}
