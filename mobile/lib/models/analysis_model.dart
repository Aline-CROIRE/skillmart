class Analysis {
  final int score;
  final String summary;
  final List<String> securityFindings;
  final Map<String, dynamic> qualityMetrics;

  Analysis({
    required this.score,
    required this.summary,
    required this.securityFindings,
    required this.qualityMetrics,
  });

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      score: json['score'] ?? 0,
      summary: json['summary'] ?? '',
      securityFindings: List<String>.from(json['securityFindings'] ?? []),
      qualityMetrics: json['qualityMetrics'] ?? {},
    );
  }
}