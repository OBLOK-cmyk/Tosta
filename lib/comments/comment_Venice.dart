import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

// Ensure Firebase is initialized before running the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venice Grand Canal Comments',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VenicePage(spot: TouristSpot(name: 'Venice Grand Canal', imageUrl: 'image_url_here', description: 'Description here', id: 'venice_spot_123')), // Provide a sample tourist spot here
    );
  }
}

class TouristSpot {
  final String name;
  final String imageUrl;
  final String description;
  final String id;

  TouristSpot({required this.name, required this.imageUrl, required this.description, required this.id});
}

class VenicePage extends StatefulWidget {
  final TouristSpot spot;

  VenicePage({Key? key, required this.spot}) : super(key: key);

  @override
  _VenicePageState createState() => _VenicePageState();
}

class _VenicePageState extends State<VenicePage> {
  bool isFavorite = false; // Track favorite status

  // Method to handle favorite tap
  void _onFavoriteTap() {
    setState(() {
      isFavorite = !isFavorite; // Toggle favorite status
    });
  }

  // Your existing star rating widget method
  Widget _buildStarRating() {
    // Implement your star rating widget
    return Container(); // Replace with your star rating code
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot.name), // Display tourist spot name
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _onFavoriteTap, // Handle favorite tap
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(widget.spot.imageUrl), // Tourist spot image
            SizedBox(height: 10),
            Text(widget.spot.description), // Tourist spot description
            SizedBox(height: 10),
            _buildStarRating(), // Star rating widget
            SizedBox(height: 20),
            CommentVenice(spotId: widget.spot.id), // Pass the spotId to CommentVenice
          ],
        ),
      ),
    );
  }
}

class CommentVenice extends StatefulWidget {
  final String spotId;

  const CommentVenice({Key? key, required this.spotId}) : super(key: key); // Ensure spotId is passed and required

  @override
  State<CommentVenice> createState() => _CommentVeniceState();
}

class _CommentVeniceState extends State<CommentVenice> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Venice Grand Canal Comments'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('commentsVenice') // Firestore collection for Venice comments
                  .where('spotId', isEqualTo: widget.spotId) // Query comments by spotId
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Error loading comments: ${snapshot.error}');
                  return Center(
                      child: Text('Error loading comments. Please try again.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print("No comments found for spotId: ${widget.spotId}");
                  return Center(child: Text('No comments available.'));
                }

                final comments = snapshot.data!.docs;
                print('Number of comments: ${comments.length}');

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      title: Text(comment['text']),
                      subtitle: Text(
                        comment['timestamp'] != null
                            ? comment['timestamp'].toDate().toString()
                            : 'No timestamp',
                        style: TextStyle(fontSize: 12.0),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _postComment() async {
    String commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser; // Check authentication
      if (user == null) {
        print("User is not authenticated");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to post a comment.')),
        );
        return;
      }

      try {
        await _firestore.collection('commentsVenice').add({
          'spotId': widget.spotId,
          'text': commentText,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _commentController.clear(); // Clear the text field after posting
      } catch (e) {
        print("Error posting comment: ${e.toString()}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: ${e.toString()}')),
        );
      }
    }
  }
}
