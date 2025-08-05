import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:path/path.dart' as path_util;

class CategoryItem {
  final String name;
  final String gender;
  final String brand;
  final String imagePath;

  CategoryItem({
    required this.name,
    required this.gender,
    required this.brand,
    required this.imagePath,
  });
}

class CategoryManager {
  // Singleton pattern
  static final CategoryManager _instance = CategoryManager._internal();
  factory CategoryManager() => _instance;
  CategoryManager._internal();

  // Maps to store category information
  Map<String, List<CategoryItem>> _categoryMap = {};
  List<String> _categoryNames = [];
  Map<String, String> _categoryThumbnails = {};
  bool _initialized = false;

  // Getters
  List<String> get categoryNames => _categoryNames;
  Map<String, String> get categoryThumbnails => _categoryThumbnails;
  bool get isInitialized => _initialized;

  // Initialize the category manager by scanning assets
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get all asset paths
      List<String> allAssetPaths = await _loadAllImageAssets();
      
      // Map to hold categories temporarily
      Map<String, List<CategoryItem>> tempCategoryMap = {};
      
      // Process all brand images
      for (String assetPath in allAssetPaths) {
        // Only process images in the All Brands directory
        if (!assetPath.contains('assets/All Brands/')) continue;
        
        // Extract path components
        List<String> pathComponents = assetPath.split('/');
        
        // Path should be like: assets/All Brands/Brand Men/image.jpg
        if (pathComponents.length < 4) continue;
        
        String brandGender = pathComponents[2]; // e.g., "Break Out Men"
        String filename = pathComponents.last; // e.g., "shoes 1.png"
        
        // Extract brand and gender
        String brand = '';
        String gender = '';
        
        if (brandGender.contains(' Men')) {
          brand = brandGender.replaceAll(' Men', '');
          gender = 'Men';
        } else if (brandGender.contains(' Women')) {
          brand = brandGender.replaceAll(' Women', '');
          gender = 'Women';
        } else {
          continue; // Skip if can't determine gender
        }
        
        // Extract category from filename
        String category = _extractCategoryFromFilename(filename);
        if (category.isEmpty) continue;
        
        // Create a category item
        CategoryItem item = CategoryItem(
          name: _formatName(filename),
          gender: gender,
          brand: brand,
          imagePath: assetPath,
        );
        
        // Add to appropriate category
        if (!tempCategoryMap.containsKey(category)) {
          tempCategoryMap[category] = [];
        }
        tempCategoryMap[category]!.add(item);
      }
      
      // Update the category map
      _categoryMap = tempCategoryMap;
      
      // Get sorted category names
      _categoryNames = _categoryMap.keys.toList()..sort();
      
      // Select thumbnail for each category (first image of each category)
      for (String category in _categoryNames) {
        if (_categoryMap[category]!.isNotEmpty) {
          _categoryThumbnails[category] = _categoryMap[category]!.first.imagePath;
        }
      }
      
      _initialized = true;
      print('CategoryManager initialized with ${_categoryNames.length} categories');
    } catch (e) {
      print('Error initializing CategoryManager: $e');
    }
  }
  
  // Get items for a specific category
  List<CategoryItem> getItemsForCategory(String category) {
    return _categoryMap[category] ?? [];
  }
  
  // Load all image assets from the manifest
  Future<List<String>> _loadAllImageAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      return manifestMap.keys.where((key) {
        // Only include image files
        final ext = path_util.extension(key).toLowerCase();
        return ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp' || ext == '.gif';
      }).toList();
    } catch (e) {
      print('Error loading asset manifest: $e');
      return [];
    }
  }
  
  // Extract category from filename
  String _extractCategoryFromFilename(String filename) {
    // Remove extension
    String nameWithoutExt = path_util.basenameWithoutExtension(filename).toLowerCase();
    
    // Common categories to detect
    final Map<String, List<String>> categoryKeywords = {
      'Shoes': ['shoes', 'sneakers', 'footwear', 'boots'],
      'Shirts': ['shirt', 'tshirt', 't-shirt', 'tee', 'polo'],
      'Pants': ['pant', 'trouser', 'jeans', 'slacks'],
      'Dresses': ['dress', 'gown', 'frock'],
      'Jackets': ['jacket', 'coat', 'blazer', 'hoodie'],
      'Formal': ['formal', 'suit', 'tuxedo'],
      'Casual': ['casual'],
      'Sportswear': ['sport', 'gym', 'athletic', 'workout'],
    };
    
    for (var entry in categoryKeywords.entries) {
      for (String keyword in entry.value) {
        if (nameWithoutExt.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    // If no specific category found but contains numbers, 
    // it might be a numeric naming pattern - use the text part
    if (RegExp(r'^\d+\s+(.+)$').hasMatch(nameWithoutExt)) {
      final match = RegExp(r'^\d+\s+(.+)$').firstMatch(nameWithoutExt);
      if (match != null && match.group(1) != null) {
        String category = match.group(1)!;
        // Capitalize first letter
        return category[0].toUpperCase() + category.substring(1);
      }
    }
    
    return 'Other';
  }
  
  // Format filename into a presentable name
  String _formatName(String filename) {
    // Remove extension
    String nameWithoutExt = path_util.basenameWithoutExtension(filename);
    
    // Remove any numbers at the start
    nameWithoutExt = nameWithoutExt.replaceAll(RegExp(r'^\d+\s*'), '');
    
    // Replace underscores and hyphens with spaces
    nameWithoutExt = nameWithoutExt.replaceAll(RegExp(r'[_-]'), ' ');
    
    // Capitalize each word
    List<String> words = nameWithoutExt.split(' ');
    words = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return '';
    }).toList();
    
    return words.join(' ').trim();
  }
}