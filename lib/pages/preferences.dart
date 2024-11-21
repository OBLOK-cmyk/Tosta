import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/pages/tourist_screen.dart';


class PreferencesPage extends StatefulWidget {
  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Place and food options
  final List<String> placeOptions = [
    'Tourist',
    'Food',
    'Adventure',
    'Cultural',
    'Relaxation'
  ];

  final List<String> foodOptions = [
    'Local',
    'International',
    'Street Food',
    'Vegan',
    'Seafood',
    'Desserts'
  ];

  // Selected items
  List<String> selectedPlaces = [];
  List<String> selectedFoods = [];

  Future<void> savePreferences() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'placePreferences': selectedPlaces,
        'foodPreferences': selectedFoods,
      }, SetOptions(merge: true));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TouristSpotsApp(),
        ),
      );
    }
  }

  Widget buildSelectableCard(String title, bool isSelected, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: isSelected ? Colors.red.shade800 : Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            Text(
              "What type of place are you looking for?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: placeOptions.map((option) {
                bool isSelected = selectedPlaces.contains(option);
                return buildSelectableCard(option, isSelected, () {
                  setState(() {
                    isSelected
                        ? selectedPlaces.remove(option)
                        : selectedPlaces.add(option);
                  });
                });
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              "What kind of food are you interested in?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: foodOptions.map((option) {
                bool isSelected = selectedFoods.contains(option);
                return buildSelectableCard(option, isSelected, () {
                  setState(() {
                    isSelected
                        ? selectedFoods.remove(option)
                        : selectedFoods.add(option);
                  });
                });
              }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: savePreferences,
              child: Text('Save Preferences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,// Set button color
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}