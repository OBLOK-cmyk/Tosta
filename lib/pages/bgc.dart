import 'package:flutter/material.dart';
import 'package:untitled/comments/comment_Venice.dart';
import 'package:untitled/navigate/Venice.dart';
import 'package:untitled/pages/tourist_screen.dart';
import 'package:untitled/pages/tourist_spot.dart' as touristSpot1;
import 'package:untitled/pages/Map.dart'; // This import is retained
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/comments/comment_Venice.dart';

class TouristSpot {
  final String id; // Add an 'id' field
  final String name;
  final String description;
  final String imageUrl;
  bool isFavorite;

  TouristSpot({
    required this.id, // Include id in the constructor
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isFavorite = false,
  });
}

class Bgc extends StatefulWidget {
  final touristSpot1.TouristSpot spot;

  Bgc({Key? key, required this.spot}) : super(key: key);

  @override
  _BgcPageState createState() => _BgcPageState();
}

class _BgcPageState extends State<Bgc> {
  bool isThingsToDoExpanded = false;
  bool isGoNowExpanded = false;
  bool isHistory = false;
  late bool isFavorite;
  double _currentRating = 0.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.spot.isFavorite;
    _loadUserRating(); // Load the user's previous rating when initializing
  }

  void _saveRating(double rating) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Check if a rating already exists
        QuerySnapshot ratingSnapshot = await _firestore
            .collection('ratings')
            .where('userId', isEqualTo: user.uid)
            .where('spotId', isEqualTo: widget.spot.id)
            .get();

        if (ratingSnapshot.docs.isNotEmpty) {
          // Update existing rating
          String docId = ratingSnapshot.docs.first.id;
          await _firestore.collection('ratings').doc(docId).update({
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          // Add new rating
          await _firestore.collection('ratings').add({
            'userId': user.uid,
            'spotId': widget.spot.id,
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You need to log in to rate.")),
        );
      }
    } catch (e) {
      print("Failed to save rating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving your rating. Please try again.")),
      );
    }
  }

  void _loadUserRating() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot ratingSnapshot = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: user.uid)
          .where('spotId', isEqualTo: widget.spot.id)
          .get();

      if (ratingSnapshot.docs.isNotEmpty) {
        setState(() {
          _currentRating = ratingSnapshot.docs.first['rating'];
        });
      }
    }
  }

  void _onFavoriteTap() {
    setState(() {
      isFavorite = !isFavorite;
      widget.spot.isFavorite = isFavorite;
    });
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _currentRating = index + 1;
              _saveRating(_currentRating); // Save rating when a star is clicked
            });
          },
        );
      }),
    );
  }

  void _onNavBarTap(int index) {
    switch (index) {
      case 0:
      // Explore functionality
        break;
      case 1:
      // Ratings and Comments section
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
            onPressed: _onFavoriteTap,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(
              widget.spot.imageUrl,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 20),

          Text(
            widget.spot.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),

          // Star Rating Widget
          _buildStarRating(),
          SizedBox(height: 20),

          // History Section
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

          // Culinary Sights Section
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

          // Go Now Section (Navigate to VeniceMap)
          OptionCard(
            icon: Icons.directions,
            title: 'Go Now',
            onTap: () {
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
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Ratings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.comment_outlined),
            label: 'Comments',
          ),
        ],
        onTap: _onNavBarTap,
      ),
    );
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
