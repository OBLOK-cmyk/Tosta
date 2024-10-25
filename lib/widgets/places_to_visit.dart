import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PlacesToVisit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Places to Visit'),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref().child('tourist_spots').orderByChild('rating').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null || (snapshot.data! as DatabaseEvent).snapshot.value == null) {
            return Center(child: CircularProgressIndicator());
          }

          // Use DatabaseEvent instead of Event
          Map<String, dynamic> spots = Map<String, dynamic>.from(
              (snapshot.data! as DatabaseEvent).snapshot.value as Map<dynamic, dynamic>);

          // Sort by rating in descending order
          var sortedSpots = spots.entries.toList()
            ..sort((a, b) => (b.value['rating'] ?? 0).compareTo(a.value['rating'] ?? 0));

          return ListView.builder(
            itemCount: sortedSpots.length,
            itemBuilder: (context, index) {
              var spot = sortedSpots[index].value;
              return ListTile(
                title: Text(spot['name']),
                subtitle: Text('Rating: ${(spot['rating'] ?? 0).toStringAsFixed(1)}'),
              );
            },
          );
        },
      ),
    );
  }
}
