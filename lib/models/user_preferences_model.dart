class UserPreferences {
  final String? gender;
  final List<String>? itemTypes;
  final List<String>? styleVibes;
  final List<String>? favoriteColors;
  final List<String>? preferredMaterials;
  final List<String>? keyOccasions;
  final List<String>? primarySeasons;
  final String? casualOutfitStyle;
  final String? formalOutfitColor;
  final String? specificOccasion;
  final Map<String, ItemSpecificPreference>? itemSpecificPreferences;

  UserPreferences({
    this.gender,
    this.itemTypes,
    this.styleVibes,
    this.favoriteColors,
    this.preferredMaterials,
    this.keyOccasions,
    this.primarySeasons,
    this.casualOutfitStyle,
    this.formalOutfitColor,
    this.specificOccasion,
    this.itemSpecificPreferences,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    Map<String, ItemSpecificPreference> itemPrefs = {};
    
    if (json['item_specific_preferences'] != null) {
      final Map<String, dynamic> itemPrefsJson = json['item_specific_preferences'];
      
      itemPrefsJson.forEach((key, value) {
        itemPrefs[key] = ItemSpecificPreference.fromJson(value);
      });
    }
    
    return UserPreferences(
      gender: json['gender'],
      itemTypes: json['item_types'] != null ? List<String>.from(json['item_types']) : null,
      styleVibes: json['style_vibes'] != null ? List<String>.from(json['style_vibes']) : null,
      favoriteColors: json['favorite_colors'] != null ? List<String>.from(json['favorite_colors']) : null,
      preferredMaterials: json['preferred_materials'] != null ? List<String>.from(json['preferred_materials']) : null,
      keyOccasions: json['key_occasions'] != null ? List<String>.from(json['key_occasions']) : null,
      primarySeasons: json['primary_seasons'] != null ? List<String>.from(json['primary_seasons']) : null,
      casualOutfitStyle: json['casual_outfit_style'],
      formalOutfitColor: json['formal_outfit_color'],
      specificOccasion: json['specific_occasion'],
      itemSpecificPreferences: itemPrefs.isEmpty ? null : itemPrefs,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (gender != null) data['gender'] = gender;
    if (itemTypes != null) data['item_types'] = itemTypes;
    if (styleVibes != null) data['style_vibes'] = styleVibes;
    if (favoriteColors != null) data['favorite_colors'] = favoriteColors;
    if (preferredMaterials != null) data['preferred_materials'] = preferredMaterials;
    if (keyOccasions != null) data['key_occasions'] = keyOccasions;
    if (primarySeasons != null) data['primary_seasons'] = primarySeasons;
    if (casualOutfitStyle != null) data['casual_outfit_style'] = casualOutfitStyle;
    if (formalOutfitColor != null) data['formal_outfit_color'] = formalOutfitColor;
    if (specificOccasion != null) data['specific_occasion'] = specificOccasion;
    
    if (itemSpecificPreferences != null) {
      final Map<String, dynamic> itemPrefsJson = {};
      
      itemSpecificPreferences!.forEach((key, value) {
        itemPrefsJson[key] = value.toJson();
      });
      
      data['item_specific_preferences'] = itemPrefsJson;
    }
    
    return data;
  }
}

class ItemSpecificPreference {
  final List<String>? colors;
  final List<String>? materials;

  ItemSpecificPreference({
    this.colors,
    this.materials,
  });

  factory ItemSpecificPreference.fromJson(Map<String, dynamic> json) {
    return ItemSpecificPreference(
      colors: json['colors'] != null ? List<String>.from(json['colors']) : null,
      materials: json['materials'] != null ? List<String>.from(json['materials']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (colors != null) data['colors'] = colors;
    if (materials != null) data['materials'] = materials;
    
    return data;
  }
}
