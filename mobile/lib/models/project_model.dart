class Project {
  final String id;
  final String title;
  final String description;
  final String category;
  final int price;

  Project({
    required this.id, 
    required this.title, 
    required this.description, 
    required this.category, 
    required this.price
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Project',
      description: json['description'] ?? 'No description provided.',
      category: json['category'] ?? 'General',
      price: json['price'] ?? 0,
    );
  }
}