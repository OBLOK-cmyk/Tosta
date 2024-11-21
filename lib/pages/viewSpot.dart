import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/comments/comment_Venice.dart';
import 'package:untitled/comments/review.dart';
import 'Map.dart';

// TouristSpotDetailsPage to display details about the selected tourist spot
class TouristSpotDetailsPage extends StatefulWidget {

  final String? businessKey;
  final String? businessName;

  TouristSpotDetailsPage({Key? key, required this.businessKey, this.businessName}) : super(key: key);

  @override
  _TouristSpotDetailsPageState createState() => _TouristSpotDetailsPageState();
}

class _TouristSpotDetailsPageState extends State<TouristSpotDetailsPage> {
  String businessKey = '';
  bool isThingsToDoExpanded = false; // State for expanding 'Things to Do' section
  bool isGoNowExpanded = false; // State for expanding 'Go Now' section
  bool isHistory = false; // State for expanding 'History' section
  bool isOpeningHours = false;
  // State for favorite status
  int _userRating = 0;
  int _totalReviews = 0; // Total number of reviews for the tourist spot
  double? averageRating; // Variable to store the average rating
  final FirebaseAuth _auth = FirebaseAuth
      .instance; // Firebase Authentication instance
  final FirebaseFirestore _firestore = FirebaseFirestore
      .instance; // Firestore instance
  bool _hasRated = false;
  bool isFavorite = false;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final DatabaseReference _businessRef = FirebaseDatabase.instance.ref(
      'accepted_businesses');
  late Future<Map<String, dynamic>> _businessDetails;
  String? spotId;
  late String businessName;



  @override
  void initState() {
    super.initState();
    //_checkIfUserHasRated();
    print("Business Key: ${widget.businessKey}"); // Debugging line
    _businessDetails = _fetchBusinessDetails(widget.businessKey!);
    businessName = widget.businessName!;


  }

