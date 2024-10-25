import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StarRating extends StatefulWidget {
  final String spotId; // ID of the tourist spot

  StarRating({required this.spotId});

  @override
  _StarRatingState createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int _currentRating = 0;

  void _onStarTap(int index) async {
    setState(() {
      _currentRating = index + 1; // Update the current rating
    });

    // Reference to the specific tourist spot
    final spotRef = FirebaseDatabase.instance.ref().child('tourist_spots').child(widget.spotId);

    // Fetch the current rating data for the spot
    DataSnapshot snapshot = await spotRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> spotData = Map<String, dynamic>.from(snapshot.value as Map);

      // Get the current rating and number of reviews
      double currentRating = spotData['rating'] ?? 0;
      int numberOfReviews = spotData['number_of_reviews'] ?? 0;

      // Calculate the new average rating
      double newRating = ((currentRating * numberOfReviews) + _currentRating) / (numberOfReviews + 1);
      int newNumberOfReviews = numberOfReviews + 1;

      // Update the database with the new rating
      await spotRef.update({
        'rating': newRating,
        'number_of_reviews': newNumberOfReviews,
      });
    } else {
      // If it's the first rating for this spot
      await spotRef.set({
        'rating': _currentRating.toDouble(),
        'number_of_reviews': 1,
      });
    }

    // Optional: Notify the user of a successful rating
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thanks for your rating!')));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            color: Colors.yellow,
          ),
          onPressed: () => _onStarTap(index),
        );
      }),
    );
  }
}
