import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardWidget extends StatefulWidget {
  @override
  _DashboardWidgetState createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  int totalSpots = 0;
  int totalReviews = 0;
  List<Map<String, dynamic>> topRatedSpots = [];
  List<Map<String, dynamic>> mostReviewedSpots = [];
  List<Map<String, dynamic>> popularCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch total number of tourist spots
    QuerySnapshot spotsSnapshot = await firestore.collection('tourist_spots').get();
    totalSpots = spotsSnapshot.docs.length;

    // Fetch total number of reviews
    QuerySnapshot reviewsSnapshot = await firestore.collection('reviews').get();
    totalReviews = reviewsSnapshot.docs.length;

    // Fetch top-rated tourist spots
    QuerySnapshot topRatedSnapshot = await firestore
        .collection('tourist_spots')
        .orderBy('averageRating', descending: true)
        .limit(5)
        .get();
    topRatedSpots = topRatedSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Fetch most-reviewed tourist spots
    QuerySnapshot mostReviewedSnapshot = await firestore
        .collection('tourist_spots')
        .orderBy('reviewsCount', descending: true)
        .limit(5)
        .get();
    mostReviewedSpots = mostReviewedSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Fetch most popular categories
    QuerySnapshot categoriesSnapshot = await firestore.collection('tourist_spots').get();
    Map<String, int> categoryCount = {};
    for (var doc in categoriesSnapshot.docs) {
      String category = doc['category'];
      if (categoryCount.containsKey(category)) {
        categoryCount[category] = categoryCount[category]! + 1;
      } else {
        categoryCount[category] = 1;
      }
    }
    popularCategories = categoryCount.entries
        .map((entry) => {'category': entry.key, 'count': entry.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int)); // Cast to int

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Total Number of Tourist Spots: $totalSpots", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text("Total Number of Reviews: $totalReviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Text("Top Rated Tourist Spots", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        for (var spot in topRatedSpots)
          ListTile(
            title: Text(spot['name']),
            subtitle: Text('Rating: ${spot['averageRating']}'),
          ),
        SizedBox(height: 20),
        Text("Most Reviewed Tourist Spots", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        for (var spot in mostReviewedSpots)
          ListTile(
            title: Text(spot['name']),
            subtitle: Text('Reviews: ${spot['reviewsCount']}'),
          ),
        SizedBox(height: 20),
        Text("Most Popular Tourist Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        for (var category in popularCategories)
          ListTile(
            title: Text('${category['category']}'),
            subtitle: Text('Count: ${category['count']}'),
          ),
      ],
    );
  }
}
