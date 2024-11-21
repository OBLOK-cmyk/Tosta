import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:untitled/widgets/business_reg.dart';

class BusinessPage extends StatefulWidget {
  @override
  _BusinessPageState createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userId;
  bool hasBusiness = false;
  bool hasPendingBusiness = false;

  String? businessName;
  String? businessDescription;
  String? businessLocation;
  String? businessPhoto;
  double? averageRating;
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    _checkUserBusiness();
  }

  Future<void> _checkUserBusiness() async {
    // Get current user ID
    userId = _auth.currentUser?.uid;

    if (userId == null) {
      print("User is not logged in.");
      return;
    }

    // Get all businesses from Firebase Realtime Database (no userId filter)
    DatabaseReference businessRef = _database.ref().child(
        'accepted_businesses');
    DataSnapshot acceptedSnapshot = await businessRef.get();

    if (acceptedSnapshot.exists) {
      print("Snapshot exists, checking businesses...");
      setState(() {
        hasBusiness = false; // Default to no business
      });

      var businessesData = acceptedSnapshot.value as Map?;
      if (businessesData != null) {
        businessesData.forEach((key, value) {
          // Debugging: Print each business info
          print("Business Key: $key, Business Info: $value");

          // Check if the userId matches
          if (value['userId'] == userId) {
            print("Found user's business: ${value['name']}");
            setState(() {
              hasBusiness = true;
              businessName = value['name'];
              businessDescription = value['description'];
              businessLocation = value['location'];
              businessPhoto =
              value['photos'][0]; // Assuming there's at least one photo

              // Fetch the average rating and comments (if needed)
              _fetchBusinessDetailsFromFirestore(businessName);
            });
          }
        });
      }
      // Check pending businesses
      DatabaseReference pendingRef = _database.ref().child('businesses');
      DataSnapshot pendingSnapshot = await pendingRef.get();

      if (pendingSnapshot.exists && !hasBusiness) {
        var pendingBusinesses = pendingSnapshot.value as Map?;
        pendingBusinesses?.forEach((key, value) {
          if (value['userId'] == userId) {
            setState(() {
              hasPendingBusiness = true;
              businessName = value['name'];
            });
          }
        });
      }
    }
  }

  Future<void> _fetchBusinessDetailsFromFirestore(String? businessName) async {
    if (businessName == null) return;

    // Fetch the spotId and averageRating from Firestore using the business name
    var touristSpotSnapshot = await _firestore.collection('tourist_spots')
        .where('name', isEqualTo: businessName)
        .get();

    if (touristSpotSnapshot.docs.isNotEmpty) {
      var touristSpotData = touristSpotSnapshot.docs.first.data();
      String spotId = touristSpotData['spotId'];
      dynamic avgRating = touristSpotData['averageRating'];

      // If the averageRating is null or not available, display a default message
      setState(() {
        averageRating = avgRating != null ? avgRating : 0.0; // Default to 0.0 if null
      });

      // Fetch the comments using the spotId from the Firestore comments collection
      _fetchComments(spotId);
    }
  }
  Future<void> _fetchComments(String spotId) async {
    try {
      var commentsSnapshot = await _firestore
          .collection('comments')
          .where('spotId', isEqualTo: spotId)
          .orderBy('timestamp', descending: true)
          .get();

      if (commentsSnapshot.docs.isNotEmpty) {
        setState(() {
          // Map each comment to include userId, message, timestamp, and optional imageUrl
          comments = commentsSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            return {
              'userId': data['userId'] ?? 'Anonymous',
              'message': data['message'] ?? '',
              'timestamp': data['timestamp'],
              'imageUrl': data['imageUrl'] ?? null, // Default to null if missing
            };
          }).toList();
        });
      } else {
        setState(() {
          comments = []; // No comments found
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
      setState(() {
        comments = []; // Set to empty list on error
      });
    }
  }


  void _registerBusiness() {
    // Navigate to the business registration page
    Navigator.pushNamed(context, '/register_business');
  }
  Widget _buildUsersBusiness(BuildContext context) {
    if (hasBusiness) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Details Card
          Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Image
                  businessPhoto != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16), // Adjust the radius as needed
                    child: Image.network(
                      businessPhoto!,
                      width: double.infinity, // Make it responsive
                      height: 200, // Set a fixed height
                      fit: BoxFit.cover, // Adjust the image scaling
                    ),
                  )
                      : Placeholder(fallbackHeight: 200),
                  SizedBox(height: 16),
                  Text(
                    businessName ?? "Business Name",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 8),
                  // Average Rating
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '${averageRating?.toStringAsFixed(1) ?? 'Loading...'}',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    businessDescription ?? "Business Description",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$businessLocation',
                          style: TextStyle(fontSize: 16),
                          maxLines: 1, // Limit to 1 line
                          overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),
                  Divider(height: 20, thickness: 1, color: Colors.grey),
                  SizedBox(height: 16),
                  // Comments Section Header
                  Text(
                    "Comments",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // Comments Section
                  comments.isEmpty
                      ? Text('No comments available.')
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final userId = comment['userId'] ?? 'Anonymous';
                      final message = comment['message'] ?? 'No message';
                      final timestamp = comment['timestamp'];
                      final imageUrl = comment.containsKey('imageUrl')
                          ? comment['imageUrl']
                          : null;

                      // Mask user ID
                      String maskedUserId = _maskUserId(userId);

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: Icon(Icons.account_circle, size: 40),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        maskedUserId,
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      timestamp != null
                                          ? _timeAgo((timestamp as Timestamp).toDate())
                                          : 'No timestamp',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(message),
                              ),
                              // Optional Image
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      );
    }  else if (hasPendingBusiness) {
      return Center(
        child: Text(
          "Your business is pending for approval.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Center(
        child: Text(
          "Don't have a business yet to showcase.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
// Function to mask the userId
  String _maskUserId(String userId) {
    if (userId.length <= 2) return userId; // Handle short IDs gracefully
    return userId[0] + '*****' + userId[userId.length - 1];
  }

// Function to format time difference
  String _timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Business",
            style: TextStyle(color: Colors.white),
      ),
        backgroundColor: Colors.red.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildUsersBusiness(context), // Call the new widget here
      ),
      floatingActionButton: !(hasBusiness || hasPendingBusiness)
          ? FloatingActionButton(
        onPressed:() => Get.to(() => BusinessReg(
          onRegister: (businessData) {
            print("Business registered: $businessData");
            Get.snackbar("Success", "Business registered successfully!");
          },
        )),
        child: Icon(Icons.add,
            color: Colors.white),
        backgroundColor: Colors.red.shade800,
      )
          : null, // Only show FAB if user doesn't have a business
    );
  }
}