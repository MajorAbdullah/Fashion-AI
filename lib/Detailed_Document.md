# The Fashion AI: Mobile Application Documentation

## Project Overview

**Student Name:** [Your Name]
**Student ID:** [Your ID]
**Course Code:**
**University:** [University Name]
**Submission Date:** May 5, 2025

## Executive Summary

The Fashion AI is a comprehensive mobile application developed using Flutter that leverages artificial intelligence to revolutionize the clothing shopping experience. The application addresses common challenges faced by consumers in the fashion industry, such as finding suitable clothing matches, virtually trying on clothes, and receiving personalized recommendations. This project demonstrates the integration of modern mobile development techniques with AI technologies to create an innovative solution for the retail fashion industry.

## Project Objectives

1. Develop a mobile application that enhances the clothing shopping experience
2. Implement AI-powered features for fashion recommendations
3. Create a virtual try-on feature using image processing technology
4. Build a personalized wardrobe management system
5. Integrate with multiple clothing brands to provide a diverse selection

## Technical Architecture

The Fashion AI is built on the Flutter framework, enabling cross-platform functionality for both Android and iOS devices. The application follows a modular architecture with distinct components for user authentication, AI recommendations, virtual try-on, and wardrobe management.

### Technology Stack

- **Frontend Framework:** Flutter/Dart
- **Backend Services:** Firebase (Authentication, Cloud Firestore, Storage)
- **AI Integration:** RapidAPI for virtual try-on functionality
- **State Management:** Stateful Widgets
- **Image Processing:** Flutter Image Compress, Exif
- **External APIs:** Try-On Diffusion API

## File Structure and Component Description

### Core Application Files

#### `main.dart`

Entry point of the application that initializes Firebase services and directs users to appropriate screens based on authentication status. It serves as the bootstrap for the entire application and sets up theme configurations.

#### `app_theme.dart`

Contains the centralized theme definitions for the entire application, including color schemes, text styles, and common UI component styling. This ensures visual consistency throughout the app.

```dart
// Defines colors, font styles, and component themes used across the application
// Primary colors: Pink shades for branding
// Secondary colors: Blues and neutrals for accents and backgrounds
```

#### `splashscreen.dart`

Implements the initial loading screen with animations that users see when launching the application. It checks authentication status and directs users to the onboarding flow or homepage.

#### `onboardingscreen.dart`

Manages the onboarding flow for new users, introducing key features through a series of screens with images and explanatory text. The implementation uses a PageView for smooth swiping interactions.

```dart
// Three onboarding screens introducing app features:
// 1. "The AI Fashion App That" - Introduction to concept
// 2. "Makes You Look Your Best" - Personalized recommendations
// 3. "Discover Your Style" - Style exploration capabilities
```

### Authentication Module

#### `login.dart`

Implements the user authentication screen with email/password login, Google sign-in integration, and navigation to the registration screen. The file includes form validation and Firebase authentication methods.

#### `sighup.dart`

Manages the new user registration process, including form validation, Firebase user creation, and initial profile setup. It collects essential information to personalize the user experience.

### Main Application Screens

#### `homepage.dart`

Acts as the central navigation hub containing the bottom navigation bar and housing the main content screens. It manages the state of which tab is currently selected and displays the appropriate content.

```dart
// Main container with bottom navigation for:
// 1. Home tab (HomeContent)
// 2. AI Fashion tab (AIFashionPage)
// 3. Virtual Try-On tab (VirtualTryOn)
// 4. Wardrobe tab (WardrobePage)
```

#### `fashion_bot.dart`

Implements the AI fashion assistant that can answer style questions, make recommendations, and help users navigate fashion choices. It integrates with a natural language processing system to interpret user queries.

#### `virtual_try_on.dart`

One of the flagship features allowing users to upload their photos and clothing items to visualize how the clothes would look on them. It leverages the Try-On Diffusion API for realistic rendering.

```dart
// Key components:
// - Image selection from camera/gallery for both user avatar and clothing
// - Gender selection for avatar processing
// - Image processing before API submission
// - Integration with RapidAPI's Try-On Diffusion API
// - Result display with downloaded try-on image
```

#### `wardrobe.dart`

Provides wardrobe management functionality where users can inventory their clothes, create outfits, and receive AI-powered recommendations based on their wardrobe content.

```dart
// Features:
// - Integration with Crazy app widget for quiz functionality
// - User preferences storage and retrieval
// - Recommendation display based on quiz results
// - Firebase storage of user wardrobe data
```

#### `profilepage.dart`

Displays and allows editing of user profile information, including style preferences, sizing, and personal details. It also shows recommendation history and saved outfits.

### Shopping and Browsing Features

#### `brand_page.dart`

Displays products from specific brands, organized by gender and category. It implements a tabbed interface and grid display for browsing brand collections.

