import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'profilepage.dart';
import 'fashion_bot.dart' hide ApiService;
import 'virtual_try_on.dart';
import 'wardrobe.dart';
import 'app_theme.dart';
import 'brand_page.dart';
import 'category_manager.dart';
import 'unified_category_page.dart';
import 'models/recommendation_model.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'screens/outfit_details_screen.dart';
import 'screens/choice_screen.dart';  // Added import for ChoiceScreen

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/bg2.jpg',
            fit: BoxFit.fill,
          ),
        ),
        // Background Overlay for better readability
        Positioned.fill(
          child: Container(
            color: Colors.pinkAccent.withOpacity(0.1),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _profileImagePath;

  final List<Widget> _pages = [
    HomeContent(),
    AIFashionPage(),
    VirtualTryOn(rapidApiKey: dotenv.env['RAPIDAPI_KEY'] ?? ''),
    WardrobePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? "User";

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: AppTheme.primaryColor,
        activeColor: Colors.white,
        color: Colors.white70,
        items: [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.auto_awesome, title: 'AI Fashion'),
          TabItem(icon: Icons.checkroom, title: 'Try On'),
          TabItem(icon: Icons.dashboard_outlined, title: 'Wardrobe'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "Fashion AI",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(profileImagePath: _profileImagePath),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                    : AssetImage('assets/logo.jpg') as ImageProvider,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final CategoryManager _categoryManager = CategoryManager();
  bool _isCategoryLoading = true;
  List<String> _categories = [];
  Map<String, String> _categoryThumbnails = {};
  
  // Add API and Storage service
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  List<OutfitRecommendation> _recommendedOutfits = [];
  bool _isOutfitsLoading = true;

  final List<Map<String, String>> brands = [
    {"name": "Breakout", "image": "assets/logo1.webp"},
    {"name": "Chase Value", "image": "assets/logo2.jpg"},
    {"name": "Ideas", "image": "assets/logo3.png"},
    {"name": "Outfitter", "image": "assets/logo4.jpg"},
  ];

  final Map<String, String> brandMapping = {
    "Breakout": "Break Out",
    "Chase Value": "Chase Value",
    "Ideas": "Ideas",
    "Outfitter": "Outfitter",
  };
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadRecommendedOutfits(); // Add this line to load outfit recommendations
  }
  
  // Add method to load outfit recommendations
  Future<void> _loadRecommendedOutfits() async {
    try {
      // Try to get saved recommendations
      final recommendations = await _storageService.getRecommendations();
      
      if (recommendations != null && recommendations.isNotEmpty) {
        setState(() {
          _recommendedOutfits = recommendations;
          _isOutfitsLoading = false;
        });
      } else {
        // If no saved recommendations, create dummy data for display
        setState(() {
          _recommendedOutfits = [
            OutfitRecommendation(
              outfitNumber: 1,
              components: {
                'topwear': 'Classic White Shirt',
                'bottomwear': 'Navy Blue Jeans',
                'footwear': 'Brown Leather Loafers'
              }
            ),
            OutfitRecommendation(
              outfitNumber: 2,
              components: {
                'topwear': 'Gray Crewneck Sweater',
                'bottomwear': 'Khaki Chinos',
                'footwear': 'White Sneakers'
              }
            ),
            OutfitRecommendation(
              outfitNumber: 3,
              components: {
                'topwear': 'Black Turtleneck',
                'bottomwear': 'Dark Gray Trousers',
                'footwear': 'Black Derby Shoes'
              }
            ),
          ];
          _isOutfitsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading outfit recommendations: $e');
      setState(() {
        _isOutfitsLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      if (!_categoryManager.isInitialized) {
        await _categoryManager.initialize();
      }

      setState(() {
        _categories = _categoryManager.categoryNames;
        _categoryThumbnails = _categoryManager.categoryThumbnails;
        _isCategoryLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isCategoryLoading = false;
      });
    }
  }

  Widget _buildBrandPage(String brandName) {
    // Map the displayed brand name to the folder name format
    String folderBrandName = brandMapping[brandName] ?? brandName;

    // Use the BrandPage that handles both men's and women's items
    return BrandPage(
      brandName: folderBrandName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChoiceScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      "AI Outfit Recommendations",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text("Popular Brands", style: _sectionStyle()),
              SizedBox(height: 10),
              _buildBrandsList(context),

              SizedBox(height: 20),
              Text("Categories", style: _sectionStyle()),
              SizedBox(height: 10),
              _buildCategoriesList(context),              SizedBox(height: 20),
              Text("Outfit Ideas", style: _sectionStyle()),
              SizedBox(height: 10),
              _buildOutfitIdeas(context),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionStyle() {
    return AppTheme.subheadingStyle.copyWith(color: Colors.black);
  }

  Widget _buildBrandsList(BuildContext context) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _buildBrandPage(brands[index]["name"]!),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(brands[index]["image"]!),
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading brand image: ${exception}');
                    },
                  ),
                  SizedBox(height: 8),
                  Text(
                    brands[index]["name"]!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildOutfitIdeas(BuildContext context) {
    if (_isOutfitsLoading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      );
    }

    if (_recommendedOutfits.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('No outfit ideas available'),
      );
    }

    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedOutfits.length,
        itemBuilder: (context, index) {
          final outfit = _recommendedOutfits[index];
          return _buildOutfitCard(context, outfit);
        },
      ),
    );
  }

  Widget _buildOutfitCard(BuildContext context, OutfitRecommendation outfit) {
    // Extract main component parts for display
    String topwear = outfit.components['topwear'] ?? 'Top';
    String bottomwear = outfit.components['bottomwear'] ?? 'Bottom';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutfitDetailsScreen(outfit: outfit),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        width: 160,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Outfit header
                Row(
                  children: [
                    Icon(Icons.checkroom, color: AppTheme.primaryColor),
                    SizedBox(width: 6),
                    Text(
                      'Outfit ${outfit.outfitNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                Divider(),
                
                // Top component
                Text(
                  'Top: $topwear',
                  style: TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 4),
                
                // Bottom component
                Text(
                  'Bottom: $bottomwear',
                  style: TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                Spacer(),
                
                // View details button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context) {
    if (_isCategoryLoading) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text('No categories found'),
      );
    }

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final categoryName = _categories[index];
          final thumbnailPath = _categoryThumbnails[categoryName] ??
              'assets/images/3 casual.jpg'; // Fallback image

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnifiedCategoryPage(
                    categoryName: categoryName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      thumbnailPath,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading category thumbnail: $thumbnailPath');
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    categoryName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AIFashionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: ChatScreen(),
    );
  }
}
