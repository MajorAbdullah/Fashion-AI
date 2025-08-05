import 'package:flutter/material.dart';
import 'onboardingscreen.dart';
import 'login.dart';
import 'homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Animation duration
      vsync: this,
    );

    // Define the animation (scaling and fading)
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth animation curve
      ),
    );

    // Start animation and navigate after a short delay
    _controller.forward();
    
    // Increase timeout and ensure navigation happens only once
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _checkUserState();
      }
    });
  }

  Future<void> _checkUserState() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      
      // Ensure Firebase is ready by explicitly checking current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      print("Navigation check - Onboarding seen: $hasSeenOnboarding, User logged in: ${currentUser != null}");
      
      if (!mounted) return;
      
      if (!hasSeenOnboarding) {
        // First time user - show onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      } else if (currentUser != null) {
        // User is already logged in - go directly to homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // User has seen onboarding but is not logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      print("Error during navigation: $e");
      // Fallback to login page if there's an error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// Background Image
          Image.asset(
            'assets/bg.jpg', // Ensure correct path
            fit: BoxFit.cover,
          ),

          /// Animated Logo
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  'assets/pixelcut-export.png', // Ensure correct path
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of animation controller
    super.dispose();
  }
}
