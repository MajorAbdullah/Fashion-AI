import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'splashscreen.dart';
import 'app_theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables first
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
    
    // Initialize Firebase with explicit error handling
    await Firebase.initializeApp().catchError((error) {
      print("Firebase initialization error: $error");
      throw error; // Rethrow to be caught by the outer try-catch
    });
    print("Firebase initialized successfully");
    
    runApp(MyApp());
  } catch (e) {
    print("Error during initialization: $e");
    // Run a minimal app that shows the error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Initialization Error: $e", 
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fashion AI',
      theme: AppTheme.themeData,
      home: SplashScreen(),
    );
  }
}
