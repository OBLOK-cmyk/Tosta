import 'package:flutter/material.dart';
import 'business.dart'; // Import the Business class
import 'package:fl_chart/fl_chart.dart';
import 'business_reg.dart'; // Import the BusinessReg form
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/login.dart'; // Import the Login page
import 'places_to_visit.dart'; // Import the PlacesToVisit page

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _businessRef = FirebaseDatabase.instance.ref("businesses");

  // Dashboard variables
  int totalSpots = 0; // Set this to the number of tourist spots you want to define
  int totalReviews = 0;
  final int maxSpots = 100;
  final int maxReviews = 100;
  List<Map<String, dynamic>> mostVisitedSpots = [];
  List<Map<String, dynamic>> mostReviewedSpots = [];
  List<Map<String, dynamic>> popularCategories = [];
  List<Map<String, dynamic>> topRatedSpots = [];
  List<String> touristSpotIds = []; // List to hold Tourist Spot IDs

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      print("User is logged in: ${FirebaseAuth.instance.currentUser!.uid}");
    } else {
      print("User is not logged in.");
    }
    _setupDashboardListeners(); // Setup real-time dashboard listeners
    fetchTotalSpots();
    _fetchTopRatedSpots();

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
      _fetchMostVisitedSpots();
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
  // Fetch the total tourist spots from Firebase Realtime Database
  void fetchTotalSpots() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('all_touristspot');
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      setState(() {
        totalSpots = snapshot.children.length; // Count the number of children in all_touristspot
      });
    } else {
      setState(() {
        totalSpots = 0; // If no data is found, set totalSpots to 0
      });
    }
  }
  Future<List<Map<String, dynamic>>> _fetchTopRatedSpots() async {
    // Fetch top-rated spots from Firestore
    var firestoreSnapshot = await FirebaseFirestore.instance
        .collection('tourist_spots')
        .orderBy('averageRating', descending: true)
        .limit(3)
        .get();

    List<Map<String, dynamic>> topRatedSpots = firestoreSnapshot.docs.map((doc) {
      return {
        'name': (doc['name'] is String) ? doc['name'] : 'Unknown',  // Ensure it's a string
        'averageRating': (doc['averageRating'] is num) ? doc['averageRating'] : 0,  // Ensure it's a number
        'reviewsCount': (doc['reviewsCount'] is int) ? doc['reviewsCount'] : 0,
      };
    }).toList();

    // Debug print to check fetched Firestore spots
    print('Top Rated Spots from Firestore: $topRatedSpots');

    // Fetch all spots from Firebase Realtime Database
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref('all_touristspot');

    // Fetch all spots from Realtime Database
    var databaseSnapshot = await databaseRef.get();

    if (databaseSnapshot.exists) {
      // Convert the data into a list
      var allSpots = Map<String, dynamic>.from(databaseSnapshot.value as Map<dynamic, dynamic>);

      List<Map<String, dynamic>> matchingSpots = [];

      // Loop through each Firestore top-rated spot and check if the name matches
      for (var firestoreSpot in topRatedSpots) {
        for (var spotKey in allSpots.keys) {
          var spot = allSpots[spotKey];
          if (spot['name'] == firestoreSpot['name']) {
            // If names match, add the spot to matchingSpots list
            matchingSpots.add({
              'name': spot['name'],
              'averageRating': firestoreSpot['averageRating'],
              'reviewsCount': firestoreSpot['reviewsCount'],
              'location': spot['location'],
              'description': spot['description'],
              'photos': (spot['photos'] is List && spot['photos'].isNotEmpty) ? spot['photos'][0] : '',
              'openingHours': spot['openingHours'],
              'closingHours': spot['closingHours'],
            });
          }
        }
      }

      // Debug print to check matched spots
      print('Matched Spots from Firebase Realtime Database: $matchingSpots');

      return matchingSpots; // Return the matching spots from Realtime Database
    } else {
      print('No spots found in Firebase Realtime Database.');
      return topRatedSpots; // Return the Firestore spots if no matches in Realtime Database
    }
  }
  // Method to fetch top-rated spots based on average ratings
  void _fetchMostVisitedSpots() {
    _firestore.collection('tourist_spots')
        .orderBy('visitCount', descending: true)
        .limit(3)
        .get()
        .then((spotsSnapshot) {
      mostVisitedSpots = spotsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      print('Most Visited Spots: $mostVisitedSpots'); // Debug print
      setState(() {});
    });
  }

  // Method to fetch most reviewed spots based on reviews count
  void _fetchMostReviewedSpots() {
    _firestore.collection('tourist_spots')
        .orderBy('reviewsCount', descending: true)
        .limit(3)
        .get()
        .then((reviewsSnapshot) {
      mostReviewedSpots = reviewsSnapshot.docs.map((doc) => {
        'name': doc.data()['name'],
        'averageRating': doc.data()['averageRating'],
        'reviewsCount': doc.data()['reviewsCount']
      }).toList();
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

  Widget buildReviewsAndRatingChart(List<Map<String, dynamic>> data) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40, // Space for reviews count on the left
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide the right titles
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50, // Space for spot names at the bottom
              getTitlesWidget: (value, meta) {
                int index = value.toInt();

                // Ensure the index is valid and within bounds
                if (index >= 0 && index < data.length) {
                  String placeName = data[index]['name'];
                  String truncatedName = placeName.length > 8
                      ? placeName.substring(0, 8) + '...'
                      : placeName;

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),  // Adjusted padding
                      child: Text(
                        truncatedName,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center, // Align the text to prevent overlap
                      ),
                    ),
                  );
                }
                return Container(); // Return empty container if out of bounds
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (index) {
          double reviewsCount = (data[index]['reviewsCount'] as num).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: reviewsCount,  // This is the correct parameter for the height of the bar
                color: Colors.red.shade800,
                width: 10,  // You can adjust the width of the bars here
              ),
            ],
          );
        }),
      ),
    );
  }
  BarChart buildBarChart(List<Map<String, dynamic>> data, String valueKey) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: data.map((spot) {
          return BarChartGroupData(
            x: data.indexOf(spot),
            barRods: [
              BarChartRodData(
                toY: (spot[valueKey] as num).toDouble(),
                color: Colors.red.shade800,
                width: 15,
              )
            ],
          );
        }).toList(),
      ),
    );
  }
  Widget buildHorizontalBarChart(List<Map<String, dynamic>> data, String valueKey) {
    // Find the maximum value from the data to scale the progress bars
    double maxVisitCount = data.fold<double>(0, (max, entry) {
      double value = (entry[valueKey] as num).toDouble();
      return value > max ? value : max;
    });

    return Column(
      children: data.asMap().entries.map((entry) {
        int index = entry.key;
        double value = (entry.value[valueKey] as num).toDouble();
        String placeName = entry.value['name'];

        // Limiting the name length if too long
        String truncatedName = placeName.length > 15 ? placeName.substring(0, 15) + '...' : placeName;

        // Calculate the width factor as the fraction of the max visit count
        double widthFactor = maxVisitCount > 0 ? value / maxVisitCount : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spot Name
              Container(
                width: 120, // Fixed width for the name
                child: Text(
                  truncatedName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              // Spacer between name and the bar
              const SizedBox(width: 8),
              // Bar for the Visit Count (using two colors)
              Expanded(
                child: Container(
                  height: 10, // Height of the bar
                  decoration: BoxDecoration(
                    color: Colors.red.shade100, // Light color for the remaining part
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Stack(
                    children: [
                      // This part will fill according to the visit count (red)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widthFactor,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade800, // Darker color for the progress
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      // This part remains as the light color (showing the "remaining" part)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1 - widthFactor,
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
              // Visit Count
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  // Build method for Admin widget
  @override
  Widget build(BuildContext context) {
    double progress = totalSpots / maxSpots;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          Container(
          width: 150, // Desired width
          height: 150, // Desired height
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10.0), // Add padding for spacing
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align items to the left
                children: [
                  Text(
                    '$totalSpots',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Total Spots',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 17),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '0%',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${((totalSpots / maxSpots) * 100).toInt()}%', // Convert to integer for no decimal
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                        child: LinearProgressIndicator(
                          value: progress, // Progress as a fraction (0.0 to 1.0)
                          backgroundColor: Colors.red.shade100,
                          color: Colors.red.shade800,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

          const SizedBox(width: 16),// Optional spacing
                Container(
                  width: 150, // Desired width
                  height: 150, // Desired height
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0), // Add padding for spacing
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the left
                        children: [
                          Text(
                            '$totalReviews',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total Reviews',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 17),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '0%',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${((totalReviews / maxReviews) * 100).toInt()}%', // Convert to integer for no decimal
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12), // Rounded corners
                                child: LinearProgressIndicator(
                                  value: progress, // Progress as a fraction (0.0 to 1.0)
                                  backgroundColor: Colors.red.shade100,
                                  color: Colors.red.shade800,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


              ],
            ),
        Container(
          width: 250, // Desired width
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Most Visited Spots',
                    style:  TextStyle(
                      fontSize: 16,
                    ),

                  ),
                ),
                Container(
                  height: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: buildHorizontalBarChart(
                    mostVisitedSpots.map((spot) {
                      return {
                        // Truncate spot name to a manageable length
                        'name': spot['name'].length > 5
                            ? '${spot['name'].substring(0, 12)}...'
                            : spot['name'],
                        'visitCount': spot['visitCount'],
                      };
                    }).toList(),
                    'visitCount',
                  ),
                ),
                ],
              ),
            ),
        ),

            Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Top Rated Spot',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    // Call the _buildTopRatedSpots widget here
                    _buildTopRatedSpots(),
                  ],
                )
            ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popular Categories', style: Theme.of(context).textTheme.titleLarge),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16.0),
                    child: buildBarChart(popularCategories, 'count'),
                  ),
                ],
              ),
            ),

            // New section for Top-Rated Spots

          ],
        ),
      ),
    );
  }


  Widget _buildTopRatedSpots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // FutureBuilder to load data
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 200, // Specify the height for the horizontal list
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTopRatedSpots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching top-rated spots'));
                }
                final topRatedSpots = snapshot.data ?? [];
                if (topRatedSpots.isEmpty) {
                  return Center(child: Text('No top-rated spots available.'));
                }
                return ListView.builder(
                  itemCount: topRatedSpots.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    var spot = topRatedSpots[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      padding: const EdgeInsets.all(8.0),
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5.0,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Spot image (you can use placeholder or network image)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              spot['photos'],
                              height: 80,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Spot name
                          Text(
                            spot['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Spot average rating
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              SizedBox(width: 4),
                              Text(
                                '${spot['averageRating'].toStringAsFixed(1) ?? 'Loading...'}',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}