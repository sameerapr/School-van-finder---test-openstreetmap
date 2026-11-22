import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:openstreetmap/models/driver_control_panel.dart';

import 'models/van_stop.dart';
import 'widgets/parent_control_panel.dart';

class SchoolVanTrackerScreen extends StatefulWidget {
  const SchoolVanTrackerScreen({super.key});

  @override
  State<SchoolVanTrackerScreen> createState() => _SchoolVanTrackerScreenState();
}

class _SchoolVanTrackerScreenState extends State<SchoolVanTrackerScreen> {
  final MapController _mapController = MapController();

  final List<VanStop> _morningStops = [
    VanStop(
      name: "Wariyapola (Start / Depot)",
      shortName: "Wariyapola",
      location: const LatLng(7.6242, 80.2447),
      isSchool: false,
    ),
    VanStop(
      name: "President's Girls' College",
      shortName: "President's Girls'",
      location: const LatLng(7.4892, 80.3635),
    ),
    VanStop(
      name: "Wayamba Royal College",
      shortName: "Wayamba Royal",
      location: const LatLng(7.4845, 80.3672),
    ),
    VanStop(
      name: "Maliyadeva Boys' College",
      shortName: "Maliyadeva Boys'",
      location: const LatLng(7.4812, 80.3648),
    ),
    VanStop(
      name: "Maliyadeva Model School",
      shortName: "Maliyadeva Model",
      location: const LatLng(7.4765, 80.3615),
    ),
    VanStop(
      name: "Maliyadeva Balika Vidyalaya",
      shortName: "Maliyadeva Girls'",
      location: const LatLng(7.4738, 80.3589),
    ),
    VanStop(
      name: "Sir John Kothalawala College",
      shortName: "Sir John College",
      location: const LatLng(7.4695, 80.3552),
    ),
  ];

  bool _isDriverMode = false;
  bool _isMorningTrip = true;
  bool _isSelectingHomeOnMap = false;
  bool _isChildPickedUp =
      false; // Morning සහ Evening දෙකේදීම Picked Up status එක

  late VanStop _selectedChildSchool;
  LatLng _parentHomeLocation = const LatLng(7.5550, 80.3010);

  late LatLng _vanLocation;
  String _currentPlaceName = "Loading place...";
  String _targetEstTime = "Calculating...";
  String _targetEstDist = "";

  List<LatLng> _fullRoutePoints = [];
  List<LatLng> _activeTargetRoutePoints = [];
  bool _isLoading = true;

  List<VanStop> get _activeStops =>
      _isMorningTrip ? _morningStops : _morningStops.reversed.toList();

  List<VanStop> get _schoolsOnly =>
      _morningStops.where((stop) => stop.isSchool).toList();

