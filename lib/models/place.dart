// lib/models/place.dart

class Place {
  final String id; // generated from lat-lon or place_id if available
  final String name; // short title
  final String displayName; // full address
  final double lat;
  final double lon;
  final String? type;

  Place({
    required this.id,
    required this.name,
    required this.displayName,
    required this.lat,
    required this.lon,
    this.type,
  });

  factory Place.fromNominatimJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0.0;
    final display = (json['display_name'] ?? '').toString();
    final title = (json['name'] ??
            (json['display_name'] != null ? (json['display_name'] as String).split(',').first : '')) ??
        '';
    final id = json['place_id']?.toString() ?? '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
    return Place(
      id: id,
      name: title,
      displayName: display,
      lat: lat,
      lon: lon,
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'displayName': displayName,
        'lat': lat,
        'lon': lon,
        'type': type,
      };

  factory Place.fromJson(Map<String, dynamic> j) {
    return Place(
      id: j['id'] ?? '${j['lat']},${j['lon']}',
      name: j['name'] ?? '',
      displayName: j['displayName'] ?? '',
      lat: (j['lat'] is num) ? (j['lat'] as num).toDouble() : double.tryParse(j['lat'].toString()) ?? 0,
      lon: (j['lon'] is num) ? (j['lon'] as num).toDouble() : double.tryParse(j['lon'].toString()) ?? 0,
      type: j['type'],
    );
  }
}
