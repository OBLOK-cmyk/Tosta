import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {

  TextEditingController email = TextEditingController();

  reset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
      // Show a Snackbar when the link is successfully sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("A link has been sent to your email."),
          backgroundColor: Colors.green, // Set the background color to green for success
          duration: Duration(seconds: 3), // Duration of Snackbar visibility
        ),
      );
    } catch (e) {
      // If there's an error, show an error Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: Could not send reset link. Please try again."),
          backgroundColor: Colors.red, // Red background for error
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Wrap with SingleChildScrollView to handle overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center-align the text
            children: [
              // Forgot Password Text
              SizedBox(height: 200),
              Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 25, // Large font size
                  fontWeight: FontWeight.bold, // Bold
                ),
                textAlign: TextAlign.center, // Centered
              ),
              SizedBox(height: 10), // Space between texts

              // Instruction Text
              Text(
                "No worries, we'll send you reset instructions.",
                style: TextStyle(
                  fontSize: 14, // Small size
                ),
                textAlign: TextAlign.center, // Centered
              ),
              SizedBox(height: 20), // Space before the email label

              // Email Label
              Align( // Use Align widget to control alignment
                alignment: Alignment.centerLeft, // Align to the left
                child: Text(
                  "Email", // Left-aligned label
                  style: TextStyle(
                    fontSize: 16, // Small size
                    fontWeight: FontWeight.bold, // Bold
                  ),
                ),
              ),
              SizedBox(height: 10), // Space between label and TextField

              // TextField for email input
              TextField(
                controller: email,
                decoration: InputDecoration(
                  hintText: "Enter email address",
                  filled: true,
                  fillColor: Colors.grey[50], // Light background for input field
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.red.shade800, width: 2.0), // Border weight
                  ),
                ),
              ),
              SizedBox(height: 20), // Space between TextField and button

              // Reset Password Button
              ElevatedButton(
                onPressed: reset, // Function to handle reset logic and show Snackbar
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800, // Red button
                  foregroundColor: Colors.white, // White text color
                  padding: EdgeInsets.symmetric(horizontal: 105, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text("Reset Password"),
              ),

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the row
                children: [
                  Icon(Icons.arrow_back, color: Colors.black), // Arrow icon
                  SizedBox(width: 8), // Space between icon and text
                  GestureDetector(
                    onTap: () {
                      // Navigate back to login screen
                      Navigator.pop(context); // You can replace this with your login navigation logic
                    },
                    child: Text(
                      "Back to Login",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
