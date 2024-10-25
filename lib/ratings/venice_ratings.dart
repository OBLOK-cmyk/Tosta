import 'package:flutter/material.dart';

class VeniceRatings extends StatefulWidget {
  const VeniceRatings({super.key});

  @override
  State<VeniceRatings> createState() => _VeniceRatingsState();
}

class _VeniceRatingsState extends State<VeniceRatings> {
  double _currentRating = 4.0; // Initial rating
  final List<Map<String, dynamic>> _comments = [
    {'user': 'User1', 'comment': 'Beautiful place!', 'rating': 5},
    {'user': 'User2', 'comment': 'Great experience.', 'rating': 4},
    {'user': 'User3', 'comment': 'Amazing atmosphere!', 'rating': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venice Ratings & Comments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Average Rating:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < _currentRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Comments:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(comment['user']),
                      subtitle: Text(comment['comment']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < comment['rating']
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
