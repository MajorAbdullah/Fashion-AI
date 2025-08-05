import 'package:flutter/material.dart';
import 'package:thefashionai/app_theme.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'virtual_try_on.dart';

class BrandPage extends StatefulWidget {
  final String brandName;

  const BrandPage({
    Key? key,
    required this.brandName,
  }) : super(key: key);

  @override
  _BrandPageState createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage> with SingleTickerProviderStateMixin {
  List<BrandItem> _items = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  // Method to send a clothing image to the Virtual Try-On feature
  Future<void> _sendToTryOn(BuildContext context, String assetPath) async {
    try {
      // Load the image from assets
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Get temporary directory to save the image
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/try_on_clothing.jpg';
      
      // Save the image to temporary storage
      final File file = File(tempPath);
      await file.writeAsBytes(bytes);
      
      // Store the path in SharedPreferences for the Try-On page to access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('clothing_image_path', tempPath);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image sent to Virtual Try-On'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Go to Try-On',
            onPressed: () {
              // Navigate to the Virtual Try-On tab (index 2 in the bottom navigation)
              Navigator.of(context).pop(); // Go back to the home page
              // Update the index in the parent to show the Try-On tab
              // This requires a callback from HomePage which we'll implement separately
            },
          ),
        ),
      );
    } catch (e) {
      print('Error sending image to Try-On: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image to Try-On'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadBrandImages();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<String>> _loadManifest() async {
    try {
      // Load the AssetManifest.json file which contains all the assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Get all the asset paths
      return manifestMap.keys.where((key) {
        // Only include image files (with extensions like jpg, jpeg, png, etc)
        final ext = path_util.extension(key).toLowerCase();
        return ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp' || ext == '.gif';
      }).toList();
    } catch (e) {
      print('Error loading asset manifest: $e');
      return [];
    }
  }

  Future<void> _loadBrandImages() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Define the folder paths for men and women
      final String menFolderPath = 'assets/All Brands/${widget.brandName} Men';
      final String womenFolderPath = 'assets/All Brands/${widget.brandName} Women';
      
      // Load all asset paths from the manifest
      List<String> allAssetPaths = await _loadManifest();
      
      // Debug output - print all found asset paths
      print('Found ${allAssetPaths.length} total assets in manifest');
      
      // Filter assets for this brand (both men's and women's)
      List<String> brandMenAssets = allAssetPaths
          .where((path) => path.startsWith(menFolderPath))
          .toList();
          
      List<String> brandWomenAssets = allAssetPaths
          .where((path) => path.startsWith(womenFolderPath))
          .toList();
      
      print('Found ${brandMenAssets.length} men\'s assets and ${brandWomenAssets.length} women\'s assets for ${widget.brandName}');
      
      // Output examples of found paths for debugging
      if (brandMenAssets.isNotEmpty) {
        print('Example men\'s asset: ${brandMenAssets.first}');
      }
      if (brandWomenAssets.isNotEmpty) {
        print('Example women\'s asset: ${brandWomenAssets.first}');
      }
      
      List<BrandItem> items = [];
      
      // If no real assets found, fall back to sample assets for demonstration
      if (brandMenAssets.isEmpty && brandWomenAssets.isEmpty) {
        print('No assets found, using sample images');
        _useSampleImages();
        return;
      }
      
      // Process men's assets - tag them as "Men"
      for (String path in brandMenAssets) {
        // Extract category from subfolder path
        String category = _extractCategoryFromPath(path, menFolderPath, 'Men');
        String name = _formatImageName(path);
        
        items.add(
          BrandItem(
            id: 'men_${items.length}',
            name: name,
            gender: 'Men',
            category: category,
            imagePath: path,
            price: 59.99 + (items.length % 10) * 5,
          )
        );
      }
      
      // Process women's assets - tag them as "Women"
      for (String path in brandWomenAssets) {
        // Extract category from subfolder path
        String category = _extractCategoryFromPath(path, womenFolderPath, 'Women');
        String name = _formatImageName(path);
        
        items.add(
          BrandItem(
            id: 'women_${items.length}',
            name: name,
            gender: 'Women',
            category: category,
            imagePath: path,
            price: 69.99 + (items.length % 10) * 5,
          )
        );
      }
      
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading brand images: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Use sample images on error
      _useSampleImages();
    }
  }
  
  // Extract category from file path - improved to handle nested subfolders
  String _extractCategoryFromPath(String path, String basePath, String defaultCategory) {
    try {
      // Remove the base path to get the relative path
      String relativePath = path.substring(basePath.length);
      
      // Ensure the path starts with a separator
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
      
      // Split the relative path into components
      List<String> pathComponents = relativePath.split('/');
      
      // If there's a subfolder, use it as category
      if (pathComponents.length > 1) {
        String subfolder = pathComponents[0];
        // Clean up the category name
        return _formatCategoryName(subfolder);
      }
      
      // No subfolder, use default category
      return defaultCategory;
    } catch (e) {
      print('Error extracting category: $e');
      return defaultCategory;
    }
  }
  
  // Format a category name to make it more presentable
  String _formatCategoryName(String category) {
    // Replace underscores and hyphens with spaces
    category = category.replaceAll(RegExp(r'[_-]'), ' ');
    
    // Capitalize each word
    List<String> words = category.split(' ');
    words = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return '';
    }).toList();
    
    return words.join(' ');
  }
  
  // Format an image name to make it more presentable
  String _formatImageName(String path) {
    // Extract filename without extension
    String fileName = path.split('/').last.split('.').first;
    
    // Remove any numbers at the start
    fileName = fileName.replaceAll(RegExp(r'^\d+[\s_-]*'), '');
    
    // Replace underscores and hyphens with spaces
    fileName = fileName.replaceAll(RegExp(r'[_-]'), ' ');
    
    // Capitalize each word
    List<String> words = fileName.split(' ');
    words = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return '';
    }).toList();
    
    return words.join(' ');
  }
  
  // Use sample images when real images aren't available
  void _useSampleImages() {
    List<BrandItem> items = [];
    
    // Sample Men's items
    for (int i = 1; i <= 5; i++) {
      items.add(
        BrandItem(
          id: 'men_sample_$i',
          name: '${widget.brandName} Men\'s Item $i',
          gender: 'Men',
          category: 'Men\'s Collection',
          imagePath: 'assets/images/${i * 2} casual.jpg',
          price: 59.99 + (i * 10),
        )
      );
    }
    
    // Sample Women's items
    for (int i = 1; i <= 5; i++) {
      items.add(
        BrandItem(
          id: 'women_sample_$i',
          name: '${widget.brandName} Women\'s Item $i',
          gender: 'Women',
          category: 'Women\'s Collection',
          imagePath: 'assets/images/${35 + i} tshirt.jpg',
          price: 69.99 + (i * 10),
        )
      );
    }
    
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.brandName} Collection'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Items'),
            Tab(text: 'Men'),
            Tab(text: 'Women'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.pink.shade50],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${widget.brandName} Collection',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All Items Tab
                  _buildItemsGrid(_items),
                  
                  // Men's Tab
                  _buildItemsGrid(_items.where((item) => item.gender == 'Men').toList()),
                  
                  // Women's Tab
                  _buildItemsGrid(_items.where((item) => item.gender == 'Women').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsGrid(List<BrandItem> items) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No items found in this collection',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildProductCard(context, items[index], index);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, BrandItem item, int index) {
    final Color genderColor = item.gender == 'Men' 
        ? Colors.blue.withOpacity(0.7) 
        : Colors.pink.withOpacity(0.7);
    
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Actual image with fallback
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading image: ${item.imagePath}");
                      return Container(
                        color: item.gender == 'Men' ? Colors.blue[100] : Colors.pink[100],
                        child: Icon(
                          item.gender == 'Men' ? Icons.person : Icons.person_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  
                  // Gender tag
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: genderColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.gender,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Product Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category label
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                ),
                
                SizedBox(height: 4),
                
                // Item name
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Try On button
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.checkroom, size: 16),
                    label: Text('Try On', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _sendToTryOn(context, item.imagePath),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BrandItem {
  final String id;
  final String name;
  final String gender;
  final String category;
  final String imagePath;
  final double price;

  BrandItem({
    required this.id,
    required this.name,
    required this.gender,
    required this.category,
    required this.imagePath,
    required this.price,
  });
}