import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/forgot.dart';
import 'package:untitled/pages/tourist_screen.dart';
import 'package:untitled/signup.dart';
import 'package:untitled/verifyemail.dart';
import 'package:untitled/widgets/admin.dart';
import 'package:untitled/widgets/business_reg.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isLoading = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref(); // Updated line
  final String adminEmail = ''; // Replace with your admin email
  final String adminPassword = ''; // Replace with your admin password

  signIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      if (email.text == adminEmail && password.text == adminPassword) {
        Get.offAll(() => Admin());
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email.text, password: password.text);

        String userId = userCredential.user!.uid;

        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          Get.to(() => VerifyEmail());
        } else {
          // Initialize user data in the database
          _databaseReference.child('users').child(userId).set({
            'favorites': [],
            'recentlyViewed': [],
          });

          Get.snackbar('Success', 'Login successful');
          Get.offAll(() => TouristSpotsApp());
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'An error occurred');
    } catch (e) {
      Get.snackbar('Error', 'Please enter your credentials properly');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void addFavorite(String userId, String itemId) {
    _databaseReference.child('users').child(userId).child('favorites').child(itemId).set(true);
  }

  void addRecentlyViewed(String userId, String itemId) {
    _databaseReference.child('users').child(userId).child('recentlyViewed').child(itemId).set(true);
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
      backgroundColor: Colors.red.shade800,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: Colors.white)),
                    SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () => Get.to(() => Signup()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text("Get Started"),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Center(
                  child: Text("TOSTA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          Spacer(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -3))],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 10),
                    Text("Enter your details below", style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
                    SizedBox(height: 20),
                    TextField(
                      controller: email,
                      decoration: InputDecoration(
                        hintText: "Enter email address",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Enter password",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => signIn(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text("Sign In"),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Get.to(() => Forgot()),
                      child: Text("Forgot your password?", style: TextStyle(color: Colors.black, fontSize: 13)),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Get.to(() => BusinessReg(
                        onRegister: (businessData) {
                          print("Business registered: $businessData");
                          Get.snackbar("Success", "Business registered successfully!");
                        },
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text("Business Registration"),
                    ),
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
