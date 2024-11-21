import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();
  String _userName = '';
  String _userEmail = '';
  String _userPassword = '******'; // Masked password (for display purposes)


  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _passwordController.text = _userPassword;
    _emailController.text = _userEmail;
  }

  // Function to toggle password editing mode
  void _togglePasswordEdit() {
    setState(() {
      _isEditingPassword = !_isEditingPassword;
      if (!_isEditingPassword) {
        // If we exit edit mode, mask the password again
        _userPassword = _passwordController.text;
      }
    });
  }
  // Function to toggle name editing mode
  void _toggleNameEdit() {
    setState(() {
      _isEditingName = !_isEditingName;
      if (!_isEditingName) {
        // Update the name when edit mode is turned off
        _userName = _nameController.text;
      }
    });
  }

  // Function to toggle email editing mode
  void _toggleEmailEdit() {
    setState(() {
      _isEditingEmail = !_isEditingEmail;
      if (!_isEditingEmail) {
        // Update the email when edit mode is turned off
        _userEmail = _emailController.text;
      }
    });
  }

  // Fetch user details from Firebase
  Future<void> _fetchUserDetails() async {
    // Get current user from FirebaseAuth
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      setState(() {
        _userEmail = currentUser.email ?? '';
      });

      // Fetch user display name from Firestore using the userId (UID)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['displayName'] ?? ''; // Assuming 'displayName' field exists

        });
      }
    }
  }
  Future<void> _updateName() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Update the name in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'displayName': _nameController.text.trim()});
      print("Name updated in Firestore: ${_nameController.text.trim()}");
    }
  }

  void _updateUserInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _updateName(); // Update name
        // Update email
        if (_emailController.text.isNotEmpty &&
            _emailController.text != _userEmail) {
          await user.updateEmail(_emailController.text.trim());
          setState(() {
            _userEmail = _emailController.text.trim();
          });
          print("Email updated.");
        }
      }

      // If updating the password
      if (_isEditingPassword && _passwordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          throw Exception("Please enter your current password.");
        }

        // Re-authenticate the user with the current password
        AuthCredential credential = EmailAuthProvider.credential(
          email: FirebaseAuth.instance.currentUser?.email ?? '',
          password: _currentPasswordController.text,
        );
        await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);

        // Update the password
        await FirebaseAuth.instance.currentUser?.updatePassword(_passwordController.text);
        print("Password updated in Firebase Auth.");
      }

      // After saving, update local variables and show success message
      setState(() {

        _userPassword = _passwordController.text; // Assuming password has been updated
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Information updated successfully!')));

    } catch (e) {
      print("Error occurred while updating user info: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update information: $e')));
    }
  }


  // Function to update the user details
  Future<void> _updateUserDetails(String name, String email, String password) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Update name in Firestore
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'displayName': name,
        });

        // Update email in FirebaseAuth
        if (email != _userEmail) {
          await currentUser.updateEmail(email);
          setState(() {
            _userEmail = email; // Update the email field
          });
        }

        // Update password in FirebaseAuth
        if (password != '*****') {
          await currentUser.updatePassword(password);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User details updated successfully')));
        Navigator.pop(context); // Close the modal
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating user details')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(  // Wrap the entire body with SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // User Icon and Name - Centered
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              child: Icon(Icons.account_circle, size: 80),
                            ),
                            SizedBox(height: 16),
                            _isEditingName
                                ? TextField(
                              controller: _nameController,
                              decoration: InputDecoration(hintText: 'Enter your name'),
                              autofocus: true,
                            )
                                : Text(
                              _userName,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.red.shade800),
                              onPressed: _toggleNameEdit,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Security Warning
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.red.shade100,
                        child: Text(
                          'For enhanced account security, keep your account information updated',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Email field - Editable with Icon
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _isEditingEmail
                                ? TextField(
                              controller: _emailController,
                              decoration: InputDecoration(hintText: 'Enter your email'),
                              autofocus: true,
                            )
                                : Text(
                              _userEmail,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.red.shade800),
                            onPressed: _toggleEmailEdit,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (_isEditingPassword)
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            hintText: 'Enter your current password',
                          ),
                        ),
                      SizedBox(height: 16),
                      // Password field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _isEditingPassword
                              ? Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(hintText: 'Enter new password'),
                              autofocus: true,
                            ),
                          )
                              : Text(
                            _userPassword,
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.red.shade800),
                            onPressed: _togglePasswordEdit,
                          ),
                        ],
                      ),


                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity, // Makes the button take the full width of its container
                child: ElevatedButton(
                  onPressed: _updateUserInfo,
                  child: Text('Update Information'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,// Set button color
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    textStyle: TextStyle(fontSize: 16, color: Colors.white), // Set text color to white
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}