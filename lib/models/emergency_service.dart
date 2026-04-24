class EmergencyService {
  final String id;
  final String name;
  final String type; // e.g., hospital, police, ambulance, towing, puncture
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? address;
  double? distance; // Current distance from user

  EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.address,
    this.distance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory EmergencyService.fromMap(Map<String, dynamic> map) {
    return EmergencyService(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
    );
  }
}