  // දැනට Van එක යන්නේ පාසලටද (true) නැත්නම් ගෙදරටද (false) යන්න තීරණය කිරීම
  bool get _isTargetSchool {
    if (_isMorningTrip) {
      return _isChildPickedUp; // උදේ: Pick කළාට පසු -> School
    } else {
      return !_isChildPickedUp; // හවස: Pick කරන්න කලින් -> School, Pick කළාට පසු -> Home
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedChildSchool = _schoolsOnly[0];
    _vanLocation = _activeStops[0].location;
    _loadAllMapData();
  }

  Future<void> _loadAllMapData() async {
    setState(() => _isLoading = true);

    await _fetchFullVanRoute();
    await _updateVanLiveStatus();

    setState(() => _isLoading = false);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _fullRoutePoints.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([
              ..._fullRoutePoints,
              _parentHomeLocation,
              _vanLocation,
            ]),
            padding: const EdgeInsets.only(
              top: 130,
              bottom: 280,
              left: 40,
              right: 40,
            ),
          ),
        );
      }
    });
  }

  Future<void> _fetchFullVanRoute() async {
    String coordsString = _activeStops
        .map((s) => '${s.location.longitude},${s.location.latitude}')
        .join(';');

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordsString'
      '?overview=full&geometries=geojson',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List<dynamic> coords =
            data['routes'][0]['geometry']['coordinates'];
        setState(() {
          _fullRoutePoints = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Full Route Error: $e");
    }
  }

  Future<void> _updateVanLiveStatus() async {
    await _getPlaceName(_vanLocation);

    // _isTargetSchool true නම් පාසලටත්, false නම් නිවසටත් දුර සහ කාලය ගණනය කරයි
    LatLng targetPoint = _isTargetSchool
        ? _selectedChildSchool.location
        : _parentHomeLocation;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${_vanLocation.longitude},${_vanLocation.latitude};'
      '${targetPoint.longitude},${targetPoint.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final route = data['routes'][0];
        final List<dynamic> coords = route['geometry']['coordinates'];

        double distKm = route['distance'].toDouble() / 1000;
        int mins = ((route['duration'].toDouble() / 60) * 1.2).round();

        setState(() {
          _activeTargetRoutePoints = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
          _targetEstDist = "${distKm.toStringAsFixed(1)} km";
          _targetEstTime = mins <= 1
              ? "Arriving Now (1 min)"
              : (mins >= 60
                    ? "${mins ~/ 60} hr ${mins % 60} mins"
                    : "$mins mins");
        });
      }
    } catch (e) {
      debugPrint("Target Route Error: $e");
    }
  }

  Future<void> _getPlaceName(LatLng pos) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2'
      '&lat=${pos.latitude}&lon=${pos.longitude}',
    );

    try {
      final res = await http.get(
        url,
        headers: {'User-Agent': 'com.mobappdev.schoolvan'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final address = data['address'];
        String road = address['road'] ?? '';
        String area =
            address['suburb'] ??
            address['town'] ??
            address['village'] ??
            address['city'] ??
            '';
        setState(() {
          _currentPlaceName = [
            road,
            area,
          ].where((s) => s.isNotEmpty).join(', ');
          if (_currentPlaceName.isEmpty)
            _currentPlaceName = "Kurunegala - Wariyapola Rd";
        });
      }
    } catch (_) {
      setState(() => _currentPlaceName = "Kurunegala - Wariyapola Rd");
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng tappedPoint) {
    if (_isDriverMode) {
      setState(() => _vanLocation = tappedPoint);
      _updateVanLiveStatus();
    } else if (_isSelectingHomeOnMap) {
      setState(() {
        _parentHomeLocation = tappedPoint;
        _isSelectingHomeOnMap = false;
      });
      _updateVanLiveStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Parent Home Location Updated!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color activeLineColor = _isTargetSchool
        ? Colors.blueAccent
        : Colors.green.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDriverMode ? 'Driver Mode' : 'Parent Tracker'),
        backgroundColor: _isDriverMode ? Colors.indigo : Colors.amber.shade800,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Text(
                _isDriverMode ? "Driver" : "Parent",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _isDriverMode,
                activeColor: Colors.white,
                onChanged: (val) {
                  setState(() {
                    _isDriverMode = val;
                    _isSelectingHomeOnMap = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 1. OpenStreetMap
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _vanLocation,
                    initialZoom: 12.0,
                    onTap: _onMapTapped,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mobappdev.schoolvan',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (_fullRoutePoints.isNotEmpty)
                          Polyline(
                            points: _fullRoutePoints,
                            strokeWidth: 4.0,
                            color: Colors.blueGrey.withOpacity(0.4),
                          ),
                        if (_activeTargetRoutePoints.isNotEmpty)
                          Polyline(
                            points: _activeTargetRoutePoints,
                            strokeWidth: 5.5,
                            color: activeLineColor,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        ..._schoolsOnly.map((school) {
                          bool isChildSchool =
                              school.name == _selectedChildSchool.name;
                          return Marker(
                            point: school.location,
                            width: 115,
                            height: 65,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isChildSchool
                                        ? Colors.blueAccent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isChildSchool
                                          ? Colors.white
                                          : Colors.black26,
                                    ),
                                  ),
                                  child: Text(
                                    school.shortName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isChildSchool
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.school,
                                  color: isChildSchool
                                      ? Colors.blueAccent
                                      : Colors.grey.shade700,
                                  size: isChildSchool ? 30 : 22,
                                ),
                              ],
                            ),
                          );
                        }),
                        Marker(
                          point: _parentHomeLocation,
                          width: 90,
                          height: 65,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Your Home",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.home,
                                color: Colors.green.shade700,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                        Marker(
                          point: _vanLocation,
                          width: 52,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(
                              Icons.airport_shuttle,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 2. Morning / Evening Selector
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isMorningTrip = true;
                                  _isChildPickedUp =
                                      false; // උදේ: තවම Home එකෙන් pick කර නැත
                                  _vanLocation = _morningStops.first.location;
                                });
                                _loadAllMapData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isMorningTrip
                                      ? Colors.amber.shade700
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    "Morning (To School)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isMorningTrip
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isMorningTrip = false;
                                  _isChildPickedUp = false; // හවස: තවම School එකෙන් pick කර නැත
                                  _vanLocation = _morningStops.last.location;
                                });
                                _loadAllMapData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isMorningTrip
                                      ? Colors.indigo
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    "Evening (To Home)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_isMorningTrip
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tap Instruction Banner
                if (_isSelectingHomeOnMap || _isDriverMode)
                  Positioned(
                    top: 68,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isDriverMode
                            ? Colors.indigo.shade900
                            : Colors.green.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isDriverMode
                            ? "📍 Tap anywhere on the map to move the School Van"
                            : "🏠 Tap anywhere on the map to set your Home location",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // 3. Separate Widgets භාවිතා කර ඇති Bottom Control Panel එක
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _isDriverMode
                          ? DriverControlPanel(
                              isMorningTrip: _isMorningTrip,
                              isChildPickedUp: _isChildPickedUp,
                              activeStops: _activeStops,
                              currentPlaceName: _currentPlaceName,
                              onTogglePickupStatus: () {
                                setState(
                                  () => _isChildPickedUp = !_isChildPickedUp,
                                );
                                _updateVanLiveStatus();
                              },
                              onJumpToStop: (selectedStop) {
                                setState(
                                  () => _vanLocation = selectedStop.location,
                                );
                                _mapController.move(_vanLocation, 14.5);
                                _updateVanLiveStatus();
                              },
                            )
                          : ParentControlPanel(
                              isMorningTrip: _isMorningTrip,
                              isChildPickedUp: _isChildPickedUp,
                              isSelectingHomeOnMap: _isSelectingHomeOnMap,
                              selectedChildSchool: _selectedChildSchool,
                              schoolsOnly: _schoolsOnly,
                              currentPlaceName: _currentPlaceName,
                              targetEstTime: _targetEstTime,
                              targetEstDist: _targetEstDist,
                              onSchoolChanged: (newSchool) {
                                setState(
                                  () => _selectedChildSchool = newSchool,
                                );
                                _updateVanLiveStatus();
                              },
                              onToggleSetHome: () {
                                setState(
                                  () => _isSelectingHomeOnMap =
                                      !_isSelectingHomeOnMap,
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
