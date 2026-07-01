import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'splashscreen.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((error) {
      print("Firebase initialization error: $error");
      throw error;
    });
    print("Firebase initialized successfully");

    runApp(MyApp());
  } catch (e) {
    print("Error during initialization: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              "Initialization Error: $e",
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
