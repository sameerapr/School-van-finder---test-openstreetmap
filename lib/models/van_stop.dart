import 'package:latlong2/latlong.dart';

class VanStop {
  final String name;
  final String shortName;
  final LatLng location;
  final bool isSchool;

  VanStop({
    required this.name,
    required this.shortName,
    required this.location,
    this.isSchool = true,
  });
}
