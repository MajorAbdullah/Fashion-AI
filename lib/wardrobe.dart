import 'package:flutter/material.dart';
import 'package:crazy/crazy_app_widget.dart';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WardrobePage extends StatefulWidget {
  @override
  _WardrobePageState createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  late SharedPreferences _prefs; // Declare _prefs as late
  List<String> _quizTags = [];
  List<dynamic> _quizRecommendations = [];
  bool _quizCompleted = false;
  bool _isSavingData = false;

  @override
  void initState() {
    super.initState();
    _initializePreferences(); // Initialize _prefs
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {}); // Trigger a rebuild after initialization
  }

  // Save quiz data to Firestore
  Future<void> _saveQuizDataToFirestore(List<String> tags, List<dynamic> recommendations) async {
    setState(() {
      _isSavingData = true;
    });
    
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Create a structured survey data object from quiz results
        Map<String, dynamic> surveyData = {
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Process tags into meaningful categories for profile display
        if (tags.isNotEmpty) {
          // Example tag processing - adjust based on actual data structure from CrazyAppWidget
          List<String> stylePreferences = [];
          List<String> colorPreferences = [];
          List<String> clothingTypes = [];
          
          for (String tag in tags) {
            if (tag.contains('style:')) {
              stylePreferences.add(tag.replaceAll('style:', '').trim());
            } else if (tag.contains('color:')) {
              colorPreferences.add(tag.replaceAll('color:', '').trim());
            } else if (tag.contains('clothing:')) {
              clothingTypes.add(tag.replaceAll('clothing:', '').trim());
            }
          }
          
          // Add processed categories to survey data
          if (stylePreferences.isNotEmpty) surveyData['Style'] = stylePreferences;
          if (colorPreferences.isNotEmpty) {
            surveyData['Color Palette'] = colorPreferences.join(', ');
          }
          if (clothingTypes.isNotEmpty) surveyData['Clothing Type'] = clothingTypes;
          
          // Add some default values if certain categories are empty
          if (!surveyData.containsKey('Gender')) {
            surveyData['Gender'] = 'Not specified';
          }
        }
        
        // Store recommendations URLs
        if (recommendations.isNotEmpty) {
          List<String> recommendationUrls = [];
          for (var item in recommendations) {
            if (item.containsKey('imageUrl')) {
              recommendationUrls.add(item['imageUrl']);
            }
          }
          surveyData['recommendationUrls'] = recommendationUrls;
        }

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'surveyData': surveyData,
          'lastSurveyDate': FieldValue.serverTimestamp(),
        }).catchError((error) async {
          // If update fails (document doesn't exist), create it
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'surveyData': surveyData,
            'lastSurveyDate': FieldValue.serverTimestamp(),
            'email': currentUser.email,
            'displayName': currentUser.displayName,
          });
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Style preferences saved successfully!')),
        );
      }
    } catch (e) {
      print('Error saving survey data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving style preferences: $e')),
      );
    } finally {
      setState(() {
        _isSavingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs == null) {
      // Show a loading indicator until _prefs is initialized
      return Center(child: CircularProgressIndicator());
    }

    // If quiz was completed, update UI after this build frame
    if (_quizCompleted) {
      _quizCompleted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }

    return AppBackground(
      child: _buildCrazyAppWidget(),
    );
  }

  Widget _buildCrazyAppWidget() {
    return Stack(
      children: [
        CrazyAppWidget(
          onDataLoaded: (success) {
            print('Data loaded successfully: $success');
          },
          onQuizCompleted: (tags, recommendations) {
            print('Quiz completed with ${tags.length} tags');
            print('Recommended ${recommendations.length} items');

            // Store the data and mark quiz as completed
            _quizTags = List<String>.from(tags);
            _quizRecommendations = recommendations;
            _quizCompleted = true;
            
            // Save the data to Firestore
            _saveQuizDataToFirestore(tags, recommendations);

            // This will cause the widget to rebuild and then we'll handle
            // the state change in the post-frame callback
          },
        ),
        if (_quizRecommendations.isNotEmpty)
          Positioned.fill(
            child: Stack(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _quizRecommendations.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _quizRecommendations[index]['imageUrl'], // Assuming recommendations have 'imageUrl'
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(Icons.error_outline, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (_isSavingData)
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 15),
                          Text(
                            'Saving your style preferences...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Positioned(
          top: 40,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
