enum TripStatus { pending, accepted, arriving, started, completed }

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
      };

  factory RideRequest.fromJson(Map<String, dynamic> json) => RideRequest(
        id: json['id'],
        passengerName: json['passengerName'],
        pickupName: json['pickupName'],
        dropoffName: json['dropoffName'],
        pickupLat: (json['pickupLat'] as num).toDouble(),
        pickupLng: (json['pickupLng'] as num).toDouble(),
        destLat: (json['destLat'] as num).toDouble(),
        destLng: (json['destLng'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        meetAndGreetName: json['meetAndGreetName'] as String?,
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
