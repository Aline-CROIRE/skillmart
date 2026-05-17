class Project {
  final String id;
  final String title;
  final String description;
  final String category;
  final int price;
  final String status;
  final String reviewNote;
  final String fileUrl;
  final String thumbnailUrl;
  final String sellerName;
  final String sellerId;

  // New fields
  final String ownerType;
  final String ownerName;
  final String ceoName;
  final String linkedinUrl;
  final String projectType;
  final String externalLink;
  final String rdbRegistrationNumber;
  final String proposalUrl;
  final String rdbProofUrl;
  final String incomeStatementUrl;
  final String rraTaxHistoryUrl;
  final String rraClearanceUrl;
  final String pitchVideoUrl;
  final bool isShareholderSeeking;
  final int maxShareholders;
  final int totalSharesAvailable;
  final int minShare;
  final int shareValue;

  final String analyticsFileUrl;
  final List<dynamic> analyticsAccessRequests;

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
    this.thumbnailUrl = "",
    this.reviewNote = "",
    this.ownerType = "Individual",
    this.ownerName = "",
    this.ceoName = "",
    this.linkedinUrl = "",
    this.projectType = "Business Idea",
    this.externalLink = "",
    this.rdbRegistrationNumber = "",
    this.proposalUrl = "",
    this.rdbProofUrl = "",
    this.incomeStatementUrl = "",
    this.rraTaxHistoryUrl = "",
    this.rraClearanceUrl = "",
    this.pitchVideoUrl = "",
    this.analyticsFileUrl = "",
    this.analyticsAccessRequests = const [],
    this.isShareholderSeeking = false,
    this.maxShareholders = 0,
    this.totalSharesAvailable = 0,
    this.minShare = 0,
    this.shareValue = 0,
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
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      sellerName: name,
      sellerId: sid,
      reviewNote: json['reviewNote']?.toString() ?? '',
      ownerType: json['ownerType']?.toString() ?? 'Individual',
      ownerName: json['ownerName']?.toString() ?? '',
      ceoName: json['ceoName']?.toString() ?? '',
      linkedinUrl: json['linkedinUrl']?.toString() ?? '',
      projectType: json['projectType']?.toString() ?? 'Business Idea',
      externalLink: json['externalLink']?.toString() ?? '',
      rdbRegistrationNumber: json['rdbRegistrationNumber']?.toString() ?? '',
      proposalUrl: json['proposalUrl']?.toString() ?? '',
      rdbProofUrl: json['rdbProofUrl']?.toString() ?? '',
      incomeStatementUrl: json['incomeStatementUrl']?.toString() ?? '',
      rraTaxHistoryUrl: json['rraTaxHistoryUrl']?.toString() ?? '',
      rraClearanceUrl: json['rraClearanceUrl']?.toString() ?? '',
      pitchVideoUrl: json['pitchVideoUrl']?.toString() ?? '',
      analyticsFileUrl: json['analyticsFileUrl']?.toString() ?? '',
      analyticsAccessRequests: json['analyticsAccessRequests'] ?? [],
      isShareholderSeeking: json['isShareholderSeeking'] ?? false,
      maxShareholders: json['maxShareholders'] ?? 0,
      totalSharesAvailable: json['totalSharesAvailable'] ?? 0,
      minShare: json['minShare'] ?? 0,
      shareValue: json['shareValue'] ?? 0,
    );
  }
}