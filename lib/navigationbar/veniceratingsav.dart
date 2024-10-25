import 'package:flutter/material.dart';
import 'package:untitled/ratings/venice_ratings.dart'; // Import your VeniceRatings screen

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // Add your other screens here
    Container(), // Placeholder for other screens
    VeniceRatings(), // Your ratings and comments screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map', // Replace with other labels
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star), // Or any other icon
            label: 'Ratings and Comments',
          ),
        ],
      ),
    );
  }
}
