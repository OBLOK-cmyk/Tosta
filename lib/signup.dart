import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import for Realtime Database
import 'package:flutter/material.dart';
import 'package:untitled/login.dart';
import 'package:untitled/wrapper.dart';
import 'package:get/get.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isLoading = false;

  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  Future<void> signup() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Basic validation
      if (email.text.isEmpty || password.text.length < 6) {
        Get.snackbar(
          "Error",
          "Please enter a valid email and password (min 6 characters).",
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      // Initialize user data in the Realtime Database
      await _databaseReference.child('users').child(userCredential.user!.uid).set({
        'favorites': [],
        'recentlyViewed': [],
      });

      Get.offAll(Wrapper());
    } catch (e) {
      // Show an error message
      print("Error: $e");
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
      backgroundColor: Colors.red.shade800, // Set background color to red
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                // Top-right "Don't have an account?" and "Get Started" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 5), // Space between text and button
                    ElevatedButton(
                      onPressed: () => Get.to(() => Login()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3), // Button background color
                        foregroundColor: Colors.white, // Button text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text("Sign in"),
                    ),
                  ],
                ),
                SizedBox(height: 40), // Space between top elements and TOSTA
                // TOSTA centered text
                Center(
                  child: Text(
                    "TOSTA",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          // Modal-like container for signup form positioned at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Modal background color
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded corners at the top
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -3), // Shadow offset upwards
                  ),
                ],
              ),
              child: SingleChildScrollView( // Wrap in SingleChildScrollView to prevent overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Shrink container to its content
                  children: [
                    // Welcome text
                    Text(
                      "Get Started free.",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    // Enter your details below text
                    Text(
                      "Enter the required details below",
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20), // Space between text and input fields
                    // Email input
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter email address",
                        filled: true,
                        fillColor: Colors.grey[50], // Light background for input fields
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Space between inputs
                    // Password input
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Enter password",
                        filled: true,
                        fillColor: Colors.grey[50], // Light background for input fields
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Space between inputs and buttons
                    // Sign Up Button
                    ElevatedButton(
                      onPressed: () => signup(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800, // Red button
                        foregroundColor: Colors.white, // White text color
                        padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Sign Up"),
                    ),
                    SizedBox(height: 20), // Space between button and other elements
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
