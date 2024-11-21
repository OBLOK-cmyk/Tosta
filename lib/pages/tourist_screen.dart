import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/pages/businesspage.dart';
import 'package:untitled/pages/profile.dart';
import 'package:untitled/pages/mind_museum.dart';
import 'package:untitled/pages/tourist_spot.dart' as touristSpot;
import 'venice_page.dart';
import 'bgc.dart';
import 'macam.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/login.dart'; // Import your login page
import 'package:untitled/widgets/business.dart';
import 'viewSpot.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'Map.dart'; // Import the TouristSpot class
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class TouristSpot {
  final String id; // Required parameter
  final String name;
  final String imageUrl;
  bool isFavorite;

  TouristSpot({
    required this.id, // This must be provided
    required this.name,
    required this.imageUrl,
    this.isFavorite = false,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TouristSpotsApp());
}

class TouristSpotsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tosta',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins',
      ),
      home: TouristSpotsHome(),
      routes: {
        '/login': (context) => Login(), // Ensure you have this LoginPage class
      },
    );
  }
}

class TouristSpotsHome extends StatefulWidget {

  @override
  _TouristSpotsHomeState createState() => _TouristSpotsHomeState();
}

class _TouristSpotsHomeState extends State<TouristSpotsHome> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _acceptedBusinessRef = FirebaseDatabase.instance.ref("accepted_businesses");
  final DatabaseReference _allTouristSpotsRef = FirebaseDatabase.instance.ref('all_touristspot');
  late Future<List<Map<String, dynamic>>> favoriteSpotsFuture;
  User? get currentUser => _auth.currentUser;
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();
  List _searchResults = [];
  String _searchText = '';
  int _currentIndex = 0;
  int _userRating = 0;

  final List<touristSpot.TouristSpot> spots = [
    touristSpot.TouristSpot(
      id: '1', // Provide a unique id
      name: 'Venice Grand Canal Mall',
      imageUrl: 'assets/images/venice.jpg',
    ),
    // Add other spots here...
  ];

  List<touristSpot.TouristSpot> recentlyViewed = [];
  List<Business> registeredBusinesses = [];
  List<Map<String, dynamic>> recommendedSpots = [];
  List<String> userPlacePreferences = [];
  List<String> userFoodPreferences = [];
  List<Map<String, dynamic>> allTouristSpots = [];
  String selectedCategory = "All"; // Default category

  void _fetchAllTouristSpots() {
    DatabaseReference ref = FirebaseDatabase.instance.ref('all_touristspot');
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          allTouristSpots = data.entries.map((e) {
            return {
              'key': e.key,
              ...Map<String, dynamic>.from(e.value),
            };
          }).toList();
        });
      }
    });
  }
  Future<List<Map<String, dynamic>>> fetchTrendingAndDetails() async {
    final mergedSpots = <Map<String, dynamic>>[]; // Final list of merged spots

    try {
      // Fetch trending spots from Firestore
      final trendingSnapshot = await FirebaseFirestore.instance
          .collection('tourist_spots')
          .orderBy('visitCount', descending: true)
          .limit(3)
          .get();

      final trendingSpots = trendingSnapshot.docs.map((doc) {
        return {
          'spotId': doc.id,
          'name': doc['name'],
          'visitCount': doc['visitCount'],
        };
      }).toList();

      print('Trending Spots: $trendingSpots');

      // Fetch all spots from Realtime Database
      final allSpotsSnapshot =
      await FirebaseDatabase.instance.ref('all_touristspot').get();

      if (allSpotsSnapshot.exists) {
        final allSpotsData = (allSpotsSnapshot.value as Map).map(
              (key, value) => MapEntry(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ),
        );

        final allSpots = allSpotsData.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          return {
            'key': key,
            'name': value['name'],
            'photos': value['photos'],
            'location': value['location'],
            'description': value['description'],
            'latlong': value['latlong'],
            'openingHours': value['openingHours'],
            'closingHours': value['closingHours'],
            'type': value['type'],
          };
        }).toList();

        print('All Spots: $allSpots');

        // Merge trending spots with detailed data
        for (var trendingSpot in trendingSpots) {
          final matchingSpot = allSpots.firstWhere(
                (spot) => spot['name'] == trendingSpot['name'],
            orElse: () => {}, // Return empty map if no match
          );

          if (matchingSpot.isNotEmpty) {
            mergedSpots.add({
              'key': matchingSpot['key'],
              'spotId': trendingSpot['spotId'],
              'name': trendingSpot['name'],
              'photos': matchingSpot['photos'] ?? [],
              'visitCount': trendingSpot['visitCount'],
              'location': matchingSpot['location'] ?? 'Location not available',
              'description': matchingSpot['description'] ?? 'No description',
              'latlong': matchingSpot['latlong'] ?? 'Coordinates not available',
              'openingHours': matchingSpot['openingHours'] ?? 'N/A',
              'closingHours': matchingSpot['closingHours'] ?? 'N/A',
              'type': matchingSpot['type'] ?? 'Unknown',
            });
          }
        }
      } else {
        print('No data found in all_touristspot');
      }
    } catch (e) {
      print('Error fetching trending and detailed spots: $e');
    }

    print('Merged Trending Spots: $mergedSpots');
    return mergedSpots;
  }
  // Add a method to filter spots
  void _filterSpots() async {
    final snapshot = await FirebaseDatabase.instance.ref('all_touristspot').get();
    if (snapshot.value != null) {
      final Map<String, dynamic> spotsMap =
      Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        _searchResults = spotsMap.entries
            .where((entry) =>
            entry.value['name']
                .toLowerCase()
                .contains(_searchText.toLowerCase()))
            .map((entry) => {
          'key': entry.key, // Business key
          'name': entry.value['name'], // Spot name
          'description': entry.value['description'] ?? '',
        })
            .toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }
  Future<void> fetchUserPreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;

        setState(() {
          userPlacePreferences = List<String>.from(userData?['placePreferences'] ?? []);
          userFoodPreferences = List<String>.from(userData?['foodPreferences'] ?? []);

          print('User Place Preferences: $userPlacePreferences');
          print('User Food Preferences: $userFoodPreferences');
        });
      }
    }
  }
  Future<void> _getRecommendedSpots() async {
    await fetchUserPreferences();
    // Fetching all tourist spots
    _allTouristSpotsRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        print('Data fetched from Firebase: $data');  // Debugging log
        setState(() {
          // Initialize a list to store recommended spots
          recommendedSpots = [];

          // Loop through all tourist spots
          data.entries.forEach((entry) {
            final key = entry.key as String;
            final value = entry.value as Map;
            print('Checking spot: ${value['name']}');

            // Get the type(s) of the spot (split by commas)
            String spotType = value['type'];  // This is the comma-separated string
            List<String> spotTypes = spotType.split(',').map((e) => e.trim()).toList();

            // Check if any of the spot's types match user's preferences
            bool matchesPreference = false;

            // Check if the spot types match place or food preferences
            for (String spotType in spotTypes) {
              if (userPlacePreferences.contains(spotType) || userFoodPreferences.contains(spotType)) {
                matchesPreference = true;
                break;
              }
            }

            if (matchesPreference) {
              print('Adding to recommended: ${value['name']}');  // Debugging log
              recommendedSpots.add({

                'key': key,
                'name': value['name'],
                'type': value['type'],
                'location': value['location'],
                'latlong': value['latlong'],
                'openingHours': value['openingHours'],
                'closingHours': value['closingHours'],
                'photos': List<String>.from(value['photos'] ?? []),
                'description': value['description'] ?? '',
              });
            }
          });
        });
      } else {
        print('No data found in Firebase');  // Debugging log
      }
    });
  }



  Future<void> _getRegisteredBusinesses() async {
    _acceptedBusinessRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          registeredBusinesses = data.entries.map((entry) {
            final key = entry.key as String;
            final value = entry.value as Map;
            return Business(
              key: key,
              name: value['name'],
              type: value['type'],
              location: value['location'],
              latlong: value['latlong'],
              timestamp: value['timestamp'],
              openingHours: value['openingHours'],
              closingHours: value['closingHours'],
              photos: List<String>.from(value['photos'] ?? []),
              description: value['description'] ?? '',
              userId: value['userId'] ?? '',
            );
          }).toList();
        });
      }
      });
    }

  @override
  void initState() {
    super.initState();
    _getRecentlyViewed();
    _getFavorites();
    _getRegisteredBusinesses();
    _getRecommendedSpots();
    _fetchAllTouristSpots();
    favoriteSpotsFuture = _fetchFavoriteSpots();
    _controller = AnimationController(
      duration: Duration(seconds: 1),  // Flame pulse duration
      vsync: this, // Use this as the TickerProvider
      // Animation duration
    );

    // Define the scale animation (pulsing effect)
    _scaleAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Define the color animation (flame flicker effect)
    _colorAnimation = ColorTween(
      begin: Colors.orangeAccent, // Start with a bright orange color
      end: Colors.yellow, // End with a yellow color
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start the animation loop
    _controller.repeat(reverse: true);

  }
  // Function to remove a spot from favorites
  Future<void> _removeFromFavorites(String name) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Get the current favorites list
      final userDoc = await userDocRef.get();
      final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);

      // Remove the spot from the favorites
      favorites.remove(name);

      // Update Firestore with the new favorites list
      await userDocRef.update({'favorites': favorites});

      // Immediately update the UI by refetching the favorite spots
      setState(() {
        favoriteSpotsFuture = _fetchFavoriteSpots();
      });

    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _onStarTap(int rating) async {
    setState(() {
      _userRating = rating;
    });

    // Get the current user ID
    String userId = _auth.currentUser!.uid;

    // Save the rating to Firestore
    await _firestore.collection('ratings').add({
      'rating': rating,
      'spotId': '',
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }



  Future<void> _getRecentlyViewed() async {
    if (currentUser != null) {
      DocumentSnapshot doc = await _firestore.collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists && doc['recentlyViewed'] != null) {
        List<dynamic> viewedList = doc['recentlyViewed'];
        setState(() {
          recentlyViewed = viewedList.map((spotData) {
            return touristSpot.TouristSpot(
              id: spotData['id'], // Ensure you include the 'id'
              name: spotData['name'],
              imageUrl: spotData['imageUrl'],
              isFavorite: spotData['isFavorite'] ?? false,
            );
          }).toList();
        });
      }
    }
  }

  Future<void> _getFavorites() async {
    if (currentUser != null) {
      DocumentSnapshot doc = await _firestore.collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists && doc['favorites'] != null) {
        List<dynamic> favoritesList = doc['favorites'];
        setState(() {
          favoritesList.forEach((favorite) {
            var foundSpot = spots.firstWhere(
                  (spot) => spot.name == favorite['name'], // Update to access name
              orElse: () => touristSpot.TouristSpot(name: '', imageUrl: '', id: '', isFavorite: false), // Ensure you provide the id
            );
            if (foundSpot.name.isNotEmpty) {
              foundSpot.isFavorite = true; // Update the favorite status
            }
          });
        });
      }
    }
  }

  Future<void> _saveRecentlyViewed() async {
    if (currentUser != null) {
      List<Map<String, dynamic>> recentlyViewedData = recentlyViewed.map((spot) {
        return {
          'name': spot.name,
          'imageUrl': spot.imageUrl,
          'isFavorite': spot.isFavorite,
        };
      }).toList();

      await _firestore.collection('users')
          .doc(currentUser!.uid)
          .set({'recentlyViewed': recentlyViewedData}, SetOptions(merge: true));
    }
  }

  void _addToRecentlyViewed(touristSpot.TouristSpot spot) {
    setState(() {
      if (!recentlyViewed.contains(spot)) {
        recentlyViewed.insert(0, spot);
      } else {
        recentlyViewed.remove(spot);
        recentlyViewed.insert(0, spot);
      }
      if (recentlyViewed.length > 9) {
        recentlyViewed.removeLast();
      }
      _saveRecentlyViewed(); // Save to Firestore whenever updated
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Adjust the route as per your login page
  }
  void _navigateToBusiness() {
    // Navigate to the Business page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BusinessPage()), // Replace with your BusinessPage widget
    );
  }
  void _navigateToProfile() {
    // Navigate to the Business page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()), // Replace with your BusinessPage widget
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tourist Spots',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red.shade800,
        elevation: 0.0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu,
              color: Colors.white,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),

      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.5, // Half-width drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red.shade800,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.red.shade800),
              title: Text('Profile', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _navigateToProfile(); // Implement your profile navigation logic
              },
            ),
            ListTile(
              leading: Icon(Icons.business, color: Colors.red.shade800),
              title: Text('Business', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _navigateToBusiness(); // Implement your business navigation logic
              },
            ),
            Spacer(), // Takes the remaining space between the menu items and the logout button
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // Adds some padding to the bottom
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade800),
                title: Text('Logout', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _logout(); // Implement your logout logic
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFFF2F2F2),
      body: _currentIndex == 0 ? _buildTouristSpots() : _buildFavorites1(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red.shade800,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildTouristSpots() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _searchText.isNotEmpty ? 250 : 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim().toLowerCase();
                        if (_searchText.isEmpty) {
                          _searchResults.clear();
                        } else {
                          _filterSpots(); // Filter spots based on input
                        }
                      });
                    },
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search for a destination...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchText.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final spot = _searchResults[index];
                        return ListTile(
                          title: Text(spot['name']),
                          onTap: () {
                            final selectedBusinessKey = spot['key'] ?? '';  // Ensure null safety
                            final selectedBusinessName = spot['name'] ?? 'Unknown';  // Ensure null safety
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TouristSpotDetailsPage(businessKey: selectedBusinessKey, businessName: selectedBusinessName),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Normal content below the search box
        if (_searchText.isEmpty)
        Expanded(
          child: ListView(
            controller: _scrollController,
            children: [
              if (recentlyViewed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Recently Viewed",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 10),
              if (recentlyViewed.isNotEmpty)
                _buildRecentlyViewedSection(context),

              SizedBox(height: 20),
              // Trending Now Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value, // Apply the scale animation
                            child: Icon(
                              Icons.local_fire_department,  // Flame icon
                              color: _colorAnimation.value, // Apply the color animation (flickering effect)
                              size: 25.0,  // Icon size
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8.0), // Space between icon and text
                      Text(
                        "Trending Now",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              _buildTrendingSpotsSection(context),
              SizedBox(height: 20),
              // Registered Businesses Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "New Tourist Spot",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (registeredBusinesses.isNotEmpty)
                _buildRegisteredBusinessesSection(context),
              SizedBox(height: 20),
              // Recommended Tourist Spots based on user preferences
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recommended for You",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              _buildRecommendedSpotsSection(context),
              SizedBox(height: 20),
              // New Category-Based Tourist Spot Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Explore by Category",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              _buildCategorySelection(context),
              SizedBox(height: 20),
              _buildCategorySpotsSection(context), // Horizontal scrollable spots
              SizedBox(height: 24),

            ],
          ),
        ),
      ],
    );
  }
  Widget _buildTrendingSpotsSection(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTrendingAndDetails(), // Fetch trending spots
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final trendingSpots = snapshot.data ?? [];

        if (trendingSpots.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "No trending spots available at the moment.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(

          height: 200, // Adjust height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trendingSpots.length,
            itemBuilder: (context, index) {
              final spot = trendingSpots[index];
              // Add ranking (1, 2, 3) for each spot
              String rank = (index + 1).toString();
              return GestureDetector(
                onTap: () {
                  final selectedBusinessKey = spot['key'] ?? '';  // Ensure null safety
                  final selectedBusinessName = spot['name'] ?? 'Unknown';  // Ensure null safety
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TouristSpotDetailsPage(businessKey: selectedBusinessKey, businessName: selectedBusinessName),
                    ),
                  );
                  // Navigate to the spot details page
                },
                child: Container(
                  width: 160, // Adjust card width as needed
                  margin: EdgeInsets.symmetric(horizontal: 20.0),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0), bottom: Radius.circular(12.0)),
                            child: Image.network(
                              spot['photos'].isNotEmpty ? spot['photos'][0] : 'default_image_url',
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8.0,
                            left: 8.0,
                            child: Opacity(
                              opacity: 0.7,  // Set opacity to add transparency to the rank number
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  color: Colors.white,  // White text for contrast
                                  fontWeight: FontWeight.bold,
                                  fontSize: 125,  // Adjust the font size as needed
                                ),
                              ),

                            ),
                          ),
                          Positioned(
                            bottom: 0.0,
                            // Adjust this value to position the text correctly
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0)), // Optional: rounded corners
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Adjust blur strength as needed
                                child: Container(
                                  width: 180, // Width to match the parent container (image width)
                                  padding: EdgeInsets.all(8.0),  // Add padding around the text
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),  // Set black background with some opacity
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        spot['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.0), // Space between text lines
                                      Text(
                                        "${spot['visitCount']} visits", // Additional text
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),


                        ],
                      ),


                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  Widget _buildCategorySelection(BuildContext context) {
    final categories = ["All", "Adventure", "Relaxation", "Cultural", "Food", "Tourist", "Local", "International", "Street", "Vegan", "Seafood", "Desserts", "Beverages"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.shade800 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
// Builds the filtered tourist spots
  Widget _buildCategorySpotsSection(BuildContext context) {
    // Filter spots based on selected category
    final categorySpots = allTouristSpots.where((spot) {
      // Ensure type exists and matches the selected category
      final spotType = spot['type']?.toString()?.trim()?.toLowerCase() ?? '';
      final selectedType = selectedCategory.toLowerCase();
      print('Spot Type: $spotType, Selected Type: $selectedType'); // Debugging

      return selectedCategory == "All" || spotType.contains(selectedType);
    }).toList();

    if (categorySpots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Text(
            "No spots found for this category.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categorySpots.length,
          itemBuilder: (context, index) {
            var spot = categorySpots[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () {
                  final selectedBusinessKey = categorySpots[index]['key'];
                  final selectedBusinessName = categorySpots[index]['name'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TouristSpotDetailsPage(businessKey: selectedBusinessKey, businessName: selectedBusinessName),
                    ),
                  );
                },
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        spot['photos'].isNotEmpty ? spot['photos'][0] : 'default_image_url',
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      spot['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildRecommendedSpotsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: recommendedSpots.length,
          itemBuilder: (context, index) {
            var spot = recommendedSpots[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: (){
                  final selectedBusinessKey = recommendedSpots[index]['key'];
                  final selectedBusinessName = recommendedSpots[index]['name'];
                  print("Selected Business Key: $selectedBusinessKey"); // Debugging
                  print("Selected Business Name: $selectedBusinessName"); // Debugging log
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TouristSpotDetailsPage(businessKey: selectedBusinessKey, businessName: selectedBusinessName),
                    ),
                  );
                },

                // Navigate to the details page for the business
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        spot['photos'].isNotEmpty ? spot['photos'][0] : 'default_image_url',
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      spot['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }



  Widget _buildRecentlyViewedSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: recentlyViewed.length,
          itemBuilder: (context, index) {
            final spot = recentlyViewed[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () {
                  _addToRecentlyViewed(spot);
                  if (spot.name == 'Venice Grand Canal Mall') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VenicePage(spot: spot)),
                    );
                  }
                  if (spot.name == 'The Mind Museum') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MindMuseum(spot: spot)),
                    );
                  }
                },
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.asset(
                        spot.imageUrl,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      spot.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildRegisteredBusinessesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: registeredBusinesses.length,
          itemBuilder: (context, index) {
            final business = registeredBusinesses[index];

            // Access the timestamp from the Business object
            final businessTimestamp = DateTime.fromMillisecondsSinceEpoch(business.timestamp ?? DateTime.now().millisecondsSinceEpoch);
            // Get the current date and time
            final currentDate = DateTime.now();

            // Calculate the difference in days between current date and business timestamp
            final differenceInDays = currentDate.difference(businessTimestamp).inDays;

            // Only display businesses that were added in the last 5 days
            if (differenceInDays > 10) {
              return SizedBox.shrink(); // Skip this business if older than 5 days
            }
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: (){
                  final selectedBusinessKey = registeredBusinesses[index].key;
                  final selectedBusinessName = registeredBusinesses[index].name;

                  print("Selected Business Key: $selectedBusinessKey"); // Debugging
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TouristSpotDetailsPage(businessKey: selectedBusinessKey, businessName: selectedBusinessName),
                    ),
                  );
                },

                  // Navigate to the details page for the business
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        business.photos.isNotEmpty ? business.photos[0] : 'default_image_url',
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      business.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildFavorites1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Favorites',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchFavoriteSpots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error fetching favorites'));
              }
              final favoriteSpots = snapshot.data ?? [];
              if (favoriteSpots.isEmpty) {
                return Center(child: Text('No favorite spots yet.'));
              }
              return ListView.builder(
                itemCount: favoriteSpots.length,
                itemBuilder: (context, index) {
                  final spot = favoriteSpots[index];
                  final name = spot['name'] as String? ?? 'Unknown Spot';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TouristSpotDetailsPage(
                            businessKey: spot['key'],
                            businessName: name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              spot['photo'].isNotEmpty
                                  ? spot['photo']
                                  : 'https://via.placeholder.com/80',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          IconButton(
                            icon: Icon(Icons.favorite, color: Colors.red),
                            onPressed: () => _removeFromFavorites(name),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  Future<List<Map<String, dynamic>>> _fetchFavoriteSpots() async {
    try {
      // Fetch favorite names from Firestore
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final favoriteNames = List<String>.from(userDoc.data()?['favorites'] ?? []);

      // Fetch details of favorite spots from Realtime Database
      final allSpotsSnapshot = await FirebaseDatabase.instance.ref('all_touristspot').get();
      final allSpots = Map<String, dynamic>.from(allSpotsSnapshot.value as Map);

      // Filter spots that match the favorite names
      final favoriteSpots = allSpots.entries
          .where((entry) => favoriteNames.contains(entry.value['name']))
          .map((entry) {
        final spot = Map<String, dynamic>.from(entry.value);
        spot['key'] = entry.key; // Include key for navigation
        spot['photo'] = spot['photos']?[0] ?? '';
        return spot;
      })
          .toList();

      return favoriteSpots;
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }
}
// Function to remove a spot from the user's favorites




class TouristSpotCard extends StatelessWidget {
  final touristSpot.TouristSpot spot;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const TouristSpotCard({
    required this.spot,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Card(
        elevation: 5.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.asset(
              spot.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            spot.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          trailing: IconButton(
            icon: Icon(
              spot.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: spot.isFavorite ? Colors.red : null,
            ),
            onPressed: onFavoriteToggle,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
