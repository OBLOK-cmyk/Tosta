class Business {
  String name;
  String type;
  String location;
  String openingHours;
  String closingHours;
  List<String> photos;
  String description;
  String? phoneNumber;
  String? email;
  String? socialMedia;

  Business({
    required this.name,
    required this.type,
    required this.location,
    required this.openingHours,
    required this.closingHours,
    required this.photos,
    required this.description,
    this.phoneNumber,
    this.email,
    this.socialMedia,
  });

  // Convert Business object to a map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'location': location,
      'openingHours': openingHours,
      'closingHours': closingHours,
      'photos': photos,
      'description': description,
      'phoneNumber': phoneNumber,
      'email': email,
      'socialMedia': socialMedia,
    };
  }
}
