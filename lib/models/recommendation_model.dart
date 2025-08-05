class Recommendation {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double confidenceScore;
  final List<String> tags;

  Recommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.confidenceScore,
    required this.tags,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    // Handle different field names and types
    final int parsedId = json['id'] is String 
        ? int.tryParse(json['id']) ?? 0 
        : json['id'] ?? 0;
    
    final String parsedName = json['name'] ?? 
        json['title'] ?? 
        'Unnamed Recommendation';
    
    final String parsedDescription = json['description'] ?? 
        json['desc'] ?? 
        'No description available';
    
    final String parsedImageUrl = json['image_url'] ?? 
        json['imageUrl'] ?? 
        '';
    
    final double parsedConfidenceScore = json['confidence_score'] != null 
        ? (json['confidence_score'] is double ? json['confidence_score'] : json['confidence_score'].toDouble()) 
        : json['score'] != null 
            ? (json['score'] is double ? json['score'] : json['score'].toDouble())
            : 0.0;
    
    final List<String> parsedTags = json['tags'] != null 
        ? List<String>.from(json['tags']) 
        : [];

    return Recommendation(
      id: parsedId,
      name: parsedName,
      description: parsedDescription,
      imageUrl: parsedImageUrl,
      confidenceScore: parsedConfidenceScore,
      tags: parsedTags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'confidence_score': confidenceScore,
      'tags': tags,
    };
  }
}

class OutfitRecommendation {
  final int outfitNumber;
  final Map<String, String> components;

  OutfitRecommendation({
    required this.outfitNumber,
    required this.components,
  });

  factory OutfitRecommendation.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendation(
      outfitNumber: json['outfit_number'] ?? 0,
      components: Map<String, String>.from(json['components'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outfit_number': outfitNumber,
      'components': components,
    };
  }

  static List<OutfitRecommendation> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => OutfitRecommendation.fromJson(json)).toList();
  }
}
