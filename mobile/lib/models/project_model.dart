class Project {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? fileUrl;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.fileUrl,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'pending',
      fileUrl: json['fileUrl'],
    );
  }
}