  Future<List<String>> fetchTags(String spotId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('spotId', isEqualTo: spotId)
          .get();

      Map<String, int> tagFrequency = {};

      // Iterate through the documents to collect tags and calculate frequencies
      for (var doc in querySnapshot.docs) {
        List<dynamic> docTags =
        doc.data().containsKey('tags') ? doc['tags'] : [];
        for (var tag in docTags.cast<String>()) {
          tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
        }
      }

      // Sort tags by frequency in descending order and limit to top 5
      var sortedTags = tagFrequency.entries
          .map((entry) => {'tag': entry.key, 'count': entry.value})
          .toList();

      // Cast count to int and then sort
      sortedTags.sort((a, b) {
        int countA = a['count'] as int? ?? 0; // Cast count to int with a fallback
        int countB = b['count'] as int? ?? 0; // Cast count to int with a fallback
        return countB.compareTo(countA); // Compare the counts in descending order
      });

      // Return top 5 tags (or fewer if there are less than 5)
      List<String> topTags = sortedTags.take(5).map((entry) => entry['tag'] as String).toList();

      return topTags; // Return the top 5 tags
    } catch (e) {
      print('Error fetching tags: $e');
      return []; // Return empty list on error
    }
  }
  Future<void> _checkIfFavorite(String businessName) async {
    final userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      List favorites = userDoc['favorites'] ?? [];
      if (favorites.contains(businessName)) {
        setState(() {
          isFavorite = true;
        });
      } else {
        setState(() {
          isFavorite = false;
        });
      }
    }
  }
  // Function to toggle favorite
  void _onFavoriteTap(String businessName) async {
    try {
      final user = FirebaseAuth.instance.currentUser; // Get the current user
      if (user != null) {
        // Get reference to the user's Firestore document
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // Get the current favorites array from Firestore
        DocumentSnapshot userDocSnapshot = await userDocRef.get();
        List<dynamic> favorites = userDocSnapshot.exists ? userDocSnapshot['favorites'] ?? [] : [];



        // Check if the business is already in the favorites list
        if (favorites.contains(businessName)) {
          // Remove the business from the favorites list
          favorites.remove(businessName);
        } else {
          // Add the business to the favorites list
          favorites.add(businessName);
        }

        // Update the user's Firestore document with the new favorites list
        await userDocRef.update({
          'favorites': favorites,
        });

        // Update the local state to reflect the new favorite status
        setState(() {
          isFavorite = favorites.contains(businessName); // Update the UI based on the new list
        });

      } else {
        // Handle the case when the user is not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You need to be logged in to favorite this spot.')),
        );
      }
    } catch (e) {
      // Handle any errors that occur during the Firestore update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving favorite: $e')),
      );
    }
  }


  // Fetch the spotId from Firestore using the business name
  Future<void> _getSpotId(String businessName) async {
    // Check if the businessName is valid
    if (businessName == null || businessName.isEmpty) {
      print('Invalid business name');
      return;
    }

    print('Fetching spotId for businessName: $businessName');
    final snapshot = await FirebaseFirestore.instance
        .collection('tourist_spots')
        .where('name', isEqualTo: businessName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      setState(() {
        spotId = doc['spotId'];  // The spotId is a field inside the document
      });

      // After getting the spotId, check if the user has rated
      _checkUserRating(spotId!);
      getAverageRating(spotId!);
      fetchTags(spotId!);
    }
  }

  // Handle navigation bar tap events
  void _onNavBarTap(int index) {
    switch (index) {
      case 0:
      // Explore functionality can be added here
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LeaveReviewPage(spotId: spotId!, spotName: businessName )),
        );
      // Ratings and Comments section can be added here
        break;
      case 2:
      // Navigate to Comments section
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CommentVenice(spotId: spotId!)),
        );
        break;
    }
  }
  Future<int> fetchVisitCountFromDatabase(String businessName) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('tourist_spots') // Your collection name
          .doc(businessName)
          .get();

      return snapshot['visitCount'] ?? 0; // Return 0 if not found
    } catch (e) {
      print('Error fetching visit count: $e');
      return 0; // Handle the error as needed
    }
  }
  Future<void> updateVisitCountInDatabase(String businessName, int newCount) async {
    try {
      await FirebaseFirestore.instance
          .collection('tourist_spots') // Your collection name
          .doc(businessName)
          .update({'visitCount': newCount});
    } catch (e) {
      print('Error updating visit count: $e'); // Handle the error as needed
    }
  }

  // Check if the user has already rated the business
  Future<void> _checkUserRating(String spotId) async {
    String userId = _auth.currentUser!.uid;
    final ratingData = await FirebaseFirestore.instance
        .collection('ratings')
        .where('spotId', isEqualTo: spotId)
        .where('userId', isEqualTo: userId)
        .get();

    print('Rating data for $spotId and $userId: ${ratingData.docs.length}');
    if (ratingData.docs.isNotEmpty) {
      print('Rating found: ${ratingData.docs.first.data()}');
      setState(() {
        _userRating = ratingData.docs.first['rating'];
        _hasRated = true;
      });
    } else {
      _hasRated = false;
      print('No rating found for this user and spot');
    }
  }
  Future<Map<String, dynamic>> _fetchBusinessDetails(String businessKey) async {
    try {
      // First, try fetching from the accepted_businesses node
      final acceptedBusinessSnapshot = await FirebaseDatabase.instance
          .ref("accepted_businesses/$businessKey")
          .get();

      Map<String, dynamic> businessData = {};

      if (acceptedBusinessSnapshot.value != null) {
        final rawBusinessData = acceptedBusinessSnapshot.value as Map<Object?, Object?>;
        print("Raw business data from accepted_businesses: $rawBusinessData");

        businessData = rawBusinessData.map((key, value) => MapEntry(key.toString(), value));
        print("Fetched business data from accepted_businesses: $businessData");
      } else {
        // If not found in accepted_businesses, fetch from all_tourist_spots
        final allTouristSpotSnapshot = await FirebaseDatabase.instance
            .ref("all_touristspot/$businessKey")
            .get();

        if (allTouristSpotSnapshot.value != null) {
          final rawBusinessData = allTouristSpotSnapshot.value as Map<Object?, Object?>;
          print("Raw business data from all_tourist_spots: $rawBusinessData");

          businessData = rawBusinessData.map((key, value) => MapEntry(key.toString(), value));
          print("Fetched business data from all_tourist_spots: $businessData");
        }
      }

      if (businessData.isEmpty) {
        print("No business data found in both accepted_businesses and all_tourist_spots");
        return {}; // Return empty map if no data is found
      }

      final businessName = businessData['name'] as String? ?? 'Unknown Business';
      final businessDescription = businessData['description'] as String? ?? 'Description not available';
      final businessLocation = businessData['location'] as String? ?? 'Location not available';
      final businessLatlong = businessData['latlong'] as String? ?? 'Location not available';
      final openingHours = businessData['openingHours'] as String? ?? 'Not available';
      final closingHours = businessData['closingHours'] as String? ?? 'Not available';
      final photos = businessData['photos'] as List<dynamic>? ?? [];
      final businessImageUrl = (photos.isNotEmpty) ? photos[0] as String : ''; // Handle image URL

      // Fetching corresponding tourist spot from Firestore
      final touristSpotDoc = await FirebaseFirestore.instance
          .collection('tourist_spots')
          .doc(businessName) // Assuming the document name is the same as businessKey
          .get();

      Map<String, dynamic> touristSpotData = {};

      if (touristSpotDoc.exists) {
        touristSpotData = touristSpotDoc.data() as Map<String, dynamic>;
        print("Tourist spot data: $touristSpotData");
      }

      // After fetching business and tourist spot data, pass businessName to getSpotId
      _getSpotId(businessName);  // Pass the businessName to getSpotId
      _checkIfFavorite(businessName);


      // Returning merged data from both sources
      return {
        'businessName': businessName,
        'description': businessDescription,
        'location': businessLocation,
        'latlong': businessLatlong,
        'image': businessImageUrl,
        'openingHours': openingHours,
        'closingHours': closingHours,
        // Include tourist spot data if found
        'touristSpot': touristSpotData,
      };

    } catch (e) {
      print('Error fetching business and tourist spot details: $e');
      return {}; // Return an empty map on error
    }
  }


  Future<void> getAverageRating(String spotId) async {
    final businessSnapshot = await FirebaseFirestore.instance
        .collection('tourist_spots')
        .where('spotId', isEqualTo: spotId)
        .get();

    if (businessSnapshot.docs.isNotEmpty) { // Check if any documents were found
      final document = businessSnapshot.docs.first; // Access the first document

      setState(() {
        averageRating = document.data()['averageRating']?.toDouble() ?? 0.0; // Use null-aware operator to handle cases where averageRating might be null
      });
    } else {
      print("No document found for spotId: $spotId");
    }
  }
  Future<void> _onStarTap(int rating) async {
    if (_hasRated)

      return; // Prevent submission if spotId is null


    setState(() {
      _userRating = rating;
      _hasRated = true;
    });

    String userId = _auth.currentUser!.uid;

    // Save the rating to Firestore
    await _firestore.collection('ratings').add({
      'rating': rating,
      'spotId': spotId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Log rating event in Firebase Analytics
    _updateAverageRating(rating);
  }
  Future<void> _updateAverageRating(int newRating) async {
    // Fetch all ratings for the current spotId
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

      // Optionally, update the UI with the new average
      setState(() {
        averageRating = average;
      });

    } catch (e) {
      // Handle any errors that might occur during the Firestore update
      print('Error updating Firestore: $e');
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
              isFavorite == true ? Icons.favorite : Icons.favorite_border,
              color: isFavorite == true ? Colors.red : Colors.grey,
            ),
              onPressed: () {
              _onFavoriteTap(businessName);
            }
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _businessDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade800),
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No business details available.'));
          } else {
            final businessData = snapshot.data!;
            final businessName = businessData['businessName'] as String;
            final location = businessData['location'] as String;
            final businessLatlong = businessData['latlong'] as String;
            final businessImageUrl = businessData['image'];
            final businessDescription = businessData['description'];


            final openingHours = businessData['openingHours'] as String;
            final closingHours = businessData['closingHours'] as String;
            if (averageRating == null) {
              getAverageRating(businessName);
            }

            DateTime now = DateTime.now();
            DateTime openingTime = _parseTime(openingHours, now);
            DateTime closingTime = _parseTime(closingHours, now);

            // Check if the closing time is earlier than the opening time, meaning it is past midnight
            if (closingTime.isBefore(openingTime)) {
              closingTime = closingTime.add(Duration(days: 1)); // Adjust closing time to the next day
            }

            // Check if the business is open or closed
            bool isOpen = now.isAfter(openingTime) && now.isBefore(closingTime);

            return ListView(
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                // Image display
                ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.network(
                    businessImageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 20),
                Text('$businessName',
                  style: TextStyle( fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                ),
                // Rating
                SizedBox(height: 10),
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
                SizedBox(height: 15),
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

                SizedBox(height: 10),

                // Tags Section
                FutureBuilder<List<String>>(
                  future: spotId != null ? fetchTags(spotId!) : Future.value([]),
                  builder: (context, tagSnapshot) {
                    if (tagSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 15.0, // Set your desired width
                          height: 15.0, // Set your desired height
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade800),
                          ),
                        ),
                      );
                    } else if (tagSnapshot.hasError) {
                      return Text('Error loading tags.');
                    } else {
                      final tags = tagSnapshot.data ?? [];

                      return tags.isNotEmpty
                          ? Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: tags.map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.red.shade800,
                              borderRadius: BorderRadius.circular(20.0), // Rounded edges for oblong shape
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 2), // Add a subtle shadow
                                ),
                              ],
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(fontSize: 14.0, color: Colors.white),
                            ),
                          );
                        }).toList(),
                      )
                          : Text('');
                    }
                  },
                ),
                SizedBox(height: 20),

                // Description section
                OptionCard(
                  icon: Icons.history_outlined,
                  title: 'Details',
                  onTap: () {
                    setState(() {
                      isHistory = !isHistory;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: isHistory ? 180.0 : 0.0,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$businessDescription',
                            style: TextStyle(fontSize: 16, height: 1.5),
                            textAlign: TextAlign.justify,
                          ),
                          SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey, size: 20),
                              SizedBox(width: 8),
                              Flexible( // Allows text to wrap to the next line if needed
                                child: Text(
                                  '$location',
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                  softWrap: true, // Ensures it wraps to the next line
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Opening hours section inside OptionCard
                OptionCard(
                  icon: Icons.access_time,
                  title: 'Opening Hours',
                  onTap: () {
                    setState(() {
                      isOpeningHours = !isOpeningHours;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: isOpeningHours ? 80.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [

                          SizedBox(width: 8),
                          Text(
                            isOpen ? 'Open Now' : 'Closed Now',
                            style: TextStyle(fontSize: 16, color: isOpen ? Colors.green : Colors.red),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '($openingHours - $closingHours)',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                OptionCard(
                  icon: Icons.directions,
                  title: 'Go Now',
                  onTap: () async {
                    final businessLatlong = businessData['latlong'] as String;
                    if (businessLatlong != null && businessLatlong.isNotEmpty) {
                      final coordinates = businessLatlong.split(' ');
                      if (coordinates.length == 2) {
                        try {
                          final latitude = double.parse(coordinates[0]);
                          final longitude = double.parse(coordinates[1]);

                          // Fetch the business name safely and handle if it's null
                          final businessName = businessData['businessName'] as String?; // This allows the value to be nullable

                          if (businessName != null) {
                            // Fetch the current visit count and update it
                            final currentVisitCount = await fetchVisitCountFromDatabase(businessName);

                            // Increment the visitCount and update it in the database
                            await updateVisitCountInDatabase(businessName, currentVisitCount + 1);
                          } else {
                            // Handle the case where the business name is null
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Business name is missing!')),
                            );
                          }

                          // Navigate to the map page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPage(
                                coordinates: LatLng(latitude, longitude),
                                title: businessData['businessName'] ?? 'Map',
                              ),
                            ),
                          );
                        } catch (e) {
                          // Handle parsing error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid location data format.')),
                          );
                        }
                      } else {
                        // Handle invalid string format
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Location data is incorrectly formatted.')),
                        );
                      }
                    } else {
                      // Handle missing or invalid latlong field
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Location information is unavailable.')),
                      );
                    }
                  },
                  child: SizedBox(), // Remove the container and leave an empty child
                ),

              ],
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red.shade800,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Rate'),
          BottomNavigationBarItem(icon: Icon(Icons.reviews), label: 'Reviews'),
        ],
        onTap: _onNavBarTap, // Handle navigation bar tap
      ),
    );
  }
}
// Helper function to parse time (HH:mm) into DateTime object
DateTime _parseTime(String timeStr, DateTime currentDate) {
  final split = timeStr.split(':');
  final hour = int.parse(split[0]);
  final minute = int.parse(split[1]);
  return DateTime(currentDate.year, currentDate.month, currentDate.day, hour, minute);
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
