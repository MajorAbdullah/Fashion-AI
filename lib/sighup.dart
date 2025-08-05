import 'dart:io';  // For using File to store image
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'app_theme.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  File? _pickedImage;  // Variable to hold picked image
  String? errorMessage;

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // Function to save image path to shared preferences
  Future<void> _saveImageToPreferences() async {
    if (_pickedImage != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('profile_image_path', _pickedImage!.path);
    }
  }

  // Function to sign up
  void _signUp() async {
    // Clear previous error message
    setState(() {
      errorMessage = null;
    });

    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Email and password cannot be empty";
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        errorMessage = "Passwords do not match";
      });
      return;
    }
    
    try {
      // Firebase Authentication sign up
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(_usernameController.text.trim());
      
        // Save image path to shared preferences (if picked)
        await _saveImageToPreferences();
        
        await user.reload();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup Successful")),
        );

        // Redirect to login page after successful signup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  TextField(
                    controller: _usernameController,
                    decoration: AppTheme.inputDecoration('Username', prefixIcon: Icons.account_box_rounded),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _emailController,
                    decoration: AppTheme.inputDecoration('Email Address', prefixIcon: Icons.email),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: AppTheme.inputDecoration('Password', prefixIcon: Icons.lock),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: AppTheme.inputDecoration('Confirm Password', prefixIcon: Icons.remove_red_eye),
                  ),
                  SizedBox(height: 15),
                  
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : null,
                      child: _pickedImage == null
                          ? Icon(Icons.camera_alt, size: 30, color: AppTheme.primaryColor)
                          : null,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Tap to add profile picture",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signUp,
                    style: AppTheme.elevatedButtonStyle(),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to login page
                    },
                    child: Text(
                      'Already have an account? Log in here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

