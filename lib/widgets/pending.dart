import 'business.dart'; // Import the Business class
import 'package:flutter/material.dart';
import 'business_reg.dart'; // Import the BusinessReg form
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/login.dart'; // Import the Login page
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:untitled/pages/Map.dart';

class PendingApplications extends StatefulWidget {
  const PendingApplications({super.key});

  @override
  State<PendingApplications> createState() => _PendingApplicationsState();
}

class _PendingApplicationsState extends State<PendingApplications> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Business> pendingApplications = [];
  final DatabaseReference _businessRef = FirebaseDatabase.instance.ref("businesses");

  // Dashboard variables
  List<String> touristSpotIds = []; // List to hold Tourist Spot IDs

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      print("User is logged in: ${FirebaseAuth.instance.currentUser!.uid}");
    } else {
      print("User is not logged in.");
    }
    _fetchBusinessApplications();
  }

  // Fetch business applications from Firebase
  void _fetchBusinessApplications() {
    try {
      _businessRef.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        print("Fetched data: $data"); // Debug line

        if (data != null) {
          setState(() {
            pendingApplications = data.entries.map((entry) {
              final value = entry.value as Map;
              final key = entry.key as String;
              return Business(
                key: key, // Save key in the Business object
                name: value['name'] ?? '',
                type: value['type'] ?? '',
                location: value['location']?? '',
                latlong: value['latlong'] ?? '',
                openingHours: value['openingHours'] ?? '',
                closingHours: value['closingHours'] ?? '',
                photos: List<String>.from(value['photos'] ?? []),
                description: value['description'] ?? '',
                userId: value['userId'] ?? '',
              );
            }).toList();
          });
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching business applications: $error')),
      );
    }
  }

  void _showBusinessDetails(Business business) {
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
                ),
                // Action Buttons (Accept/Reject with "O" in the center)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Align buttons in the center
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green), // Check mark icon
                      onPressed: () {
                        _updateBusinessStatus(pendingApplications.indexOf(business), true); // Accept
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 20), // Space between the check mark and "O"
                    Text(
                      'or', // "O" in the center
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20), // Space between "O" and cross mark
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red), // Cross mark icon
                      onPressed: () {
                        _updateBusinessStatus(pendingApplications.indexOf(business), false); // Reject
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Approve and reject logic with SnackBar feedback
  void _updateBusinessStatus(int index, bool isApproved) {
    setState(() {
      final business = pendingApplications[index];
      final businessKey = _businessRef.child(business.name).key;

      if (isApproved) {
        final uniqueSpotId = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
        // Add approved business to Firebase Realtime Database
        final acceptedBusinessRef = FirebaseDatabase.instance.ref("accepted_businesses").push();
        acceptedBusinessRef.set({
          'name': business.name,
          'type': business.type,
          'location': business.location,
          'latlong': business.latlong,
          'openingHours': business.openingHours,
          'closingHours': business.closingHours,
          'photos': business.photos,
          'description': business.description,
          'timestamp': ServerValue.timestamp, // Adds a timestamp
          'userId' : business.userId,
        }).then((_) {
          // After saving to accepted, remove from pending "businesses"
          if (business.key != null) {
            _businessRef.child(business.key!).remove();
          }
        });
        // Add approved business to all_touristspot
        final allTouristSpotRef = FirebaseDatabase.instance.ref("all_touristspot").push();
        allTouristSpotRef.set({
          'name': business.name,
          'type': business.type,
          'location': business.location,
          'latlong': business.latlong,
          'openingHours': business.openingHours,
          'closingHours': business.closingHours,
          'photos': business.photos,
          'description': business.description,

        });

        final touristSpotRef = FirebaseFirestore.instance.collection('tourist_spots').doc(business.name);
        touristSpotRef.set({
          'averageRating': 0,
          'category': business.type, // Assuming type represents the category
          'name': business.name,
          'reviewsCount': 0,
          'spotId': uniqueSpotId.toString(),// Generates a unique ID for spotId
          'visitCount': 0,
        });
      }

      // Remove the application regardless of approval or rejection
      pendingApplications.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${business.name} has been ${isApproved ? 'approved' : 'rejected'}!')),
      );
    });
  }


  // Method to navigate to the login screen
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false,
    );
  }
  // Build method for Admin widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Business Applications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: pendingApplications.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showBusinessDetails(pendingApplications[index]), // Show details on tap
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // Display the business image
                              if (pendingApplications[index].photos.isNotEmpty)
                                Image.network(
                                  pendingApplications[index].photos[0],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pendingApplications[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}