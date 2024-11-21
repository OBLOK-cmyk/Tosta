import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/login.dart';
import 'package:untitled/signup.dart';
import 'dart:async';
import 'package:untitled/wrapper.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    sendVerificationLink();
    // Animation Controller for growing/shrinking effect
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Repeats the animation in reverse

    // Tween Animation for scaling effect
    _animation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: reload, // Reload on icon tap
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animation.value, // Apply scaling animation
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.shade800, // Icon background color
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Icon(
                        Icons.verified_user , // Verification icon
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Instructional text
            const Text(
              'Tap the icon to reload and check verification status.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            // Go to Login button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800, // Button color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Signup()), // Replace with your signup page widget
                );
              },
              child: const Text(
                'Go Back',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}