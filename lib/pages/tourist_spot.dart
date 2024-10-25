class TouristSpot {
  final String id;
  final String name;
  final String category; // New category field
  final String imageUrl;
  bool isFavorite;
  int views; // Added views count
  double rating; // Added rating

  TouristSpot({
    required this.id,
    required this.name,
    this.category = '', // New category field
    required this.imageUrl,
    this.isFavorite = false, // Default value for isFavorite
    this.views = 0, // Default value for views
    this.rating = 0.0, // Default value for rating
  });

  String get description => '$name is a great place to visit!';

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}
