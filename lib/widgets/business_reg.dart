import 'dart:io'; // Import to use File
import 'package:flutter/material.dart';
import 'business.dart'; // Import the Business class
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
  final TextEditingController _latlongController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _closingHoursController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? userId;

  String? imageUrl; // Variable to store the uploaded image URL
  List<String> classifications = ["Tourist", "Food", "Adventure", "Cultural", "Relaxation", "Local", "International", "Street", "Vegan", "Seafood", "Desserts", "Beverages"];
  List<String> selectedClassifications = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Show the modal dialog when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRegistrationGuide();
    });
  }
  void _showRegistrationGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Register Your Business for Viewing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 1: Provide Business Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('Fill out the registration form with the following required information:'),
                const SizedBox(height: 8),
                const Text('- Business Name: Enter the official name of your business.'),
                const Text('- Description: Write a short description highlighting your business\'s unique features.'),
                const Text('- Category: Select the category of your business (e.g., Tourist Spot, Food Spot).'),
                const Text('- Business Location:'),
                const Text('  • Manually enter the address.'),
                const Text('- Pin Location:'),
                const Text('  • Use the map tool to pinpoint your exact location to capture the latitude and longitude to input like this (e.g., 14.3376 12.325632).'),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15.0), // Adjust radius as needed
                  child: Image.asset(
                    'assets/images/example.jpg', // Replace with your image path
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                const Text(
                  'Step 2: Upload Required Documents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('You need to upload the following:'),
                const SizedBox(height: 8),
                const Text('- A Photo of Your Business: Ensure it is clear and well-lit.'),
                const Text('- Business Permit: A valid copy showing your business is authorized to operate.'),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                const Text(
                  'Step 3: Review and Submit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('- Double-check all the details and uploaded documents to ensure accuracy.'),
                const Text('- Tap the Submit button to send your application for review.'),
                const Divider(height: 20, thickness: 1, color: Colors.grey),
                const Text(
                  'Important Reminders',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 8),
                const Text('- Incomplete or incorrect information may delay the approval process.'),
                const Text('- Ensure your uploaded documents are clear and valid.'),
                const Text('- You will be notified once your application is reviewed and approved.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    // Open the file picker to allow selecting media files (photos, videos)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media, // Allows media files like photos and videos
      allowMultiple: false, // Set to true if you want to select multiple files
    );

    if (result != null) {
      // Get the picked file
      File file = File(result.files.single.path!);
      print('File picked: ${file.path}');

      // You can check the file extension here if needed
      String fileExtension = file.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        // Proceed to upload the image
        await _uploadImage(file);
      } else {
        print('Selected file is not an image');
      }
    } else {
      // User canceled the picker
      print('No file selected');
    }
  }

  Future<void> _uploadImage(File file) async {
    try {
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('business_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      // Upload the image
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update state with the new image URL
      setState(() {
        imageUrl = downloadUrl;
      });
      print('Image uploaded successfully: $imageUrl');
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

  void _registerBusiness() async{
    if (_formKey.currentState!.validate()) {
      if (imageUrl == null || imageUrl!.isEmpty) {
        print('No image uploaded'); // Handle this case appropriately
        return; // Optionally return or show a message to the user
      }
      // Get the current user's ID
      String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        print("User is not logged in.");
        return;
      }
      final business = Business(
        name: _nameController.text,
        type: selectedClassifications.join(', '),
        location: _locationController.text,
        latlong: _latlongController.text,
        openingHours: _openingHoursController.text,
        closingHours: _closingHoursController.text,
        photos: [imageUrl!], // Use the uploaded image URL safely
        description: _descriptionController.text,
        userId: userId, // Add userId to the business object
      );

      // Save business to Firebase
      final businessRef = FirebaseDatabase.instance.ref('businesses').push();
      try {
        await businessRef.set(business.toJson()); // Await this call
        widget.onRegister(business.toJson());
        Navigator.pop(context); // Go back after registration
      } catch (error) {
        print('Error saving business: $error');
      }
    }
  }

  Widget _buildClassificationCards() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: classifications.map((classification) {
        final isSelected = selectedClassifications.contains(classification);
        return GestureDetector(
          onTap: () {
            setState(() {
              isSelected ? selectedClassifications.remove(classification) : selectedClassifications.add(classification);
            });
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            color: isSelected ? Colors.red.shade800 : Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                classification,
                style: TextStyle(color: isSelected ? Colors.white : Colors.black),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Establishment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)), // Border radius for input fields
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a business name' : null,
              ),
              const SizedBox(height: 10),
              const Text("Classification", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              _buildClassificationCards(),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _latlongController,
                decoration: const InputDecoration(
                  labelText: 'Pin Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter latitude and longitude' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _openingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Opening Hours',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter opening hours' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _closingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Closing Hours',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter closing hours' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Display uploaded image
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Column(
                  children: [
                    const Text(
                      "Uploaded Image",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Image.network(
                      imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red)
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Error loading image');
                      },
                    ),

                  ],
                )
              else
                const Text("No image uploaded yet."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800, // Button background color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0), // Button padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                ),
                child: const Text('Upload Business Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerBusiness,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800, // Button background color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0), // Button padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                ),
                child: const Text('Register Business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
