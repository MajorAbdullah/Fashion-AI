import 'package:flutter/material.dart';
import 'package:thefashionai/app_theme.dart';
import 'package:thefashionai/category_manager.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnifiedCategoryPage extends StatefulWidget {
  final String categoryName;

  const UnifiedCategoryPage({
    Key? key,
    required this.categoryName,
  }) : super(key: key);

  @override
  _UnifiedCategoryPageState createState() => _UnifiedCategoryPageState();
}

class _UnifiedCategoryPageState extends State<UnifiedCategoryPage> with SingleTickerProviderStateMixin {
  List<CategoryItem> _items = [];
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
    _loadCategoryItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCategoryItems() async {
    try {
      // Ensure the CategoryManager is initialized
      final categoryManager = CategoryManager();
      if (!categoryManager.isInitialized) {
        await categoryManager.initialize();
      }
      
      // Get items for this category
      final items = categoryManager.getItemsForCategory(widget.categoryName);
      
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading category items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
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
                '${widget.categoryName} Collection',
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

  Widget _buildItemsGrid(List<CategoryItem> items) {
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
                'No items found in this category',
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
        return _buildItemCard(context, items[index], index);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, CategoryItem item, int index) {
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
                  
                  // Brand and gender tags
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Brand tag
                        Container(
                          margin: EdgeInsets.only(bottom: 4),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.brand,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Gender tag
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: genderColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.gender,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                  widget.categoryName,
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
                
                // Try-On button
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