import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Import to use File
import 'package:firebase_storage/firebase_storage.dart';

class LeaveReviewPage extends StatefulWidget {
  final String? spotId; // The ID of the spot being reviewed
  final String? spotName; // Spot name to search for

  const LeaveReviewPage({required this.spotId, this.spotName});

  @override
  _LeaveReviewPageState createState() => _LeaveReviewPageState();
}

class _LeaveReviewPageState extends State<LeaveReviewPage> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  List<String> _selectedTags = [];
  String? spotName;
  List<String>? spotImageUrls;
  bool _isRated = false;
  String? imageUrl; // Variable to store the uploaded image URL

  // Firebase Realtime Database Reference
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  final List<String> _availableTags = [
    'clean',
    'crowded',
    'family-friendly',
    'affordable',
    'poor service',
    'good parking'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSpotData();
    _checkIfUserHasRated();
  }
  Future<void> _pickImage() async {
    // Open the file picker to allow selecting media files (photos, videos)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media, // Allows media files like photos and videos
      allowMultiple: false, // Set to true if you want to select multiple files
    );

    if (result != null) {
      // Get the picked file
      File file = File(result.files.single.path!);
      print('File picked: ${file.path}');

      // You can check the file extension here if needed
      String fileExtension = file.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        // Proceed to upload the image
        await _uploadImage(file);
      } else {
        print('Selected file is not an image');
      }
    } else {
      // User canceled the picker
      print('No file selected');
    }
  }
  Future<void> _uploadImage(File file) async {
    try {
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('review_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      // Upload the image
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update state with the new image URL
      setState(() {
        imageUrl = downloadUrl;
      });
      print('Image uploaded successfully: $imageUrl');
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

  // Fetch the spot data from Realtime Database
  Future<void> _fetchSpotData() async {
    final snapshot = await _databaseReference
        .child('all_touristspot')
        .orderByChild('name')
        .equalTo(widget.spotName)
        .get();

    if (snapshot.exists) {
      var spotData = snapshot.value as Map;
      // Assuming the data structure looks like this:
      // { "spotName": { "name": "spot_name", "photoUrl": "url", ... } }

      var spot = spotData.values.first;
      setState(() {
        spotName = spot['name']; // Set the spot name
        spotImageUrls = List<String>.from(spot['photos'] ?? []);
      });
    } else {
      print("No data available for this spot.");
    }
  }

  // Check if the user has already rated the business
  void _checkIfUserHasRated() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return; // User not logged in
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('ratings')
        .where('spotId', isEqualTo: widget.spotId)
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final existingRating = snapshot.docs.first.data();
      setState(() {
        _rating = (existingRating['rating'] as num).toInt();  // Set the slider to the existing rating
        _isRated = true; // Indicate that the user has already rated
      });
    }
  }
  void _submitReview() async {
    if (_commentController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to leave a review!')),
      );
      return;
    }
    if (imageUrl == null || imageUrl!.isEmpty) {
      print('No image uploaded'); // Handle this case appropriately
      return; // Optionally return or show a message to the user
    }

    try {
      final timestamp = FieldValue.serverTimestamp();
      final spotId = widget.spotId; // Ensure `spotId` is passed to the widget
// Check if the user has already rated the spot
      print('Checking if user has rated: spotId=$spotId, userId=$userId');
      final ratingDoc = await FirebaseFirestore.instance
          .collection('ratings')
          .where('spotId', isEqualTo: spotId)
          .where('userId', isEqualTo: userId)
          .get();
      print('Found ${ratingDoc.docs.length} ratings');
      if (ratingDoc.docs.isNotEmpty) {
        // Update existing rating
        final docId = ratingDoc.docs.first.id;
        await FirebaseFirestore.instance.collection('ratings').doc(docId).update({
          'rating': _rating,
          'spotId': spotId,
          'userId': userId,
          'timestamp': timestamp,
        });
        print('Updating rating');
        _updateAverageRating(_rating);
      } else {
        // Add a new rating
        await FirebaseFirestore.instance.collection('ratings').add({
          'rating': _rating,
          'spotId': spotId,
          'userId': userId,
          'timestamp': timestamp,
        });
        print('Adding new rating');
        _updateAverageRating(_rating);
      }
        await FirebaseFirestore.instance.collection('reviews').add({
          'spotId': spotId,
          'userId': userId,
          'rating': _rating,
          'imageUrl': imageUrl,
          'comment': _commentController.text,
          'tags': _selectedTags,
          'timestamp': timestamp,
        });

        // Save comment in the `comments` collection
        await FirebaseFirestore.instance.collection('comments').add({
          'message': _commentController.text,
          'spotId': spotId,
          'userId': userId,
          'imageUrl': imageUrl,
          'timestamp': timestamp,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review submitted successfully!')),
        );
      Navigator.pop(context); // Go back after submission
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }
  Future<void> _updateAverageRating(int newRating) async {
    // Fetch all ratings for the current spotId
    final spotId = widget.spotId;
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('ratings')
        .where('spotId', isEqualTo: spotId!)
        .get();

    // Calculate the new average rating
    int totalRatings = 0;
    int ratingCount = ratingsSnapshot.docs.length;

    // Sum all the existing ratings
    for (var doc in ratingsSnapshot.docs) {
      totalRatings += (doc['rating'] as num).toInt();
    }

    // Add the new rating to the total sum
    totalRatings += newRating;

    // Calculate the new average
    double average = totalRatings / (ratingCount + 1);

    // Query the tourist_spots collection to find the document where spotId matches
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tourist_spots')
          .where('spotId', isEqualTo: spotId!)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If the document exists, update the average rating and reviews count
        final docRef = querySnapshot.docs.first;
        await docRef.reference.update({
          'averageRating': average,
          'reviewsCount': ratingCount + 1, // Increment the reviews count
        });
      } else {
        // If the document does not exist, create it
        await FirebaseFirestore.instance.collection('tourist_spots').add({
          'averageRating': average,
          'reviewsCount': 1, // First rating, so reviewsCount is 1
          'spotId': spotId!,
          // Add any other necessary fields here, such as name, description, etc.
        });
      }

    } catch (e) {
      // Handle any errors that might occur during the Firestore update
      print('Error updating Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave a Review',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // White container box for the review form
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spot image and name
                if (spotImageUrls != null && spotImageUrls!.isNotEmpty && spotName != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            spotImageUrls!.first,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            spotName!, // Display the spot name
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Divider(
                    color: Colors.grey, // Line color
                    thickness: 1, // Line thickness
                    indent: 0, // Indentation on the left
                    endIndent: 0, // Indentation on the right
                  ),
                    SizedBox(height: 5.0),
                ],
                    // Ratings
                    Text(
                      'Rate this spot:',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _rating.toDouble(), // Cast _rating to double
                      min: 0,
                      max: 5,
                      divisions: 5,
                      onChanged: _isRated
                          ? null // Disable slider if the user has already rated
                          :(value) {
                        setState(() {
                          _rating = value.round(); // Round and cast value to int
                        });
                      },
                      activeColor: Colors.red.shade800, // Color of the filled portion
                      inactiveColor: Colors.red.shade100, // Color of the unfilled portion
                      label: _rating.toStringAsFixed(1),// No changes needed for the label
                    ),
                    Text(
                      'Add photos:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        // Container with dashed border
                        Container(
                          width: 150.0,
                          height: 150.0,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.photo_camera, color: Colors.red.shade800),
                            onPressed: _pickImage, // Call function to pick image
                          ),
                        ),
                        SizedBox(width: 8.0),
                        // Display uploaded images next to the icon
                        imageUrl != null && imageUrl!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(15.0), // Set the desired radius
                          child: Image.network(
                            imageUrl!,
                            width: 150.0,
                            height: 150.0,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(50.0), // Add padding to give some space
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade800),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('Error loading image');
                            },
                          ),
                        )
                            : Container(),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    // Leave a comment
                    Text(
                      'Leave a comment:',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // Set the background color to light gray
                        borderRadius: BorderRadius.circular(16.0), // Apply border radius here
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Type your comment here...',
                          hintStyle: TextStyle(
                            fontSize: 12.0, // Set the font size for the hint text
                            color: Colors.grey, // Optional: Set the hint text color
                          ),
                          border: InputBorder.none, // Remove the border
                          contentPadding: EdgeInsets.all(12.0), // Add padding inside the text field
                        ),
                        style: TextStyle(fontSize: 16.0), // Optional: Adjust text style
                      ),
                    ),
                    SizedBox(height: 16.0),

                    // Select relevant tags
                    Text(
                      'Select relevant tags:',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red.shade800 : Colors
                                  .grey[300],
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4.0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors
                                    .black87,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.0),
              // Space between container and submit button

              // Submit button
              ElevatedButton(
                onPressed: _submitReview,
                child: Text('Submit Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800, // Button background color
                  foregroundColor: Colors.white, // Text color
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
