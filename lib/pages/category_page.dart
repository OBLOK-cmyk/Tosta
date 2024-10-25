import 'package:flutter/material.dart';
import 'tourist_spot.dart'; // Make sure to import the TouristSpot class
import 'tourist_screen.dart'; // Import your tourist spots page

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  runApp(CategorySelectionPage());
}

class CategorySelectionPage extends StatelessWidget {
  final List<String> categories = [
    'Museums',
    'Parks',
    'Shopping',
    'Historical Sites',
    // Add more categories as needed
  ];

  void _navigateToTouristSpots(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TouristSpotsApp(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Category'),
        backgroundColor: Colors.red.shade800,
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(categories[index]),
            onTap: () => _navigateToTouristSpots(context, categories[index]),
          );
        },
      ),
    );
  }
}