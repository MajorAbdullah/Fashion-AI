# Fashion AI — File Purpose Reference

## Entry Point

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point. Initializes Firebase, loads `.env` variables via `flutter_dotenv`, and launches `SplashScreen`. Falls back to an error screen if initialization fails. |

## Core Screens

| File | Purpose |
|------|---------|
| `lib/splashscreen.dart` | Animated splash with fade+scale transition. Checks if onboarding has been seen (`SharedPreferences`) and Firebase auth state, then routes to Onboarding, Login, or HomePage. |
| `lib/onboardingscreen.dart` | 3-page swipeable onboarding carousel with page indicators. Marks onboarding as complete in `SharedPreferences` on finish, then navigates to Login. |
| `lib/login.dart` | Login screen with email/password fields and Google Sign-In. Uses Firebase Auth. Routes to `HomePage` on success, `SignupPage` for new users. |
| `lib/sighup.dart` | Registration screen with username, email, password, confirm password, and optional profile picture upload via `image_picker`. Saves profile image path to `SharedPreferences`. |
| `lib/homepage.dart` | Main navigation hub with 4-tab `ConvexAppBar` (Home, AI Fashion, Try On, Wardrobe). Home tab shows: popular brands, dynamic categories from `CategoryManager`, and outfit recommendation cards (fallback dummy data if API unavailable). |
| `lib/fashion_bot.dart` | AI chat assistant ("StyleBot") powered by Google Gemini 2.5 Flash REST API. Supports text queries and image uploads for fashion analysis. Includes premade prompt chips and typing animation. **Note:** Contains its own `ApiService` class distinct from `services/api_service.dart`. |
| `lib/virtual_try_on.dart` | Virtual try-on using RapidAPI Try-On Diffusion API. User uploads clothing + avatar images (camera/gallery), selects gender, and submits. Images are EXIF-corrected and compressed before upload. Displays result image. Supports loading clothing image path from `SharedPreferences` (cross-screen flow). |
| `lib/wardrobe.dart` | Style quiz and wardrobe/recommendation engine. 6-question intro→quiz→loading→results flow. Questions cover gender, style, colors, items, occasion, season. Matches answers against `CategoryManager` catalog, generates a "StyleBot" summary via Gemini, and saves results to Firestore. Each recommended item has a "Try On" button. |
| `lib/profilepage.dart` | User profile screen. Shows Firebase user info, survey preferences fetched from Firestore, recommendation image gallery, edit-profile dialog, and logout. |

## Brand & Category

| File | Purpose |
|------|---------|
| `lib/brand_page.dart` | Brand-specific product catalog with 3 tabs (All/Men/Women). Loads images from `assets/All Brands/<BrandName> Men/` and `Women/` via the Flutter asset manifest. Includes "Try On" button per item that copies the image to temp storage and signals the try-on screen. |
| `lib/category_manager.dart` | Singleton that scans the Flutter asset manifest for images under `assets/All Brands/`, parses brand/gender from folder names, and categorizes items by filename keyword matching (Shoes, Shirts, Pants, Dresses, Jackets, etc.). Provides `CategoryItem` model and per-category lookup. |
| `lib/subcategory.dart` | Generic subcategory grid view. Accepts a title, image list, and optional brand folder. Displays images in a 2-column grid with formatted names. |
| `lib/unified_category_page.dart` | Category-focused product browser with 3 tabs (All/Men/Women). Uses `CategoryManager` to load items for a given category (e.g. "Shoes", "Shirts"). Each item has a "Try On" button. Mirror of `brand_page.dart`'s pattern. |

## Screens (Quiz/Outfit Flow)

| File | Purpose |
|------|---------|
| `lib/screens/choice_screen.dart` | Entry point for the external-style quiz flow. Offers "Start New Style Quiz" or "View Previous Recommendations" (if `StorageService` has saved data). Routes to `QuestionnaireScreen` or `ResultsScreen`. |
| `lib/screens/questionnaire_screen.dart` | Fetches questions from `ApiService.getQuestions()`, displays them via `PageView` + `QuestionWidget`, collects answers, and submits to the backend. Routes to `ResultsScreen` on completion. |
| `lib/screens/results_screen.dart` | Displays outfit recommendations from the API response or from saved `StorageService` data. Each outfit card navigates to `OutfitDetailsScreen`. |
| `lib/screens/outfit_details_screen.dart` | Detailed view of a single `OutfitRecommendation`. Shows header, components list with icons per type (topwear/bottomwear/footwear), and auto-generated styling tips based on color/style keyword detection. |

## Services

| File | Purpose |
|------|---------|
| `lib/services/api_service.dart` | HTTP client for the external fashion backend (`ngrok` tunnel). Three endpoints: `GET /questions` (fetch quiz questions), `POST /preferences` (submit user preferences), `GET /recommendations` (fetch outfit recommendations). |
| `lib/services/storage_service.dart` | Local persistence layer using `SharedPreferences`. Saves/loads `UserPreferences` and `List<OutfitRecommendation>` as JSON strings. |

## Models

| File | Purpose |
|------|---------|
| `lib/models/question.dart` | Data model for quiz questions. Fields: id, question text, options list, allowMultiple boolean, maxSelections. |
| `lib/models/user_preferences_model.dart` | Data model for user style preferences. Captures gender, item types, style vibes, colors, materials, occasions, seasons, and per-item color/material preferences. |
| `lib/models/recommendation_model.dart` | Two models: `Recommendation` (generic: id, name, description, image, confidence score, tags) and `OutfitRecommendation` (outfit number + component map like `{topwear, bottomwear, footwear}`). |

## Theme & Widgets

| File | Purpose |
|------|---------|
| `lib/app_theme.dart` | Global theme constants: primary color (`#1F4A7F`), input decoration, button style, text styles, and app `ThemeData`. |
| `lib/widgets/question_widget.dart` | Reusable quiz question component. Renders radio buttons for single-select questions and checkboxes for multi-select, with max-selection enforcement. |

## Utility

| File | Purpose |
|------|---------|
| `lib/firebase_options.dart` | Auto-generated by FlutterFire CLI. Provides `FirebaseOptions` for Android (iOS/macOS/Windows/Linux throw `UnsupportedError`). |
| `lib/Detailed_Document.md` | University project documentation (292 lines). Covers executive summary, objectives, technical architecture, PRD, UI/UX design, AI implementation details, testing strategy, and deployment plan. |
