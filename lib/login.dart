import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/forgot.dart';
import 'package:untitled/pages/preferences.dart';
import 'package:untitled/pages/tourist_screen.dart';
import 'package:untitled/signup.dart';
import 'package:untitled/verifyemail.dart';
import 'package:untitled/widgets/admin.dart';
import 'package:untitled/widgets/business_reg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String adminEmail = 'tosta@gmail.com'; // Replace with your admin email
  final String adminPassword = 'tostaILoveTaguig'; // Replace with your admin password

  @override
  void initState() {
    super.initState();
    checkUserPreferences();
  }
  Future<void> checkUserPreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to retrieve the user's document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Get the user data
        var userData = userDoc.data() as Map<String, dynamic>?;

        // Check if preferences exist, only if userData is not null
        bool hasPlacePreferences = userData?.containsKey('placePreferences') ?? false;
        bool hasFoodPreferences = userData?.containsKey('foodPreferences') ?? false;

        if (hasPlacePreferences && hasFoodPreferences) {
          // Preferences exist, navigate to the tourist screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TouristSpotsApp(),
            ),
          );
        } else {
          // Preferences are missing, initialize the fields and navigate to preferences page
          if (!hasPlacePreferences || !hasFoodPreferences) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'placePreferences': [],
              'foodPreferences': [],
            });
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PreferencesPage(),
            ),
          );
        }
      } else {
        // Document does not exist - first login, navigate to preferences page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PreferencesPage(),
          ),
        );
      }
    }
  }


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
          checkUserPreferences();
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
                    SizedBox(height: 10),
                   
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
