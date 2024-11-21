import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:untitled/widgets/add.dart';
import 'business.dart'; // Import your Business model
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/login.dart'; // Import the Logi
import 'package:latlong2/latlong.dart';
import 'package:untitled/pages/Map.dart';

class RegisteredBusiness extends StatefulWidget {
  @override
  _RegisteredBusinessState createState() => _RegisteredBusinessState();
}

class _RegisteredBusinessState extends State<RegisteredBusiness> {
  final DatabaseReference _acceptedBusinessRef = FirebaseDatabase.instance.ref("accepted_businesses");
  final DatabaseReference _allSpotRef = FirebaseDatabase.instance.ref("all_touristspot");
  List<Business> registeredBusinesses = [];
  List<Business> allSpots = [];
  String? spotId;
  double? averageRating;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      print("User is logged in: ${FirebaseAuth.instance.currentUser!.uid}");
    } else {
      print("User is not logged in.");
    }
    _fetchRegisteredBusinesses();
    _fetchAllSpots();
  }
  // Fetch the spotId from Firestore using the business name
  Future<void> _getSpotId(String businessName) async {
    print('Received business name: $businessName');
    if (businessName.isEmpty) {
      print('Invalid business name');
      return;
    }

    print('Fetching spotId for businessName: $businessName');
    final snapshot = await FirebaseFirestore.instance
        .collection('tourist_spots')
        .where('name', isEqualTo: businessName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      setState(() {
        spotId = doc['spotId'];  // The spotId is a field inside the document
      });

      // After getting the spotId, fetch the average rating
      if (spotId != null) {
        getAverageRating(spotId!);
      }
    } else {
      print("No spotId found for businessName: $businessName");
    }
  }

  Future<void> getAverageRating(String spotId) async {
    print('Fetching average rating for spotId: $spotId');
    final businessSnapshot = await FirebaseFirestore.instance
        .collection('tourist_spots')
        .where('spotId', isEqualTo: spotId)
        .get();

    if (businessSnapshot.docs.isNotEmpty) {
      final document = businessSnapshot.docs.first;
      setState(() {
        averageRating = document.data()['averageRating']?.toDouble() ?? 0.0; // Handle null safely
      });
      print('Average Rating: $averageRating');
    } else {
      print("No document found for spotId: $spotId");
    }
  }

  // Fetch accepted businesses from Firebase
  void _fetchRegisteredBusinesses() {
    _acceptedBusinessRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          registeredBusinesses = data.entries.map((entry) {
            final value = entry.value as Map;
            final business = Business(
              name: value['name'],
              type: value['type'],
              location: value['location'],
              latlong: value['latlong'],
              openingHours: value['openingHours'],
              closingHours: value['closingHours'],
              photos: List<String>.from(value['photos'] ?? []),
              description: value['description'] ?? '',
              userId: value['userId'] ?? '',
            );

            return business;
          }).toList();
        });
      }
    });
  }
  // Fetch accepted businesses from Firebase
  void _fetchAllSpots() {
    _allSpotRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          allSpots = data.entries.map((entry) {
            final value = entry.value as Map;
            final business = Business(
              name: value['name'],
              type: value['type'],
              location: value['location'],
              latlong: value['latlong'],
              openingHours: value['openingHours'],
              closingHours: value['closingHours'],
              photos: List<String>.from(value['photos'] ?? []),
              description: value['description'] ?? '',
              userId: value['userId'] ?? '',
            );

            return business;
          }).toList();
        });
      }
    });
  }

  // Show modal dialog with business details
  void _showBusinessDetails(Business business) {
    _getSpotId(business.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to take full height if needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)), // Optional rounded corners
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
              mainAxisSize: MainAxisSize.min,
              children: [
                if (business.photos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                      business.photos[0],
                      height: 200, // Set a fixed height
                      fit: BoxFit.cover, // Make the image cover the box
                      width: double.infinity, // Make the image stretch to full width
                    ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  business.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '${averageRating?.toStringAsFixed(1) ?? 'Loading...'}',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${business.description}'),
                const SizedBox(height: 10),
                // Type
                Row(
                  children: [
                    Icon(Icons.category, size: 20, color: Colors.grey),
                    const SizedBox(width: 8), // Spacing between icon and text
                    Text(
                      '${business.type}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Opening and Closing Hours
                Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${business.openingHours} - ${business.closingHours}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 25.0), // Adjust bottom padding as needed
                  child: GestureDetector(
                    onTap: () {
                      // Split the latlong string by space, assuming format is 'latitude longitude'
                      List<String> latlongParts = business.latlong.split(" ");

                      // Check if the string is in the correct format before proceeding
                      if (latlongParts.length == 2) {
                        try {
                          double latitude = double.parse(latlongParts[0].trim());  // Parse latitude
                          double longitude = double.parse(latlongParts[1].trim()); // Parse longitude

                          // Create a LatLng object
                          LatLng coordinates = LatLng(latitude, longitude);

                          // Pass the coordinates and business name (or title) to the MapPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPage(
                                coordinates: coordinates,
                                title: business.name, // You can pass the business name as the title
                              ),
                            ),
                          );
                        } catch (e) {
                          // Handle parsing error
                          print("Error parsing coordinates: $e");
                        }
                      } else {
                        print("Invalid latlong format.");
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            business.location,
                            style: TextStyle(fontSize: 16),
                            maxLines: 1, // Limit to 1 line
                            overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registered Businesses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              registeredBusinesses.isEmpty
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: registeredBusinesses.length,
                shrinkWrap: true, // Important for nested GridView
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling for GridView
                itemBuilder: (context, index) {
                  final business = registeredBusinesses[index];
                  return GestureDetector(
                    onTap: () => _showBusinessDetails(business),
                    child: Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (business.photos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Image.network(
                                business.photos[0],
                                width: 130,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                business.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'All Tourist Spots',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              allSpots.isEmpty
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: allSpots.length,
                shrinkWrap: true, // Important for nested GridView
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling for GridView
                itemBuilder: (context, index) {
                  final business = allSpots[index];
                  return GestureDetector(
                    onTap: () => _showBusinessDetails(business),
                    child: Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (business.photos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Image.network(
                                business.photos[0],
                                width: 130,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                business.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StatefulBuilder(
        builder: (context, setState) {
          bool isRed = false;

          return FloatingActionButton(
            onPressed: () {
              setState(() {
                isRed = !isRed;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddBusiness(
                    onRegister: (businessData) {
                      print("Business registered: $businessData");
                      Get.snackbar("Success", "Added successfully!");
                    },
                  ),
                ),
              );
            },
            backgroundColor: isRed ? Colors.black : Colors.white,
            child: Icon(
              Icons.add,
              color: isRed ? Colors.white : Colors.red,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
  }