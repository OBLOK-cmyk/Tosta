import 'package:flutter/material.dart';
import 'package:untitled/comments/comment_Venice.dart';
import 'package:untitled/navigate/Venice.dart';
import 'package:untitled/pages/tourist_screen.dart';
import 'package:untitled/pages/tourist_spot.dart' as touristSpot1;
import 'package:untitled/pages/Map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

// Model for Tourist Spot
class TouristSpot {
  final String id; // Unique identifier for the tourist spot
  final String name; // Name of the tourist spot
  final String description; // Description of the tourist spot
  final String imageUrl; // URL of the image for the tourist spot
  bool isFavorite; // Indicates if the spot is marked as favorite

  TouristSpot({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isFavorite = false,
  });
}

// Venice Page displaying details about the tourist spot
class VenicePage extends StatefulWidget {
  final touristSpot1.TouristSpot spot; // Tourist spot data passed to this page

  VenicePage({Key? key, required this.spot}) : super(key: key);

  @override
  _VenicePageState createState() => _VenicePageState();
}

class _VenicePageState extends State<VenicePage> {
  bool isThingsToDoExpanded = false; // State for expanding 'Things to Do' section
  bool isGoNowExpanded = false; // State for expanding 'Go Now' section
  bool isHistory = false; // State for expanding 'History' section
  late bool isFavorite; // State for favorite status
  int _userRating = 0;
  int _totalReviews = 0; // Total number of reviews for the tourist spot
  double? averageRating; // Variable to store the average rating
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  bool _hasRated = false;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<int> fetchVisitCountFromDatabase(String spotId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('tourist_spots') // Your collection name
          .doc(spotId)
          .get();

      return snapshot['visitCount'] ?? 0; // Return 0 if not found
    } catch (e) {
      print('Error fetching visit count: $e');
      return 0; // Handle the error as needed
    }
  }
  Future<void> updateVisitCountInDatabase(String spotId, int newCount) async {
    try {
      await FirebaseFirestore.instance
          .collection('tourist_spots') // Your collection name
          .doc(spotId)
          .update({'visitCount': newCount});
    } catch (e) {
      print('Error updating visit count: $e'); // Handle the error as needed
    }
  }


  @override
  void initState() {
    super.initState();
    isFavorite = widget.spot.isFavorite; // Initialize favorite status
    _checkIfUserHasRated();
    _fetchAverageRating(); // Fetch the average rating when the page loads

  }
  Future<void> _fetchAverageRating() async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('tourist_spots')
          .doc('venice_grand_canal') // Make sure this matches the document ID
          .get();

      setState(() {
        averageRating = snapshot['averageRating']?.toDouble() ?? 0.0; // Fetch and set averageRating
      });
    } catch (e) {
      print("Failed to fetch average rating: $e");
    }
  }
  // Check if the user has already rated this spot
  Future<void> _checkIfUserHasRated() async {
    String userId = _auth.currentUser!.uid;
    QuerySnapshot snapshot = await _firestore
        .collection('ratings')
        .where('spotId', isEqualTo: widget.spot.id)
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _hasRated = true;
        _userRating = snapshot.docs.first['rating'];
      });
    }
  }

  Future<void> _onStarTap(int rating) async {
    if (_hasRated) return; // Prevent further rating if the user has already rated

    setState(() {
      _userRating = rating;
      _hasRated = true;
    });

    String userId = _auth.currentUser!.uid;

    // Save the rating to Firestore
    await _firestore.collection('ratings').add({
      'rating': rating,
      'spotId': widget.spot.id,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Log rating event in Firebase Analytics
    await _analytics.logEvent(
      name: 'spot_rated',
      parameters: {
        'rating': rating,
        'spot_id': widget.spot.id,
        'user_id': userId,
      },
    );

    // Update average rating in tourist_spots
    await _updateAverageRating();
  }
// Calculate and update the average rating
  Future<void> _updateAverageRating() async {
    QuerySnapshot snapshot = await _firestore
        .collection('ratings')
        .where('spotId', isEqualTo: "1")
        .get();

    double totalRating = 0;
    int ratingCount = snapshot.docs.length;

    for (var doc in snapshot.docs) {
      totalRating += doc['rating'];
    }

    double averageRating = totalRating / ratingCount;

    await _firestore.collection('tourist_spots').doc("venice_grand_canal").update({
      'averageRating': averageRating,
    });
  }

  void _incrementVisitCount() async {
    try {
      await _firestore.collection('tourist_spots').doc(widget.spot.id).update({
        'visitCount': FieldValue.increment(1),
      });
    } catch (e) {
      print("Failed to increment visit count: $e");
    }
  }
  // Toggle favorite status
  void _onFavoriteTap() {
    setState(() {
      isFavorite = !isFavorite; // Change favorite status
      widget.spot.isFavorite = isFavorite; // Update favorite status in the tourist spot
    });
  }

  // Handle navigation bar tap events
  void _onNavBarTap(int index) {
    switch (index) {
      case 0:
      // Explore functionality can be added here
        break;
      case 1:
      // Ratings and Comments section can be added here
        break;
      case 2:
      // Navigate to Comments section
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CommentVenice(spotId: widget.spot.id)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: _onFavoriteTap, // Handle favorite button tap
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          // Image display
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(
              widget.spot.imageUrl, // Image URL for the tourist spot
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 20),
          Text(
            widget.spot.name, // Tourist spot name
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.star, // Star icon
                color: Colors.amber, // Set the color to yellow
                size: 20, // Adjust the size as needed
              ),
              SizedBox(width: 4), // Add spacing between the icon and rating text
              Text(
                '${averageRating?.toStringAsFixed(1) ?? 'Loading...'}', // Display the average rating
                style: TextStyle(color: Colors.grey, fontSize: 16), // Adjust style as needed
              ),
            ],
          ),
          SizedBox(height: 20),
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  Icons.star,
                  color: index < _userRating ? Colors.amber : Colors.grey,
                ),
                onPressed: _hasRated ? null : () => _onStarTap(index + 1),
              );
            }),
          ),

          OptionCard(
            icon: Icons.history_outlined,
            title: 'History',
            onTap: () {
              setState(() {
                isHistory = !isHistory;
                isThingsToDoExpanded = false;
                isGoNowExpanded = false;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isHistory ? 180.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'The Grand Canal in Taguig, also known as the Venice Grand Canal Mall, is famous for its Venetian-inspired architecture and gondola rides. Opened in 2015, it’s a favorite spot for both locals and tourists.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ),
          // Expandable section for 'Go Now'
          OptionCard(
            icon: Icons.restaurant_menu_outlined,
            title: 'Culinary Sights',
            onTap: () {
              setState(() {
                isThingsToDoExpanded = !isThingsToDoExpanded;
                isGoNowExpanded = false;
                isHistory = false;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isThingsToDoExpanded ? 250.0 : 0.0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCulinaryImage(
                      context,
                      imagePath: 'assets/images/tongyang.jpg',
                      title: 'Tong Yang Venice McKinley',
                      description: 'Enjoy unlimited hotpot and grill with a beautiful view of Venice Grand Canal.',
                      address: 'G/F, Venice Grand Canal Mall, McKinley Hill Dr, Taguig City 1630 Metro Manila',
                      coordinates: LatLng(14.53418, 121.05061),
                    ),
                    _buildCulinaryImage(
                      context,
                      imagePath: 'assets/images/lous.jpg',
                      title: 'Mama Lous Italian Kitchen',
                      description: 'Authentic Italian dishes served in the heart of Venice Grand Canal Mall.',
                      address: 'Mckinley Hills, Venice Grand Canal Mall, Unit A - 106, Ground Floor, Taguig, Metro Manila',
                      coordinates: LatLng(14.53434, 121.05096),
                    ),
                    _buildCulinaryImage(
                      context,
                      imagePath: 'assets/images/ramenkuroda.jpg',
                      title: 'Ramen Kuroda',
                      description: 'Specializes in various ramen styles, offering rich broths and authentic Japanese flavors.',
                      address: 'Ground Floor, Venice Grand Canal Mall, McKinley Hill, Taguig City',
                      coordinates: LatLng(14.53384, 121.05111),
                    ),
                    _buildCulinaryImage(
                      context,
                      imagePath: 'assets/images/tgi.jpg',
                      title: "TGI Fridays",
                      description: 'A casual dining chain known for its vibrant atmosphere, signature cocktails, and diverse menu.',
                      address: 'Ground Floor, Venice Grand Canal Mall, McKinley Hill, Taguig City',
                      coordinates: LatLng(14.53346, 121.05083),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expandable section for 'History'
          // Go Now Section (Navigate to VeniceMap)
          OptionCard(
            icon: Icons.directions,
            title: 'Go Now',
            onTap: () async {
              // Replace 'yourSpotId' with the actual spotId you want to update
              final spotId = 'venice_grand_canal'; // Make sure to get the correct spotId

              // Fetch the current visitCount from the database
              final currentVisitCount = await fetchVisitCountFromDatabase(spotId);

              // Increment visitCount and update in database
              await updateVisitCountInDatabase(spotId, currentVisitCount + 1);

              // When tapped, navigate to VeniceMap directly
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VeniceMap(),
                ),
              );
            },
            child: SizedBox(), // Remove the container and leave an empty child
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Ratings'),
          BottomNavigationBarItem(icon: Icon(Icons.comment), label: 'Comments'),
        ],
        onTap: _onNavBarTap, // Handle navigation bar tap
      ),
    );
  }
}

Widget _buildCulinaryImage(BuildContext context,
    {required String imagePath,
      required String title,
      required String description,
      required String address,
      required LatLng coordinates}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VeniceMap()
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(
              imagePath,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget child;

  const OptionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: onTap,
          ),
          child,
        ],
      ),
    );
  }
}
