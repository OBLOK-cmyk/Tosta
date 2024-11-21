class Business {
  String? key;
  String name;
  String type;
  String location;
  String latlong;
  int? timestamp;
  String openingHours;
  String closingHours;
  List<String> photos;
  String description;
  double averageRating; // Add this field
  final double rating; // New property for the rating
  String? userId;

  Business({
    this.key,
    this.timestamp,
    required this.name,
    required this.type,
    required this.location,
    required this.latlong,
    required this.openingHours,
    required this.closingHours,
    required this.photos,
    required this.description,
    this.averageRating = 0.0, // Set a default value if needed
    this.rating = 0.0, // Default to 0.0 if not provided
    required this.userId,
  });

  // Convert Business object to a map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'location': location,
      'latlong' : latlong,
      'openingHours': openingHours,
      'closingHours': closingHours,
      'photos': photos,
      'description': description,
    };
  }
}
