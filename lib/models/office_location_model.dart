class OfficeLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? espIpAddress;
  final String? espSsid;

  OfficeLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 10.0,
    this.espIpAddress,
    this.espSsid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'espIpAddress': espIpAddress,
      'espSsid': espSsid,
    };
  }

  factory OfficeLocation.fromMap(Map<String, dynamic> map) {
    return OfficeLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radiusMeters: (map['radiusMeters'] ?? 10.0).toDouble(),
      espIpAddress: map['espIpAddress'],
      espSsid: map['espSsid'],
    );
  }
}
