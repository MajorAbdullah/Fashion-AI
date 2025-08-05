import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  final String? profileImagePath;

  ProfilePage({this.profileImagePath});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  String? username;
  String? email;
  String profileImageUrl = "https://via.placeholder.com/150";
  Map<String, dynamic>? _surveyData;
  bool _loadingSurveyData = true;
  bool _surveyCompleted = false;
  Timestamp? _lastSurveyDate;
  List<String>? _recommendationUrls;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _fetchSurveyData();
  }

  void _getUserData() {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        username = user.displayName ?? 'Sami Ullah';
        email = user.email ?? 'No email';
      });
    }
  }

  Future<void> _fetchSurveyData() async {
    setState(() {
      _loadingSurveyData = true;
    });
    
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Fetch user's survey data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && userDoc.data() != null) {
          var userData = userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('surveyData')) {
            setState(() {
              _surveyData = userData['surveyData'] as Map<String, dynamic>;
              _surveyCompleted = true;
              
              // Get last survey date if available
              if (userData.containsKey('lastSurveyDate')) {
                _lastSurveyDate = userData['lastSurveyDate'] as Timestamp?;
              }
              
              // Get recommendation URLs if available
              if (_surveyData!.containsKey('recommendationUrls')) {
                var urls = _surveyData!['recommendationUrls'];
                if (urls is List) {
                  _recommendationUrls = List<String>.from(urls);
                }
              }
            });
          } else {
            setState(() {
              _surveyCompleted = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching survey data: $e');
    } finally {
      setState(() {
        _loadingSurveyData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 60),

            /// Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.profileImagePath != null
                  ? FileImage(File(widget.profileImagePath!))
                  : NetworkImage(profileImageUrl) as ImageProvider,
            ),

            SizedBox(height: 10),

            /// Profile Content (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileButton(Icons.person, "Username", username ?? "Loading..."),
                      _profileButton(Icons.email, "Email", email ?? "Loading..."),
                      SizedBox(height: 20),
                      _editProfileButton(),
                      Divider(),
                      
                      // Survey Preferences Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Style Preferences",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (_lastSurveyDate != null)
                            Text(
                              "Last updated: ${_formatDate(_lastSurveyDate!)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildPreferencesSection(),
                      
                      // Recommendations Section
                      if (_recommendationUrls != null && _recommendationUrls!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Text(
                              "Your Recommendations",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 10),
                            _buildRecommendationsGrid(),
                          ],
                        ),
                      
                      Divider(),
                      _logoutButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildPreferencesSection() {
    if (_loadingSurveyData) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (!_surveyCompleted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "You haven't completed the style survey yet.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Go to Wardrobe tab to take the style survey")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Take Style Survey", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildPreferenceCards(),
      );
    }
  }

  List<Widget> _buildPreferenceCards() {
    List<Widget> cards = [];

    if (_surveyData == null || _surveyData!.isEmpty) {
      return [
        Center(
          child: Text("No preference data available"),
        )
      ];
    }

    // Add Gender preference card
    if (_surveyData!.containsKey('Gender')) {
      cards.add(_preferenceCard(
        "Gender",
        [_surveyData!['Gender'].toString()],
      ));
    }

    // Add Style preference card (handling lists)
    if (_surveyData!.containsKey('Style')) {
      var styles = _surveyData!['Style'];
      if (styles is List) {
        cards.add(_preferenceCard(
          "Style",
          styles.map((item) => item.toString()).toList(),
        ));
      } else if (styles is String) {
        cards.add(_preferenceCard(
          "Style",
          [styles],
        ));
      }
    }

    // Add Clothing Type preference card (handling lists)
    if (_surveyData!.containsKey('Clothing Type')) {
      var clothingTypes = _surveyData!['Clothing Type'];
      if (clothingTypes is List) {
        cards.add(_preferenceCard(
          "Clothing Types",
          clothingTypes.map((item) => item.toString()).toList(),
        ));
      } else if (clothingTypes is String) {
        cards.add(_preferenceCard(
          "Clothing Types",
          [clothingTypes],
        ));
      }
    }

    // Add other preferences
    if (_surveyData!.containsKey('Pants Type')) {
      cards.add(_preferenceCard(
        "Pants Type",
        [_surveyData!['Pants Type'].toString()],
      ));
    }

    if (_surveyData!.containsKey('Shirt Type')) {
      cards.add(_preferenceCard(
        "Shirt Type",
        [_surveyData!['Shirt Type'].toString()],
      ));
    }

    // Add Accessories preference card (handling lists)
    if (_surveyData!.containsKey('Accessories')) {
      var accessories = _surveyData!['Accessories'];
      if (accessories is List) {
        cards.add(_preferenceCard(
          "Accessories",
          accessories.map((item) => item.toString()).toList(),
        ));
      } else if (accessories is String) {
        cards.add(_preferenceCard(
          "Accessories",
          [accessories],
        ));
      }
    }

    if (_surveyData!.containsKey('Color Palette')) {
      cards.add(_preferenceCard(
        "Color Palette", 
        [_surveyData!['Color Palette'].toString()],
      ));
    }

    if (cards.isEmpty) {
      return [
        Center(
          child: Text("No preference data available"),
        )
      ];
    }

    return cards;
  }

  Widget _buildRecommendationsGrid() {
    if (_recommendationUrls == null || _recommendationUrls!.isEmpty) {
      return Center(child: Text("No recommendations available"));
    }

    return Container(
      height: 150,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _recommendationUrls!.length.clamp(0, 6), // Show at most 6 recommendations
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _recommendationUrls![index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey[700]),
                );
              },
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
            ),
          );
        },
      ),
    );
  }

  Widget _preferenceCard(String title, List<String> values) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 5),
            ...values.map((value) => Padding(
              padding: EdgeInsets.only(left: 10, top: 5),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  /// Profile Action Buttons (Show Data)
  Widget _profileButton(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey)),
    );
  }

  /// Edit Profile Button
  Widget _editProfileButton() {
    return ElevatedButton.icon(
      onPressed: _openEditDialog,
      icon: Icon(Icons.edit, color: Colors.white),
      label: Text("Edit Profile", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Logout Button
  Widget _logoutButton() {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.red),
      title: Text("LogOut", style: TextStyle(fontSize: 16, color: Colors.red)),
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      },
    );
  }

  /// Open Dialog for Editing All Fields
  void _openEditDialog() {
    TextEditingController nameController = TextEditingController(text: username);
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Save"),
            onPressed: () async {
              String newUsername = nameController.text.trim();
              String newEmail = emailController.text.trim();
              String newPassword = passwordController.text.trim();

              User? user = _auth.currentUser;

              if (user != null) {
                if (newUsername.isNotEmpty) await user.updateDisplayName(newUsername);
                if (newEmail.isNotEmpty) await user.updateEmail(newEmail);
                if (newPassword.isNotEmpty) await user.updatePassword(newPassword);

                // Update Firestore profile data if changed
                if (newUsername.isNotEmpty || newEmail.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      if (newUsername.isNotEmpty) 'displayName': newUsername,
                      if (newEmail.isNotEmpty) 'email': newEmail,
                    });
                  } catch (e) {
                    print("Error updating Firestore profile: $e");
                  }
                }

                _getUserData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Profile updated successfully")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
