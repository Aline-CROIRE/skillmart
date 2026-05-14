class Project {
  final String id;
  final String title;
  final String description;
  final String category;
  final int price;
  final String status;
  final String reviewNote;
  final String fileUrl;
  final String sellerName;
  final String sellerId;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    required this.fileUrl,
    required this.sellerName,
    required this.sellerId,
    this.reviewNote = "",
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    String name = "Community Member";
    String sid = "unknown";

    if (json['sellerId'] != null) {
      if (json['sellerId'] is Map) {
        name = json['sellerId']['name'] ?? "Member";
        sid = json['sellerId']['_id'] ?? "unknown";
      } else {
        sid = json['sellerId'].toString();
      }
    }

    return Project(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Work',
      description: json['description']?.toString() ?? 'No description.',
      category: json['category']?.toString() ?? 'General',
      price: (json['price'] is int) ? json['price'] : int.tryParse(json['price'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'pending',
      fileUrl: json['fileUrl']?.toString() ?? '',
      sellerName: name,
      sellerId: sid,
      reviewNote: json['reviewNote']?.toString() ?? '',
    );
  }
}