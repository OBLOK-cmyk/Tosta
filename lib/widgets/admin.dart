import 'package:flutter/material.dart';
import 'business.dart'; // Import the Business class
import 'business_reg.dart'; // Import the BusinessReg form
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/login.dart'; // Import the Login page
import 'places_to_visit.dart'; // Import the PlacesToVisit page

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Business> pendingApplications = [];
  final DatabaseReference _businessRef = FirebaseDatabase.instance.ref("businesses");

  // Dashboard variables
  int totalSpots = 4; // Set this to the number of tourist spots you want to define
  int totalReviews = 0;
  List<Map<String, dynamic>> topRatedSpots = [];
  List<Map<String, dynamic>> mostReviewedSpots = [];
  List<Map<String, dynamic>> popularCategories = [];
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
    _setupDashboardListeners(); // Setup real-time dashboard listeners
  }

  // Fetch business applications from Firebase
  void _fetchBusinessApplications() {
    try {
      _businessRef.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          setState(() {
            pendingApplications = data.entries.map((entry) {
              final value = entry.value as Map;
              return Business(
                name: value['name'],
                type: value['type'],
                location: value['location'],
                openingHours: value['openingHours'],
                closingHours: value['closingHours'],
                photos: List<String>.from(value['photos'] ?? []),
                description: value['description'] ?? '',
                phoneNumber: value['phoneNumber'],
                email: value['email'],
                socialMedia: value['socialMedia'],
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

  // Setup real-time dashboard listeners
  void _setupDashboardListeners() {
    // Listen for changes in reviews count
    _firestore.collection('tourist_spots').snapshots().listen((snapshot) {
      totalReviews = snapshot.docs.length;
      touristSpotIds = snapshot.docs.map((doc) => doc.id).toList(); // Get Tourist Spot IDs// Update total reviews count based on document length
      print('Total Reviews: $totalReviews'); // Debug print
      setState(() {});

      // Re-calculate top-rated spots and most reviewed spots based on ratings
      _fetchTopRatedSpots();
      _fetchMostReviewedSpots();
    });

    // Listen for popular categories
    _firestore.collection('tourist_spots').snapshots().listen((snapshot) {
      Map<String, int> categoryCount = {};
      for (var doc in snapshot.docs) {
        String category = doc['category'];
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      popularCategories = categoryCount.entries
          .map((entry) => {'category': entry.key, 'count': entry.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      print('Popular Categories: $popularCategories'); // Debug print
      setState(() {});
    });
  }

  // Method to fetch top-rated spots based on average ratings
  void _fetchTopRatedSpots() {
    _firestore.collection('tourist_spots')
        .orderBy('averageRating', descending: true)
        .limit(5)
        .get()
        .then((spotsSnapshot) {
      topRatedSpots = spotsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      print('Top Rated Spots: $topRatedSpots'); // Debug print
      setState(() {});
    });
  }

  // Method to fetch most reviewed spots based on reviews count
  void _fetchMostReviewedSpots() {
    _firestore.collection('tourist_spots')
        .orderBy('reviewsCount', descending: true)
        .limit(5)
        .get()
        .then((reviewsSnapshot) {
      mostReviewedSpots = reviewsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      print('Most Reviewed Spots: $mostReviewedSpots'); // Debug print
      setState(() {});
    });
  }

  // Method to save a review and update average rating
  void _saveReview(String touristSpotId, double rating) {
    _firestore.collection('tourist_spots').doc(touristSpotId).get().then((doc) {
      if (doc.exists) {
        double currentRating = doc['averageRating'] ?? 0.0;
        int currentCount = doc['reviewsCount'] ?? 0;
        double newAverageRating = ((currentRating * currentCount) + rating) / (currentCount + 1);

        // Update the tourist spot document
        _firestore.collection('tourist_spots').doc(touristSpotId).update({
          'averageRating': newAverageRating,
          'reviewsCount': currentCount + 1,
        });
      }
    });
  }

  // Approve and reject logic with SnackBar feedback
  void _updateBusinessStatus(int index, bool isApproved) {
    setState(() {
      final businessName = pendingApplications[index].name;
      // Update Firebase based on approval/rejection
      if (isApproved) {
        // Add approved business to your Firestore (or another reference)
        _firestore.collection('businesses').add({
          'name': pendingApplications[index].name,
          'type': pendingApplications[index].type,
          'location': pendingApplications[index].location,
          'openingHours': pendingApplications[index].openingHours,
          'closingHours': pendingApplications[index].closingHours,
          'photos': pendingApplications[index].photos,
          'description': pendingApplications[index].description,
          'phoneNumber': pendingApplications[index].phoneNumber,
          'email': pendingApplications[index].email,
          'socialMedia': pendingApplications[index].socialMedia,
        });
      }
      // Remove the application regardless of approval or rejection
      pendingApplications.removeAt(index); // Simulate action by removing from the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$businessName has been ${isApproved ? 'approved' : 'rejected'}!')),
      );
    });
  }

  // Method to add a new business application from registration
  void addBusinessApplication(Map<String, dynamic> businessData) {
    setState(() {
      pendingApplications.add(Business(
        name: businessData['name'],
        type: businessData['type'],
        location: businessData['location'],
        openingHours: businessData['openingHours'],
        closingHours: businessData['closingHours'],
        photos: List<String>.from(businessData['photos'] ?? []),
        description: businessData['description'] ?? '',
        phoneNumber: businessData['phoneNumber'],
        email: businessData['email'],
        socialMedia: businessData['socialMedia'],
      ));
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

  // Navigate to the Places to Visit screen
  void _navigateToPlacesToVisit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlacesToVisit()),
    );
  }

  // Build method for Admin widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tourist Spots: $totalSpots', style: Theme.of(context).textTheme.titleLarge),
            Text('Total Reviews: $totalReviews', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Top Rated Tourist Spots:', style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ListView.builder(
                itemCount: topRatedSpots.length,
                itemBuilder: (context, index) {
                  var spot = topRatedSpots[index];
                  return ListTile(
                    title: Text('${spot['name']} - ${spot['averageRating']} stars'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Most Reviewed Tourist Spots:', style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ListView.builder(
                itemCount: mostReviewedSpots.length,
                itemBuilder: (context, index) {
                  var spot = mostReviewedSpots[index];
                  return ListTile(
                    title: Text('${spot['name']} - ${spot['reviewsCount']} reviews'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Popular Categories:', style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ListView.builder(
                itemCount: popularCategories.length,
                itemBuilder: (context, index) {
                  var category = popularCategories[index];
                  return ListTile(
                    title: Text('${category['category']} - ${category['count']}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Pending Business Applications:', style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ListView.builder(
                itemCount: pendingApplications.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(pendingApplications[index].name),
                      subtitle: Text(pendingApplications[index].description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => _updateBusinessStatus(index, true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _updateBusinessStatus(index, false),
                          ),
                        ],
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
