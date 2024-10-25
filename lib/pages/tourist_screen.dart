import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/pages/mind_museum.dart';
import 'package:untitled/pages/tourist_spot.dart' as touristSpot;
import 'venice_page.dart';
import 'bgc.dart';
import 'macam.dart';
import 'package:untitled/login.dart'; // Import your login page

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

class _TouristSpotsHomeState extends State<TouristSpotsHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  final ScrollController _scrollController = ScrollController();
  String _searchText = '';
  int _currentIndex = 0;

  final List<touristSpot.TouristSpot> spots = [
    touristSpot.TouristSpot(
      id: '1', // Provide a unique id
      name: 'Venice Grand Canal Mall',
      imageUrl: 'assets/images/venice.jpg',
    ),
    touristSpot.TouristSpot(
      id: '2', // Provide a unique id
      name: 'The Mind Museum',
      imageUrl: 'assets/images/mindmuse.jpg',
    ),
    touristSpot.TouristSpot(
      id: '3', // Provide a unique id
      name: 'Bonifacio High Street',
      imageUrl: 'assets/images/bonifacio.jpg',
    ),
    touristSpot.TouristSpot(
      id: '4', // Provide a unique id
      name: 'Manila American Cemetery and Memorial',
      imageUrl: 'assets/images/americancem.jpg',
    ),
    // Add other spots here...
  ];

  List<touristSpot.TouristSpot> placesToVisit = [];
  List<touristSpot.TouristSpot> recentlyViewed = [];

  @override
  void initState() {
    super.initState();
    placesToVisit.addAll(spots);
    _getRecentlyViewed();
    _getFavorites();
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

  void _toggleFavorite(touristSpot.TouristSpot spot) async {
    setState(() {
      spot.toggleFavorite(); // Toggle local favorite status
    });

    if (currentUser != null) {
      List<String> favorites = spots.where((s) => s.isFavorite).map((s) => s.name).toList();
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'favorites': favorites,
      }, SetOptions(merge: true));
    }
  }

  List<touristSpot.TouristSpot> _filteredSpots() {
    if (_searchText.isEmpty) {
      return placesToVisit;
    } else {
      return placesToVisit
          .where((spot) =>
          spot.name.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Adjust the route as per your login page
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
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: Color(0xFFF2F2F2),
      body: _currentIndex == 0 ? _buildTouristSpots() : _buildFavorites(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red.shade800,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: [
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
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: "Search for a destination...",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 18.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Places to Visit",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 13),
              ..._filteredSpots().map((spot) {
                return TouristSpotCard(
                  spot: spot,
                  onTap: () {
                    _addToRecentlyViewed(spot);
                    if (spot.name == 'Venice Grand Canal Mall') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VenicePage(spot: spot)),
                      );
                    } else if (spot.name == 'The Mind Museum') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MindMuseum(spot: spot)),
                      );
                    } else if (spot.name == 'Bonifacio High Street') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Bgc(spot: spot)),
                      );
                    } else if (spot.name == 'Manila American Cemetery and Memorial') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Macam(spot: spot)),
                      );
                    }
                  },
                  onFavoriteToggle: () => _toggleFavorite(spot),
                );
              }).toList(),
            ],
          ),
        ),
      ],
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

  Widget _buildFavorites() {
    List<touristSpot.TouristSpot> favorites = spots.where((spot) => spot.isFavorite).toList();

    return ListView(
      children: [
        if (favorites.isEmpty)
          Center(
            child: Text(
              "No favorites yet!",
              style: TextStyle(fontSize: 18),
            ),
          )
        else
          ...favorites.map((spot) {
            return TouristSpotCard(
              spot: spot,
              onTap: () {
                if (spot.name == 'Venice Grand Canal Mall') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VenicePage(spot: spot)),
                  );
                } else if (spot.name == 'The Mind Museum') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MindMuseum(spot: spot)),
                  );
                }
              },
              onFavoriteToggle: () => _toggleFavorite(spot),
            );
          }).toList(),
      ],
    );
  }
}

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