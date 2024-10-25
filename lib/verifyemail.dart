import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/login.dart';
import 'package:untitled/wrapper.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  @override
  void initState() {
    super.initState();
    sendVerificationLink();
  }

  // Function to send email verification link
  sendVerificationLink() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        Get.snackbar(
          'Verification Link Sent',
          'Check your email for the verification link.',
          margin: const EdgeInsets.all(30),
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'User is either not logged in or already verified.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Function to reload the user state and check email verification
  reload() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.reload(); // Reload user state
      if (user.emailVerified) {
        // If the email is verified, navigate to the main Wrapper
        Get.offAll(Wrapper());
      } else {
        // If email is not verified, show a snackbar with feedback
        Get.snackbar(
          'Email Not Verified',
          'Please verify your email first.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Stack(
        children: [
          // Gradient background for a modern look
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white, // Start with white at the top
                  Colors.redAccent, // Transition to red at the bottom
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Verification icon with shadow for emphasis
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.red[700],
                    child: Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 30), // Space between icon and text

                // Instruction text with improved typography
                const Text(
                  'Check your email for the verification link.\n'
                      'Once verified, click the button below to reload.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey, // Use gray for secondary text
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40), // Space between text and buttons

                // Reload and Verify button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700], // Red button
                    foregroundColor: Colors.white, // White text on the button
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                    elevation: 10, // Add shadow for a floating effect
                  ),
                  onPressed: reload, // Reload and check verification status
                  child: const Text(
                    'Reload fand Verify',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 20), // Space between buttons

                // Go to Login button with a subtle gray shade
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700], // Gray button
                    foregroundColor: Colors.white, // White text on the button
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                    elevation: 5, // Subtle shadow for button
                  ),
                  onPressed: () {
                    Get.offAll(Login()); // Navigate to Login
                  },
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[700], // Red floating button
        onPressed: reload, // On pressing, it reloads the user's status
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
