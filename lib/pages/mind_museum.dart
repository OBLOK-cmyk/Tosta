import 'package:flutter/material.dart';
import 'package:untitled/comments/comment_Venice.dart';
import 'package:untitled/navigate/Venice.dart';
import 'package:untitled/pages/tourist_screen.dart';
import 'package:untitled/pages/tourist_spot.dart' as touristSpot1;
import 'package:untitled/pages/Map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
class MindMuseum extends StatefulWidget {
  final touristSpot1.TouristSpot spot; // Tourist spot data passed to this page

  MindMuseum({Key? key, required this.spot}) : super(key: key);

  @override
  _MindMuseumPageState createState() => _MindMuseumPageState();
}

class _MindMuseumPageState extends State<MindMuseum> {
  bool isThingsToDoExpanded = false; // State for expanding 'Things to Do' section
  bool isGoNowExpanded = false; // State for expanding 'Go Now' section
  bool isHistory = false; // State for expanding 'History' section
  late bool isFavorite; // State for favorite status
  double _currentRating = 0.0; // Current rating given by the user
  double _averageRating = 0.0; // Average rating of the tourist spot
  int _totalReviews = 0; // Total number of reviews for the tourist spot
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  @override
  void initState() {
    super.initState();
    isFavorite = widget.spot.isFavorite; // Initialize favorite status
    _loadUserRating(); // Load the user's previous rating when initializing
    _fetchAverageRating(); // Fetch the average rating when the page is initialized
  }

  // Method to save rating to Firestore
  void _saveRating(double rating) async {
    try {
      User? user = _auth.currentUser; // Get the current user
      if (user != null) {
        // Query Firestore to check if the user has already rated this spot
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

        _fetchAverageRating(); // Refresh the average rating after saving
        _updateTouristSpotData(); // Update the tourist spot data after rating
      } else {
        // Prompt user to log in if they are not authenticated
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You need to log in to rate.")),
        );
      }
    } catch (e) {
      print("Failed to save rating: $e");
      // Show error message in case of failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving your rating. Please try again.")),
      );
    }
  }

  // Load user's previous rating for this spot
  void _loadUserRating() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Query Firestore for the user's rating
      QuerySnapshot ratingSnapshot = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: user.uid)
          .where('spotId', isEqualTo: widget.spot.id)
          .get();

      if (ratingSnapshot.docs.isNotEmpty) {
        setState(() {
          _currentRating = ratingSnapshot.docs.first['rating']; // Set current rating
        });
      }
    }
  }

  // Fetch average rating for this tourist spot
  void _fetchAverageRating() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('ratings')
          .where('spotId', isEqualTo: widget.spot.id)
          .get();

      double totalRating = 0.0;
      int totalCount = snapshot.docs.length;

      snapshot.docs.forEach((doc) {
        totalRating += doc['rating']; // Accumulate ratings
      });

      setState(() {
        _totalReviews = totalCount; // Update total reviews count
        _averageRating = totalCount > 0 ? totalRating / totalCount : 0.0; // Calculate average rating
      });
    } catch (e) {
      print("Failed to fetch average rating: $e");
    }
  }

  // Toggle favorite status
  void _onFavoriteTap() {
    setState(() {
      isFavorite = !isFavorite; // Change favorite status
      widget.spot.isFavorite = isFavorite; // Update favorite status in the tourist spot
    });
  }

  // Build star rating UI
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
                _currentRating = index + 1; // Set current rating based on the star clicked
              });
            },
          );
        }));
  }

  // Method to submit the rating
  void _submitRating() async {
    try {
      // Create a new document in the tourist_spots collection with a generated ID
      DocumentReference newDocumentRef = await _firestore.collection('tourist_spots').add({
        'averageRating': _averageRating,
        'category': 'Cultural',
        'name': 'Venice Grand Canal Mall', // Keeping the name as specified
        'reviewsCount': _totalReviews,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rating submitted successfully! Document ID: ${newDocumentRef.id}")),
      );
    } catch (e) {
      print("Failed to submit rating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting your rating. Please try again.")),
      );
    }
  }

  // Update tourist spot data for total reviews
  void _updateTouristSpotData() async {
    try {
      await _firestore.collection('tourist_spots').doc('mind_museum').update({
        'totalReviews': FieldValue.increment(1), // Increment total reviews
      });
    } catch (e) {
      print("Failed to update tourist spot data: $e");
    }
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          // Average rating display
          Text(
            "Average Rating: ${_averageRating.toStringAsFixed(1)}",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 10),
          // Star rating UI
          _buildStarRating(),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _submitRating(); // Call submit rating method
            },
            child: Text("Submit Rating"),
          ),
          SizedBox(height: 20),
          // Toggle expandable sections for details
          ExpansionTile(
            title: Text('Things to Do'),
            children: <Widget>[
              // List of activities can be added here
              Text("Activity 1"),
              Text("Activity 2"),
              Text("Activity 3"),
            ],
          ),
          ExpansionTile(
            title: Text('Go Now'),
            children: <Widget>[
              // Navigation options can be added here
              Text("Get directions to the spot"),
            ],
          ),
          ExpansionTile(
            title: Text('History'),
            children: <Widget>[
              // Historical context can be added here
              Text("Brief history of the spot"),
            ],
          ),
        ],
      ),
      // Navigation bar
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
