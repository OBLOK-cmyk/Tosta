import 'dart:io'; // Import to use File
import 'package:flutter/material.dart';
import 'business.dart'; // Import the Business class
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';


class AddBusiness extends StatefulWidget {
  final Function(Map<String, dynamic>) onRegister;

  AddBusiness({required this.onRegister});

  @override
  _AddBusinessState createState() => _AddBusinessState();
}

class _AddBusinessState extends State<AddBusiness> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latlongController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _closingHoursController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? imageUrl; // Variable to store the uploaded image URL
  List<String> classifications = ["Tourist", "Food", "Adventure", "Cultural", "Relaxation", "Local", "International", "Street", "Vegan", "Seafood", "Desserts", "Beverages"];
  List<String> selectedClassifications = [];

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

      final business = Business(
        name: _nameController.text,
        type: selectedClassifications.join(', '),
        location: _locationController.text,
        latlong: _latlongController.text,
        openingHours: _openingHoursController.text,
        closingHours: _closingHoursController.text,
        photos: [imageUrl!], // Use the uploaded image URL safely
        description: _descriptionController.text,
        userId: null,
      );
      // Generate a unique ID for Firestore
      final uniqueSpotId =
          '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
      // Save business to Firebase
      final businessRef = FirebaseDatabase.instance.ref('all_touristspot').push();
      try {
        await businessRef.set(business.toJson()); // Await this call
        // Save to Firestore under tourist_spots
        final touristSpotRef =
        FirebaseFirestore.instance.collection('tourist_spots').doc(business.name);
        await touristSpotRef.set({
          'averageRating': 0,
          'category': business.type, // Assuming type represents the category
          'name': business.name,
          'reviewsCount': 0,
          'spotId': uniqueSpotId, // Generates a unique ID for spotId
          'visitCount': 0,
        });

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
        title: const Text('Add Establishment'),
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
                child: const Text('Add Business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
