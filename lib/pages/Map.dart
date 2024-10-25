import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Now App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),

    );
  }
}

class MapPage extends StatefulWidget {
  final LatLng coordinates;
  final String title;

  MapPage({required this.coordinates, required this.title});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng _currentLocation = LatLng(0, 0);// Updated coordinates
  StreamSubscription<LocationData>? _locationSubscription;
  final MapController _mapController = MapController();
  List<LatLng> _polylinePoints = [];
  List<List<LatLng>> _allRoutes = [];
  bool _isMapReady = false;
  bool _isMapInteracted = false;
  bool _isFollowingRoute = false;
  String _eta = '';
  String _selectedMode = 'driving';
  double _distance = 0.0;
  bool _loading = true;
  bool _avoidHighways = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _startPulsatingAnimation();
  }

  void _checkLocationPermission() async {
    permission.PermissionStatus status = await permission.Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      print('Location permission denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();

    // Check if location service is enabled
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        print('Location service not enabled');
        return;
      }
    }

    // Check for permission
    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print('Location permission denied');
        return;
      }
    }

    // Get the current location data
    LocationData currentLocationData;
    try {
      currentLocationData = await location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      return;
    }

    // Update the current location
    setState(() {
      _currentLocation = LatLng(currentLocationData.latitude!, currentLocationData.longitude!);
      _loading = false;
    });

    // Listen to location changes
    _locationSubscription = location.onLocationChanged.listen((LocationData newData) {
      setState(() {
        _currentLocation = LatLng(newData.latitude!, newData.longitude!);
        if (_isMapReady && !_isMapInteracted && !_isFollowingRoute) {
          _mapController.move(_currentLocation, 15.0);
        }
      });

      _fetchRoute(); // Fetch the route after updating location
    });
  }

  Future<void> _fetchRoute() async {
    final start = '${_currentLocation.longitude},${_currentLocation.latitude}';
    final end = '${widget.coordinates.longitude},${widget.coordinates.latitude}';

    String url = 'http://router.project-osrm.org/route/v1/$_selectedMode/$start;$end?overview=full&geometries=geojson&steps=true';

    // Apply user preference for avoiding highways
    if (_avoidHighways && _selectedMode == 'walking') {
      url += '&exclude=motorway'; // OSRM syntax to avoid highways
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'].isNotEmpty) {
          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          final double duration = data['routes'][0]['duration'];
          _distance = data['routes'][0]['distance'] / 1000; // Distance in kilometers

          setState(() {
            _polylinePoints = coordinates.map((point) {
              return LatLng(point[1], point[0]);
            }).toList();
            _isFollowingRoute = true;
            _eta = _formatDuration(duration);
          });
        }
      } else {
        print('Failed to load the route, Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching the route: $e');
    }
  }

  String _formatDuration(double duration) {
    final int minutes = (duration / 60).floor();
    final int seconds = (duration % 60).floor();
    return '$minutes min ${seconds}s';
  }
  void _savePreferences() async {
    setState(() {
      _avoidHighways = !_avoidHighways;
      _fetchRoute(); // Refetch route with updated preference
    });
  }
  void _startPulsatingAnimation() {
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _isAnimating = !_isAnimating; // Toggle animation state every second
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
  Widget _buildModeIcon(String mode) {
    switch (mode) {
      case 'driving':
        return Icon(Icons.directions_car_rounded, color: Colors.blue); // Rounded car icon
      case 'walking':
        return Icon(Icons.directions_run_rounded, color: Colors.green); // Rounded walking icon
      case 'biking':
        return Icon(Icons.directions_bike_rounded, color: Colors.orange); // Rounded biking icon
      default:
        return Icon(Icons.directions_car_rounded); // Default icon (rounded car)
    }
  }
  Widget _buildCurrentLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsating effect
        AnimatedContainer(
          duration: Duration(milliseconds: 1500),
          width: 50 + (_isAnimating ? 10 : 0),  // Pulsate between 50 and 60 width
          height: 50 + (_isAnimating ? 10 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.3),  // Light blue pulsating effect
          ),
        ),
        // Border circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blueAccent,  // Border color
              width: 4,
            ),
            color: Colors.white,  // Background inside the border
          ),
          child: Icon(
            Icons.my_location,
            color: Colors.blue,  // Main icon color
            size: 30,            // Icon size inside the border
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Listener(
        onPointerDown: (_) {
          _isMapInteracted = true;
        },
        onPointerUp: (_) {
          _isMapInteracted = false;
        },
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,  // Corrected parameter name
            initialZoom: 15.0,                 // Corrected parameter name
            onMapReady: () {
              // Mark the map as ready and move the map
              setState(() {
                _isMapReady = true;
              });
              if (_currentLocation != LatLng(0, 0)) {
                _mapController.move(_currentLocation, 15.0);  // Move the map when ready
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            if (_polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylinePoints,
                    strokeWidth: 15.0,
                    color: Colors.grey.withOpacity(0.8),
                  ),
                  Polyline(
                    points: _polylinePoints,
                    strokeWidth: 10.0,  // Main polyline thickness
                    color: _getPolylineColor(),  // Main route color (your chosen color)
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  width: 60,  // Adjust width
                  height: 60, // Adjust height
                  child: _buildCurrentLocationMarker(),

                ),
                Marker(
                  point: widget.coordinates,
                  child: Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),

            // Display ETA and Distance
            Positioned(
              left: 0, // Positioned at the left edge
              right: 0, // Positioned at the right edge (to make it span horizontally)
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(10),
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, -3), // Shadow direction
                    ),
                  ],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 22),
                        children: [
                          if (_eta.isNotEmpty) // Check if ETA is not empty
                            TextSpan(
                              text: ' $_eta ', // ETA value
                              style: TextStyle(color: Colors.red), // Red color for ETA
                            ),
                          if (_distance > 0) // Check if Distance is greater than 0
                            TextSpan(
                              text: '(${_distance.toStringAsFixed(2)} km)', // Distance in parentheses
                              style: TextStyle(color: Colors.black), // Black color for Distance
                            ),
                        ],
                      ),
                    ), // Push the 'Fastest route now' text to the bottom
                    Text(
                      ' Fastest route now', // The new text
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green, // You can change the color and size as per your design
                        // Make it bold to stand out
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Travel Mode Selector
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: _selectedMode,
                  items: <String>['driving', 'walking', 'biking']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                          children: [
                            // Add the corresponding rounded icon for each mode
                            _buildModeIcon(value),
                            SizedBox(width: 8), // Space between icon and text
                            Text(value),
                          ]
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMode = newValue!;
                      _fetchRoute();
                    });
                  },
                ),
              ),
            ),
            // Floating Action Button
            Positioned(
              right: 16,
              bottom: 180, // Adjust this to place it before the box at the bottom
              child: FloatingActionButton(
                onPressed: () {
                  _mapController.move(_currentLocation, 15.0);
                },
                child: Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Color _getPolylineColor() {
    // This function returns the color based on the traffic condition
    return Colors.green.shade800; // Simplified for now
  }
}
