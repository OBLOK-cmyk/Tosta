import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/homepage.dart';
import 'package:untitled/login.dart';
import 'package:untitled/pages/preferences.dart';
import 'package:untitled/pages/tourist_screen.dart';
import 'package:untitled/verifyemail.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              final user = FirebaseAuth.instance.currentUser;

              // Check if the user is authenticated and if their email is verified
              if (user != null && !user.emailVerified) {
                return VerifyEmail(); // Go to email verification screen
              } else {
                return PreferencesPage(); // Go to the main app
              }
            } else {
              return Login(); // Go to the login screen if not authenticated
            }
          }),
    );
  }
}
