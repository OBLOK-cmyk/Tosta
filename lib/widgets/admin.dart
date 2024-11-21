import 'package:flutter/material.dart';
import 'business.dart'; // Import the Business class
import 'business_reg.dart'; // Import the BusinessReg form
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/login.dart'; // Import the Login page
import 'places_to_visit.dart'; // Import the PlacesToVisit page
import 'admindashboard.dart';
import 'registered.dart';
import 'pending.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    AdminDashboard(),
    RegisteredBusiness(),
    PendingApplications(),
  ];

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      print("User is logged in: ${FirebaseAuth.instance.currentUser!.uid}");
    } else {
      print("User is not logged in.");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  // Method to navigate to the login screen
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tourist Spots',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red.shade800,
        elevation: 0.0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout,color: Colors.white,
            ),
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: Color(0xFFF2F2F2),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red.shade800,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Tourist Spots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending),
            label: 'Pending',
          ),
        ],

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
