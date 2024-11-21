import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/login.dart';
import 'package:untitled/login.dart';
import 'package:untitled/pages/preferences.dart';
import 'package:untitled/pages/tourist_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Wrapper(),
    );
  }
}
class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  Future<Widget> _getInitialScreen() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Check Firestore for user preferences
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        bool hasPlacePreferences = userData?['placePreferences'] != null;
        bool hasFoodPreferences = userData?['foodPreferences'] != null;

        if (hasPlacePreferences && hasFoodPreferences) {
          return TouristSpotsApp(); // Go to Tourist Screen
        } else {
          return PreferencesPage(); // Go to Preferences Page
        }
      }
    }
    return const Login(); // Default to Login Page
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        // While waiting, show a white background and a red loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white, // White background
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red), // Red loading indicator
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong!"));
        } else {
          return snapshot.data ?? const Login();
        }
      },
    );
  }
}

