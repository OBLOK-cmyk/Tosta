import 'dart:io'; // Import to use File
import 'package:flutter/material.dart';
import 'business.dart'; // Import the Business class
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

class BusinessReg extends StatefulWidget {
  final Function(Map<String, dynamic>) onRegister;

  BusinessReg({required this.onRegister});

  @override
  _BusinessRegState createState() => _BusinessRegState();
}

class _BusinessRegState extends State<BusinessReg> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _closingHoursController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();

  String? imageUrl; // Variable to store the uploaded image URL

  Future<void> _pickImage() async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Upload the image to Firebase Storage
        await _uploadImage(pickedFile.path);
      } else {
        print('No image selected.');
      }
    } else {
      print('Permission denied');
    }
  }

  Future<void> _uploadImage(String filePath) async {
    try {
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('business_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      // Upload the image
      await storageRef.putFile(File(filePath));
      // Get the download URL
      imageUrl = await storageRef.getDownloadURL();
      print('Image uploaded successfully: $imageUrl');
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

  void _registerBusiness() {
    if (_formKey.currentState!.validate()) {
      final business = Business(
        name: _nameController.text,
        type: _typeController.text,
        location: _locationController.text,
        openingHours: _openingHoursController.text,
        closingHours: _closingHoursController.text,
        photos: [imageUrl ?? ''], // Add the uploaded image URL to the business details
        description: _descriptionController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        socialMedia: _socialMediaController.text,
      );

      // Save business to Firebase
      final businessRef = FirebaseDatabase.instance.ref('businesses').push();
      businessRef.set(business.toJson()).then((_) {
        // Notify the admin that a new business was added
        widget.onRegister(business.toJson());
        Navigator.pop(context); // Go back after registration
      }).catchError((error) {
        print('Error saving business: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Business'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Business Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a business name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Business Type'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a business type';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _openingHoursController,
                decoration: const InputDecoration(labelText: 'Opening Hours'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter opening hours';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _closingHoursController,
                decoration: const InputDecoration(labelText: 'Closing Hours'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter closing hours';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _socialMediaController,
                decoration: const InputDecoration(labelText: 'Social Media'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Upload Business Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerBusiness,
                child: const Text('Register Business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
