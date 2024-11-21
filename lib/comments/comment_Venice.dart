import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  final FirebaseAuth _auth = FirebaseAuth
      .instance; // Firebase Authentication instance


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('comments')
                  .where('spotId', isEqualTo: widget.spotId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade800),
                  ));
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

                return ListView.separated(
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => Divider(),
                  // Horizontal line between comments
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final userId = comment['userId'] ?? 'Anonymous';
                    final message = comment['message'] ?? 'No message';
                    final timestamp = comment['timestamp'];

                    // Safely check for imageUrl
                    final data = comment.data() as Map<String,
                        dynamic>?; // Cast to Map
                    final imageUrl = data != null &&
                        data.containsKey('imageUrl')
                        ? data['imageUrl']
                        : null;

                    // Mask user ID
                    String maskedUserId = _maskUserId(userId);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(Icons.account_circle),
                          // Keep profile icon as is
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  maskedUserId,
                                  style: TextStyle(fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow
                                      .ellipsis, // Prevent overflow
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                timestamp != null
                                    ? _timeAgo(timestamp.toDate())
                                    : 'No timestamp',
                                style: TextStyle(
                                    fontSize: 12.0, color: Colors.grey),
                              ),
                            ],
                          ),
                          subtitle: Text(message),
                        ),
                        // Display the uploaded photo after the ListTile
                        // Safely display the uploaded photo after the ListTile
                        (imageUrl != null && imageUrl.isNotEmpty)
                            ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            // Apply border radius
                            child: Image.network(
                              imageUrl,
                              width: 250,
                              height: 250,
                              fit: BoxFit
                                  .cover, // Ensure the image fits nicely within the box
                            ),
                          ),
                        )
                            : SizedBox(), // If no image, show nothing
                      ],
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }

// Function to convert the timestamp to a human-readable format like "2 hours ago"
  String _timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays /
          365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays /
          30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1
          ? 's'
          : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1
          ? 's'
          : ''} ago';
    } else {
      return 'Just now';
    }
  }

// Function to mask the userId
  String _maskUserId(String userId) {
    if (userId.length <= 2)
      return userId; // In case userId is too short, return as is.
    return userId[0] + '*****' + userId[userId.length - 1];
  }
}