```dart
// Features:
// - Dynamic loading of brand assets from asset folders
// - Tabbed navigation (All Items, Men, Women)
// - Product cards with Try-On button integration
// - Image processing and formatting for display
// - Asset management through manifest loading
```

#### `category_manager.dart`

Manages the categorization of clothing items throughout the application, implementing a singleton pattern to ensure consistent data access. It processes asset paths to extract metadata like gender, brand, and category.

```dart
// Core functionality:
// - Singleton design pattern for global access
// - Asset path processing and categorization
// - Dynamic category thumbnail selection
// - Category item structure with metadata
```

#### `unified_category_page.dart`

Displays products by category (e.g., shirts, pants, dresses) across brands, allowing users to filter by gender. Similar to the brand page but organized by product type instead of brand.

```dart
// Features:
// - Category-specific product display
// - Tabbed filtering by gender
// - Integration with Try-On functionality
// - Product cards with brand and gender indicators
```

#### `subcategory.dart`

Provides a more granular view of product categories, such as different types of shirts or pants, enhancing the browsing experience with specific filters.

### AI & Special Features

#### `virtual_try_on.dart`

The virtual try-on feature allows users to upload an image of themselves and clothing items to see how the clothes would look on them. It uses the Try-On Diffusion API through RapidAPI.

```dart
// Implementation details:
// - Image selection and processing
// - API integration with error handling
// - Result display and image rendering
// - Automatic loading of selected clothing from other screens
```

## Data Management

### Firebase Integration

The application uses Firebase for user authentication, data storage, and file storage:

1. **Authentication:** Email/password and Google Sign-in methods
2. **Cloud Firestore:** Stores user profiles, preferences, and wardrobe data
3. **Storage:** Handles image storage for user uploads and profile pictures

### Local Data Management

SharedPreferences is used to store user settings, completed onboarding status, and temporary data like the selected clothing image for the try-on feature.

## User Experience Flow

1. **New User Journey:**

   - Splash screen → Onboarding screens → Sign up/Login → Homepage
2. **Returning User Journey:**

   - Splash screen → Homepage with personalized recommendations
   - Access to wardrobe, try-on, and AI assistant
3. **Shopping Experience:**

   - Browse by brand or category
   - Select items to try on virtually
   - Save favorite items to wardrobe
   - Receive AI-powered outfit combinations

## AI Feature Implementation

### Virtual Try-On

The virtual try-on feature uses a machine learning model accessed through an API. It processes both the user's photo and the clothing image to generate a realistic composite. The implementation handles image requirements, error states, and result display.

### AI Fashion Recommendations

The application analyzes user preferences, previous selections, and fashion trends to provide personalized outfit recommendations. This system evolves as users interact with the app, creating increasingly accurate suggestions.

## Cross-Platform Compatibility

The application is built using Flutter to ensure consistent performance and appearance across both Android and iOS platforms. Special consideration is given to platform-specific behaviors and UI expectations.

## Future Development Roadmap

1. **Enhanced AI Integration:**

   - Outfit generation based on occasion and weather
   - Color analysis for better matching
2. **Social Features:**

   - Share outfits with friends
   - Community style ratings and feedback
3. **Retail Integration:**

   - Direct purchase options from featured brands
   - Size recommendation based on previous purchases
4. **Extended Reality Features:**

   - 3D model try-on for more accurate visualization
   - Augmented reality shopping experience

## Conclusion

The Fashion AI represents a significant advancement in the application of artificial intelligence to the retail fashion experience. By combining modern mobile development techniques with AI technologies, the application provides users with a personalized, interactive, and visually engaging platform for discovering and experimenting with fashion. The modular architecture ensures maintainability and scalability as new features and brands are added to the ecosystem.

## References

- Flutter Documentation: https://flutter.dev/docs
- Firebase Documentation: https://firebase.google.com/docs
- Try-On Diffusion API: https://rapidapi.com/try-on-diffusion/
- Image Processing in Flutter: https://pub.dev/packages/flutter_image_compress
- Firebase Auth: https://pub.dev/packages/firebase_auth
- Convex Bottom Bar: https://pub.dev/packages/convex_bottom_bar

## Appendices

### A. Installation Instructions

```
# Clone the repository
git clone https://github.com/yourusername/thefashionai.git

# Navigate to project directory
cd thefashionai

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### B. API Keys and Configuration

To run the application with full functionality, you need to set up:

1. Firebase project with authentication and Firestore
2. RapidAPI key for the Try-On Diffusion API
3. Configure firebase_options.dart with your Firebase project details
4. Create a .env file with your RapidAPI key

### C. Testing Procedures

The application includes widget tests to verify the functionality of key components. Run tests using:

```
flutter test
```
