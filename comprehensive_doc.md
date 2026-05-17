# Fashion AI — Comprehensive Documentation

> Generated: 2026-05-08
> Repository: `Fashion-AI` (`thefashionai` Flutter package)
> Primary branch: `master`

This document describes the Fashion AI mobile application end-to-end: purpose, flows, architecture, code layout, backend/cloud integrations, frontend composition, data schema, runtime/deploy requirements, and the (non-existent) payment/credit-token surface.

---

## 1. System Overview

**Fashion AI** is a cross-platform mobile application (Flutter) that brings AI-powered styling to fashion shopping. It lets a user:

- **Authenticate** via email/password, Google Sign-In, or anonymous Firebase auth.
- **Browse fashion catalogs** by brand (Breakout, Chase Value, Ideas, Outfitter) and by auto-derived category (Shirts, Pants, Shoes, Jackets, Dresses, etc.). The catalog is a bundled set of asset images packaged with the app.
- **Get AI outfit recommendations** by completing a dynamic preference questionnaire backed by an external HTTP API.
- **Chat with a Fashion Assistant ("StyleBot")** powered by Google Gemini (`gemini-2.0-flash-exp`) — both text and image input are supported.
- **Virtual Try-On** — upload an avatar photo + a clothing item and receive a composited try-on image, generated via the RapidAPI **Try-On Diffusion** service.
- **Take an in-app style quiz** (delivered through the third-party `crazy` widget) and persist the resulting tags + recommendation URLs to Firestore for the user's profile.
- **Manage a profile** with editable display name / email / password and a derived "Style Preferences" view drawn from quiz results.

Primary Capabilities:
- AI Fashion Chatbot (Gemini multimodal).
- Virtual Try-On (Try-On Diffusion API).
- Personalized Outfit Recommendations (custom REST backend via ngrok).
- Brand & Category catalog browsing (asset-driven).
- Wardrobe / Style Quiz integration (third-party `crazy` widget).
- Profile management with Firestore-backed style data.

There is **no commerce, payment, subscription, or credit/token system** wired into the application code (see §11).

---

## 2. System Flow

### 2.1 Process Flow (High Level)

```
┌──────────────┐  cold start   ┌───────────────┐   first run    ┌──────────────────┐
│  main.dart   │ ────────────► │ SplashScreen  │ ─────────────► │ OnboardingScreen │
└──────┬───────┘               └──────┬────────┘                └────────┬─────────┘
       │ load .env, init Firebase     │ checks SharedPreferences         │
       ▼                              │   `hasSeenOnboarding`            ▼
                                      │   FirebaseAuth.currentUser   marks flag, → Login
                                      ▼
                              ┌──────────────────┐
                              │ Login / Sign Up  │
                              └────────┬─────────┘
                                       │ FirebaseAuth + Firestore user doc
                                       ▼
                              ┌──────────────────┐
                              │     HomePage     │ — ConvexAppBar tabs
                              └─────────┬────────┘
              ┌───────────────┬─────────┴──────────┬─────────────────┐
              ▼               ▼                    ▼                 ▼
        Home (browse)    AIFashionPage        VirtualTryOn       WardrobePage
              │               │                    │                 │
              ▼               ▼                    ▼                 ▼
         BrandPage      Gemini API           RapidAPI Try-On     CrazyAppWidget
         CategoryPage   (text + image)       Diffusion API       (Quiz)→Firestore
              │
              ▼
        ChoiceScreen → QuestionnaireScreen → ResultsScreen → OutfitDetailsScreen
                       (External REST API: simple-walrus-initially.ngrok-free.app)
```

### 2.2 Data Flow

| Source | Sink | Mechanism |
|---|---|---|
| User credentials | Firebase Authentication | `firebase_auth` SDK |
| User profile + survey data | Cloud Firestore (`users/{uid}`) | `cloud_firestore` SDK |
| Profile picture path | Local device | `shared_preferences` (`profile_image_path`) |
| Onboarding flag | Local device | `shared_preferences` (`hasSeenOnboarding`) |
| Selected clothing image | Disk → next page | App temp dir + `shared_preferences` (`clothing_image_path`) |
| Questionnaire answers | External recommendations API | `http` POST `/preferences` |
| Outfit recommendations | Local device + UI | `shared_preferences` (`recommendations`) |
| Avatar + clothing images | RapidAPI Try-On Diffusion | Multipart HTTP POST |
| Chat prompt + image | Google Generative Language API | HTTP POST with inline base64 |
| Catalog images | Bundled assets (`AssetManifest.json`) | `rootBundle` |
| RAPIDAPI_KEY / GOOGLE_AI_API_KEY | App | `flutter_dotenv` (`.env`) |

### 2.3 End-to-end Try-On Flow (Example)

1. User opens **Brand Page** or **Category Page** and taps "Try On" on a product.
2. Asset bytes are read with `rootBundle.load(...)`, written to the OS temp directory, and the path is saved as `clothing_image_path` in `SharedPreferences`.
3. User switches to the **Try-On** tab. `VirtualTryOnState._loadSavedClothingImage()` consumes the path, displays the clothing preview, and clears the key.
4. User picks an avatar image (camera/gallery), the app reads EXIF, auto-corrects orientation, and compresses to ~512×512 JPEG @ q90.
5. App size-checks (≤5 MB) and decodes both images for sanity validation.
6. App POSTs a `multipart/form-data` request (`avatar_sex`, `clothing_image`, `avatar_image`) to `https://try-on-diffusion.p.rapidapi.com/try-on-file` with the RapidAPI key from `.env`.
7. On 200 + `image/*` content-type, the binary body is rendered with `Image.memory`.

---

## 3. User Flow

A typical journey from cold launch to closing the app:

1. **Launch** — Splash screen (`assets/bg.jpg` + animated logo) plays for ~3 s.
2. **Routing decision (SplashScreen._checkUserState):**
   - First-time → `OnboardingScreen` (3 swipeable pages) → on completion sets `hasSeenOnboarding=true` → `LoginPage`.
   - Returning, signed-in → `HomePage` directly.
   - Returning, signed-out → `LoginPage`.
3. **Login / Sign Up:**
   - Email/password (`createUserWithEmailAndPassword` / `signInWithEmailAndPassword`).
   - Google Sign-In via `google_sign_in` + `GoogleAuthProvider.credential`.
   - Anonymous sign-in is also wired in `LoginPage.signInAnonymously` (not surfaced as a button by default).
4. **Home tab** — Sees AI Outfit Recommendations CTA, "Popular Brands", auto-derived "Categories", and a horizontal "Outfit Ideas" carousel sourced from saved recommendations or seeded dummy data.
5. **AI Outfit Recommendations** — Tap the CTA → `ChoiceScreen` (start quiz / view previous).
   - **Start New Style Quiz** → `QuestionnaireScreen` fetches questions from `/questions`, paginates them with progress, validates answers, then POSTs to `/preferences` and pushes `ResultsScreen`.
   - **View Previous** → `ResultsScreen` with cached recommendations.
6. **AI Fashion tab** — `ChatScreen` (StyleBot). User can pick a pre-made prompt, type freely, or attach an image. Responses stream as a typing indicator then a Gemini reply.
7. **Try-On tab** — Pick clothing + avatar, choose gender, tap "Try it On". The composited image renders below.
8. **Wardrobe tab** — Embeds `CrazyAppWidget` which runs an interactive style quiz; on completion, tags/recommendations are written to Firestore under `users/{uid}.surveyData` and recommendation thumbnails are tiled.
9. **Profile** — Tap the avatar in the AppBar → `ProfilePage` shows username, email, last survey date, "Style Preferences" cards, and recommendation thumbnails. Edit name/email/password, or **Logout**.
10. **Exit / Suspend** — All ephemeral state cleared (clothing image path, in-memory chat history). Persisted user prefs and Firestore data remain.

---

## 4. Architecture

### 4.1 Style

A **layered, client-heavy mobile architecture** with several external service dependencies:

```
┌────────────────────────────────────────────────────────────────┐
│                       Flutter UI Layer                         │
│  Screens (homepage, login, sighup, profilepage, brand_page,    │
│  unified_category_page, virtual_try_on, wardrobe, fashion_bot, │
│  splashscreen, onboardingscreen, screens/*)                    │
│  Widgets (widgets/question_widget.dart)                        │
└──────────────────────────────┬─────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────┐
│              Domain / Service Layer (lib/services)             │
│  ApiService          — REST calls to the recommendations API   │
│  StorageService      — SharedPreferences read/write helpers    │
│  CategoryManager     — Singleton: scans AssetManifest, derives │
│                        categories, brands, gender              │
│  ChatScreen.ApiService — Gemini HTTP client (in fashion_bot)   │
└──────────────────────────────┬─────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────┐
│                       Models (lib/models)                      │
│  Question, UserPreferences, ItemSpecificPreference,            │
│  Recommendation, OutfitRecommendation                          │
└──────────────────────────────┬─────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────┐
│                External Services / Platform                    │
│  Firebase: Authentication · Cloud Firestore · Storage          │
│  Google Generative Language API (Gemini 2.0 Flash)             │
│  RapidAPI Try-On Diffusion                                     │
│  Recommendations API (ngrok-tunneled FastAPI/etc.)             │
│  Bundled asset manifest (clothing imagery)                     │
└────────────────────────────────────────────────────────────────┘
```

### 4.2 Major Components

| Component | File | Role |
|---|---|---|
| App bootstrap | `lib/main.dart` | Loads `.env`, initialises Firebase, mounts `MyApp` → `SplashScreen`. |
| Theme | `lib/app_theme.dart` | Centralized colors, button/input styles, `ThemeData`. |
| Splash | `lib/splashscreen.dart` | Animation + auth/onboarding routing decision. |
| Onboarding | `lib/onboardingscreen.dart` | Three-page intro, persists `hasSeenOnboarding`. |
| Login | `lib/login.dart` | Email/password + Google + anonymous auth. |
| Sign-up | `lib/sighup.dart` | Email/password account creation, optional avatar pick. |
| Home shell | `lib/homepage.dart` | `ConvexAppBar` 4-tab shell: Home / AI / Try-On / Wardrobe. |
| Brand catalog | `lib/brand_page.dart` | Loads brand assets from manifest, men/women/all tabs, "Try On" hand-off. |
| Category catalog | `lib/unified_category_page.dart` | Cross-brand browsing per category with gender tabs. |
| Subcategory | `lib/subcategory.dart` | Grid view of images in a brand/category folder. |
| Category manager | `lib/category_manager.dart` | Singleton; parses `AssetManifest.json`, infers brand/gender/category from path + filename. |
| Fashion bot | `lib/fashion_bot.dart` | Gemini chat UI + HTTP client; pre-made prompts, image attachment, link launching. |
| Virtual try-on | `lib/virtual_try_on.dart` | Image picking, EXIF + compression, multipart upload to RapidAPI. |
| Wardrobe | `lib/wardrobe.dart` | Embeds external `crazy` quiz widget, persists tags/recs to Firestore. |
| Profile | `lib/profilepage.dart` | Profile + Firestore "surveyData" rendering, edit/logout. |
| Choice | `lib/screens/choice_screen.dart` | Branching to new quiz vs. previous recommendations. |
| Questionnaire | `lib/screens/questionnaire_screen.dart` | Paginated form with progress, posts answers. |
| Results | `lib/screens/results_screen.dart` | Lists outfit cards from recommendations API. |
| Outfit details | `lib/screens/outfit_details_screen.dart` | Per-outfit components + heuristic styling tips. |
| Question widget | `lib/widgets/question_widget.dart` | Single/multiple choice rendering with `maxSelections`. |
| API client | `lib/services/api_service.dart` | `GET /questions`, `POST /preferences`, `GET /recommendations`. |
| Storage helper | `lib/services/storage_service.dart` | Persists user preferences + recommendations to `SharedPreferences`. |
| Firebase config | `lib/firebase_options.dart` | Generated by FlutterFire — Android-only at present. |

---

## 5. Folder Structure

Top-level layout of the repository:

| Path | Purpose |
|---|---|
| `lib/` | All Dart application code (see breakdown below). |
| `assets/` | Bundled imagery: backgrounds, logos, brand catalogs (`All Brands/<Brand> Men|Women/...`), CSV stubs, onboarding/imagery. Listed in `pubspec.yaml`. |
| `android/` | Android Gradle project (`android/app/build.gradle`, `google-services.json`). Application id `com.example.thefashionai`. Uses FlutterFire `com.google.gms.google-services` plugin. |
| `web/` | Flutter web target (`index.html`, `manifest.json`, icons). Note: `firebase_options.dart` does **not** support web yet. |
| `test/` | Standard `flutter test` directory (single placeholder test). |
| `.dart_tool/` | Generated tool state (gitignored). |
| `.git/` | Git repository state. |
| `pubspec.yaml` | Flutter package manifest, dependencies, asset registration, launcher icon config. |
| `pubspec.lock` | Resolved dependency lockfile. |
| `firebase.json` | Minimal FlutterFire metadata: project `fyp-fashion`, Android app id. |
| `firebase_cli_commands.txt` | Cheat sheet of Firebase CLI commands used during development. |
| `analysis_options.yaml` | Dart analyzer + lint rules (`flutter_lints` package). |
| `devtools_options.yaml` | Flutter DevTools settings. |
| `setup.sh`, `setup.bat` | Convenience setup scripts (Flutter doctor, `pub get`, `.env` bootstrap, Firebase tooling check). |
| `README.md`, `README.pdf` | Public-facing project README and PDF mirror. |
| `SECURITY.md` | API key handling guidance. |
| `lib/Detailed_Document.md` | Pre-existing student-style documentation (kept for reference). |

### 5.1 `lib/` Breakdown

```
lib/
├── main.dart                     # bootstrap: dotenv + Firebase + MyApp
├── app_theme.dart                # design tokens, ThemeData, helpers
├── firebase_options.dart         # FlutterFire-generated (Android only)
├── splashscreen.dart             # animation + routing decision
├── onboardingscreen.dart         # 3-page intro
├── login.dart                    # email/Google/anonymous auth
├── sighup.dart                   # registration (note: filename "sighup")
├── homepage.dart                 # tabbed shell + HomeContent
├── brand_page.dart               # per-brand catalog
├── unified_category_page.dart    # cross-brand by category
├── subcategory.dart              # subcategory grid
├── category_manager.dart         # singleton manifest parser
├── fashion_bot.dart              # Gemini chat (also defines its own ApiService)
├── virtual_try_on.dart           # avatar+clothing → Try-On Diffusion
├── wardrobe.dart                 # CrazyAppWidget host + Firestore writes
├── profilepage.dart              # profile + style preference cards
├── Detailed_Document.md          # legacy documentation
├── models/
│   ├── question.dart             # quiz question schema
│   ├── recommendation_model.dart # OutfitRecommendation, Recommendation
│   └── user_preferences_model.dart # UserPreferences + ItemSpecificPreference
├── screens/
│   ├── choice_screen.dart        # quiz vs. previous recs
│   ├── questionnaire_screen.dart # paged form
│   ├── results_screen.dart       # outfit list
│   └── outfit_details_screen.dart # per-outfit detail
├── services/
│   ├── api_service.dart          # recommendations REST client
│   └── storage_service.dart      # SharedPreferences persistence
└── widgets/
    └── question_widget.dart      # single/multi choice question UI
```

### 5.2 Critical Asset Subfolders

- `assets/All Brands/` — image catalog organised as `<Brand> <Gender>/` then optional sub-categories (e.g. `Ideas Men/Ideas Polos/...`). Drives `BrandPage`, `UnifiedCategoryPage`, and `CategoryManager`.
- `assets/csv/` — `questions.csv`, `clothing.csv` stubs registered in `pubspec.yaml` (used historically; current questionnaire fetches from API).
- `assets/images/` — generic UI imagery (e.g., category fallback thumbnails).

---

## 6. Backend Overview

There is **no first-party server in this repository**; the backend is a composition of external services and one externally hosted REST API.

### 6.1 Firebase (Google Cloud)

- **Project**: `fyp-fashion` (defined in `firebase.json`, `firebase_options.dart`).
- **Authentication** — `firebase_auth ^5.5.1`: email/password, Google federation (via `google_sign_in ^6.2.2`), anonymous.
- **Cloud Firestore** — `cloud_firestore ^5.6.5`: stores `users/{uid}` documents containing `surveyData`, `lastSurveyDate`, `email`, `displayName`, plus updates from `ProfilePage`.
- **Cloud Storage** — `firebase_storage ^12.4.5` (declared, not actively written from current code paths).
- **Firebase Core** — `firebase_core ^3.12.1`.

### 6.2 External Recommendations API

Defined in `lib/services/api_service.dart`:

```
Base URL: https://simple-walrus-initially.ngrok-free.app
```

| Method | Path | Purpose | Request | Response |
|---|---|---|---|---|
| GET | `/questions` | Fetch questionnaire | — | `[Question, ...]` |
| POST | `/preferences` | Submit quiz answers | `UserPreferences` JSON | `{ outfits: [OutfitRecommendation], ... }` |
| GET | `/recommendations` | Fetch latest recommendations | — | `{ outfits: [OutfitRecommendation] }` |

This base URL is an **ngrok tunnel** — i.e. an ad-hoc development endpoint, not a stable production host (see Blockers in §11).

### 6.3 Google Generative Language API (Gemini)

Used by `lib/fashion_bot.dart`:

- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$GOOGLE_AI_API_KEY`
- Both text-only and image+text payloads (image inlined as base64 with detected MIME type).
- Response markdown is stripped (`*`, `##`, ` ``` `, etc.) before display.

### 6.4 RapidAPI Try-On Diffusion

Used by `lib/virtual_try_on.dart`:

- Endpoint: `POST https://try-on-diffusion.p.rapidapi.com/try-on-file`
- Headers: `x-rapidapi-host`, `x-rapidapi-key` (from `.env: RAPIDAPI_KEY`).
- Multipart fields: `avatar_sex` (`male|female`), `clothing_image`, `avatar_image`.
- Response: binary image (rendered with `Image.memory`).

### 6.5 Request Handling Mechanics

- All HTTP via `http ^1.1.0` (and `http_parser` for multipart MediaType).
- `dio ^5.4.0` is included in `pubspec.yaml` but not used in the current source.
- Image preprocessing: `flutter_image_compress` (auto-orientation, JPEG @ q90, min 512×512), `exif`, `image` (decode validation).
- Auth: handled client-side via Firebase SDK; no backend-issued JWTs in this repo.

---

## 7. Frontend Overview

### 7.1 Framework & Major Libraries

- **Flutter** SDK `^3.6.0`, **Dart**, Material Design.
- **State**: simple `StatefulWidget`s (`_State` private classes throughout). `flutter_bloc` is in `pubspec.yaml` but is **not used** in any current source file.
- **Navigation**: imperative `Navigator.push` / `pushReplacement`. No declarative routing.
- **Bottom navigation**: `convex_bottom_bar` (`ConvexAppBar`) + `animated_bottom_navigation_bar` (declared, not currently used).
- **Imagery**: `image_picker`, `flutter_image_compress`, `exif`, `image`, `cached_network_image`, `palette_generator`, `shimmer`.
- **Networking & files**: `http`, `http_parser`, `dio` (declared), `path`, `path_provider`, `mime` (used via `lookupMimeType` in fashion_bot).
- **Persistence**: `shared_preferences`, Firebase SDKs.
- **Misc**: `flutter_dotenv` (env), `flutter_linkify` + `url_launcher` (chat links), `csv` (declared, not currently parsed), `google_generative_ai` (declared, not used — the code calls Gemini via raw HTTP).
- **Speech & camera**: `speech_to_text`, `camera` (declared in `pubspec.yaml`, not currently surfaced in the UI).

### 7.2 Component Breakdown

| Layer | Components |
|---|---|
| Shell | `MyApp` (root), `SplashScreen`, `OnboardingScreen`, `LoginPage`, `SignupPage`. |
| Home shell | `HomePage` (tab host) → `HomeContent`, `AIFashionPage` (= `ChatScreen`), `VirtualTryOn`, `WardrobePage`. |
| Browsing | `BrandPage` (3 tabs: All / Men / Women, grid + Try-On), `UnifiedCategoryPage`, `SubcategoryPage`. |
| AI / Quiz | `ChatScreen` (Gemini), `ChoiceScreen`, `QuestionnaireScreen`, `ResultsScreen`, `OutfitDetailsScreen`. |
| Try-On | `VirtualTryOn` widget (`StatefulWidget`) — public API includes a `Function(Uint8List)? onTryOnComplete` callback. |
| Profile | `ProfilePage` with edit dialog, preference cards, recommendation grid, logout. |
| Reusable widgets | `AppBackground` (defined in `homepage.dart`), `QuestionWidget`, `AnimatedDot`/`DelayTween` (typing indicator). |

### 7.3 Major Workflows

1. **Authentication & Routing** — `SplashScreen` consults `SharedPreferences` (`hasSeenOnboarding`) and `FirebaseAuth.instance.currentUser` to choose Onboarding / Login / Home.
2. **Catalog → Try-On Hand-off** — Brand/Category pages stage the selected clothing image to disk and write `clothing_image_path` to `SharedPreferences`; `VirtualTryOnState._loadSavedClothingImage` consumes and clears it.
3. **Quiz Loop** — `ChoiceScreen` → `QuestionnaireScreen` (fetch + paginate questions, validate answers, format `item_specific_preferences`) → POST `/preferences` → `ResultsScreen` (also caches via `StorageService`).
4. **Style Quiz (Wardrobe)** — `CrazyAppWidget` raises `onQuizCompleted(tags, recommendations)`; `_saveQuizDataToFirestore` parses tag prefixes (`style:`, `color:`, `clothing:`) and merges into `users/{uid}.surveyData`.
5. **Chat** — Pre-made prompts populate the input; `_sendMessage` either calls `_sendTextMessage` or `_sendImageMessage` with base64-inlined image.

---

## 8. Schema

The application is **schemaless on the server side** (Firestore + freeform external API). Below are the effective document/JSON shapes used in code.

### 8.1 Firestore — `users/{uid}`

```json
{
  "email": "user@example.com",
  "displayName": "Sami Ullah",
  "lastSurveyDate": "<Timestamp>",
  "surveyData": {
    "Gender": "Female",
    "Style": ["minimal", "casual"],
    "Color Palette": "navy, white, beige",
    "Clothing Type": ["dress", "top"],
    "Pants Type": "wide-leg",
    "Shirt Type": "buttoned",
    "Accessories": ["belt", "scarf"],
    "recommendationUrls": ["https://.../img1.jpg", "..."],
    "timestamp": "<ServerTimestamp>"
  }
}
```

> Source of truth: `lib/wardrobe.dart` (writes) and `lib/profilepage.dart` (reads). Field set is *open* — only `Gender`, `Style`, `Color Palette`, `Clothing Type`, `Pants Type`, `Shirt Type`, `Accessories`, `recommendationUrls` are explicitly handled in the UI.

### 8.2 Recommendation Models (Dart)

`lib/models/question.dart`:

```dart
class Question {
  final String id;
  final String question;
  final List<String> options;
  final bool allowMultiple;
  final int? maxSelections;
}
```

`lib/models/user_preferences_model.dart`:

```dart
class UserPreferences {
  String?              gender;
  List<String>?        itemTypes;
  List<String>?        styleVibes;
  List<String>?        favoriteColors;
  List<String>?        preferredMaterials;
  List<String>?        keyOccasions;
  List<String>?        primarySeasons;
  String?              casualOutfitStyle;
  String?              formalOutfitColor;
  String?              specificOccasion;
  Map<String, ItemSpecificPreference>? itemSpecificPreferences;
}

class ItemSpecificPreference {
  List<String>? colors;
  List<String>? materials;
}
```

`lib/models/recommendation_model.dart`:

```dart
class OutfitRecommendation {
  final int outfitNumber;
  final Map<String, String> components; // e.g. { "topwear": "...", "bottomwear": "...", "footwear": "..." }
}

class Recommendation {            // Generic catalog item (currently unused outside model)
  int    id;
  String name;
  String description;
  String imageUrl;
  double confidenceScore;
  List<String> tags;
}
```

### 8.3 External API — JSON Shapes

`GET /questions`:
```json
[
  {
    "id": "gender",
    "question": "What is your gender?",
    "options": ["Male", "Female", "Non-binary"],
    "allow_multiple": false,
    "max_selections": null
  }
]
```

`POST /preferences` (request body produced by `_processAnswers`):
```json
{
  "gender": "Female",
  "item_types": ["Top", "Bottom"],
  "favorite_colors": ["navy", "white"],
  "preferred_materials": ["cotton"],
  "item_specific_preferences": {
    "top":    { "colors": ["navy", "white"], "materials": ["cotton"] },
    "bottom": { "colors": ["navy", "white"], "materials": ["cotton"] }
  }
}
```

`GET /recommendations` and the response of `POST /preferences`:
```json
{
  "outfits": [
    {
      "outfit_number": 1,
      "components": {
        "topwear": "Classic White Shirt",
        "bottomwear": "Navy Blue Jeans",
        "footwear": "Brown Leather Loafers"
      }
    }
  ]
}
```

### 8.4 Local Persistence Keys (SharedPreferences)

| Key | Producer | Consumer | Purpose |
|---|---|---|---|
| `hasSeenOnboarding` (bool) | `OnboardingScreen` | `SplashScreen` | Skip onboarding on subsequent launches. |
| `profile_image_path` (String) | `SignupPage` | `HomePage`, `ProfilePage` | Local avatar image path. |
| `clothing_image_path` (String) | `BrandPage`, `UnifiedCategoryPage` | `VirtualTryOnState._loadSavedClothingImage` | Hand-off from catalog → Try-On. |
| `user_preferences` (JSON String) | `StorageService.saveUserPreferences` | `StorageService.getUserPreferences` | Cached questionnaire answers. |
| `recommendations` (JSON String) | `StorageService.saveRecommendations` | `StorageService.getRecommendations` / `HomeContent`, `ChoiceScreen`, `ResultsScreen` | Cached outfit recommendations. |

---

## 9. Essentials Checklist

To run the project locally:

### 9.1 Tooling

- **Flutter SDK** `^3.6.0` (Dart 3.x).
- **Android SDK** with build tools, `minSdk = 23`, an emulator or physical device (or Android Studio).
- **Xcode** for iOS — _note:_ `firebase_options.dart` currently throws `UnsupportedError` for iOS / macOS / web / Windows / Linux. iOS target requires re-running `flutterfire configure`.
- **Firebase CLI** + **FlutterFire CLI** for regenerating `firebase_options.dart` if you change projects.
- **Git** to clone the repository.

### 9.2 Configuration

- A `.env` file at the project root (referenced as a Flutter asset via `pubspec.yaml`):
  ```dotenv
  RAPIDAPI_KEY=<your RapidAPI key with access to try-on-diffusion>
  GOOGLE_AI_API_KEY=<your Google AI Studio / Generative Language key>
  # Optional, used by setup.sh templating only
  ENVIRONMENT=development
  DEBUG_MODE=true
  ```
  This file is consumed via `flutter_dotenv` in `lib/main.dart`. Without it, `dotenv.load` will throw and the fallback red-text scaffold is shown.

- **Firebase project** matching `firebase_options.dart` and `android/app/google-services.json` — currently `fyp-fashion`. To use your own project, run `flutterfire configure`.

- **Recommendations API** — by default the code points at `https://simple-walrus-initially.ngrok-free.app`. This is an ngrok tunnel; you must either:
  - Stand up your own service exposing `/questions`, `/preferences`, `/recommendations`, **or**
  - Update `ApiService.baseUrl` in `lib/services/api_service.dart` to a stable URL.

- **External `crazy` package** — `lib/wardrobe.dart` imports `package:crazy/crazy_app_widget.dart`. The `pubspec.yaml` dependency line is currently commented out (`# crazy: # path: ...`). The Wardrobe tab will fail to compile until that dependency is restored (see §11 Blockers).

### 9.3 Dart Dependencies (from `pubspec.yaml`)

Flutter, `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`, `firebase_storage`, `shared_preferences`, `image_picker`, `google_generative_ai` (declared), `camera`, `speech_to_text`, `palette_generator`, `http`, `flutter_bloc` (declared), `cached_network_image`, `flutter_linkify`, `url_launcher`, `dio` (declared), `path_provider`, `path`, `http_parser`, `flutter_dotenv`, `flutter_image_compress`, `exif`, `image`, `cupertino_icons`, `shimmer`, `csv` (declared), `convex_bottom_bar`, `animated_bottom_navigation_bar` (declared). Dev: `flutter_test`, `flutter_lints`, `flutter_launcher_icons`.

### 9.4 First-Run Commands

```bash
git clone <repo>
cd Fashion-AI
./setup.sh                 # macOS/Linux helper (installs deps, scaffolds .env)
# or:
flutter pub get
# Restore the `crazy` dependency before this step or wardrobe.dart will fail.
flutter run                # launches on the connected device/emulator
```

---

## 10. Deployments Checklist

The application is a **client-only Flutter app** — there is no backend deployable from this repository. Cloud responsibilities are delegated to Firebase and the third-party APIs.

### 10.1 Target Platforms (configured)

| Platform | Status |
|---|---|
| Android | ✅ Configured. `applicationId = com.example.thefashionai`, `minSdk = 23`, FlutterFire Gradle plugin active, `google-services.json` present. |
| iOS | ⚠ Not configured. `firebase_options.dart` throws `UnsupportedError`. |
| Web | ⚠ Partial. `web/` folder + `manifest.json` exist; Firebase web config is missing. |
| Windows / macOS / Linux | ⚠ Not configured for Firebase. Launcher icons set up via `flutter_launcher_icons` for web/windows/macOS. |

### 10.2 App Distribution Pipeline

1. **Set production secrets** — store production `RAPIDAPI_KEY` and `GOOGLE_AI_API_KEY` in `.env` (or use `--dart-define` build args; the current code hard-codes `dotenv.env[...]` lookups so `.env` is the path of least resistance).
2. **Replace the development Firebase project** with your own using `flutterfire configure` — this regenerates `lib/firebase_options.dart` and writes the new `google-services.json` (and `GoogleService-Info.plist` for iOS).
3. **Configure signing** — `android/app/build.gradle` currently uses `signingConfigs.debug` for release builds (`// TODO: Add your own signing config`). Add a release keystore before publishing.
4. **Build artifacts**:
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   flutter build web --release        # only after web Firebase config is added
   ```
5. **Distribute** via Google Play Console (App Bundle), Firebase App Distribution, or your preferred channel.
6. **Backend services to provision separately**:
   - Firebase project: enable Email/Password and Google sign-in providers; configure Firestore security rules; configure Cloud Storage rules.
   - Recommendations API: deploy a stable host (Cloud Run, Render, Fly, etc.) replacing the ngrok URL.
   - RapidAPI subscription with sufficient quota for Try-On Diffusion.
   - Google AI Studio API key with access to `gemini-2.0-flash-exp` (or update the model id).

### 10.3 Operational Notes

- `firebase.json` in the project root is **not** the standard Firebase Hosting/Functions config — it is FlutterFire metadata. Hosting/Functions are not deployed from this repo.
- API keys are loaded **at startup** from `.env`; keys cannot be hot-rotated without rebuilding/restarting the app.
- Firestore security rules are not stored in this repo and must be defined in the Firebase Console (or via a separate Firebase config repo).

### 10.4 Pre-Flight Checklist

- [ ] Production `.env` populated.
- [ ] FlutterFire reconfigured for the production Firebase project.
- [ ] `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) deployed.
- [ ] Release signing config configured in `android/app/build.gradle`.
- [ ] Firestore security rules locked down (currently the schema-write code in `wardrobe.dart` and `profilepage.dart` assumes read/write under `users/{uid}`).
- [ ] Recommendations API host set in `ApiService.baseUrl` to a stable domain.
- [ ] RapidAPI quota and Gemini quota verified for the expected user load.
- [ ] `crazy` package dependency restored (path or git URL — see §11) or the Wardrobe tab refactored.

---

## 11. Payment Integration & Credit / Token System

**There is no payment or credit/token system implemented in this codebase.**

- No payment SDKs are declared in `pubspec.yaml`. Searches across the project for `stripe`, `payment`, `subscription`, `paypal`, `in_app_purchase`, `google_pay`, `apple_pay`, `credit`, and `token` return no application logic. The only matches for "token" are Firebase OAuth tokens used in Google Sign-In (`googleAuth.accessToken`, `googleAuth.idToken` in `lib/login.dart`) — these are auth tokens, not billing/credit tokens.
- No Cloud Functions, server endpoints, webhooks, billing dashboards, paywalls, or upgrade screens exist.
- All "premium-feeling" capabilities (Gemini chat, Try-On Diffusion) are gated only by:
  - The presence of the `RAPIDAPI_KEY` and `GOOGLE_AI_API_KEY` values in `.env`.
  - The third-party providers' own quotas/rate limits (RapidAPI plan limits on Try-On Diffusion; Google's Generative Language quotas).
- The economic model, if any, is **bring-your-own-API-key** — costs accrue to whoever owns the keys baked into `.env`, not to end users.

If a payment / credit system were to be introduced, the natural attachment points would be:

1. **Per-feature gating** — wrap calls in `lib/virtual_try_on.dart` (Try-On) and `lib/fashion_bot.dart::ApiService.sendFashionQuery` (Chat) with a credit-debit check before the HTTP request.
2. **Server-side enforcement** — proxy the RapidAPI and Gemini calls through your own backend so keys are not embedded in the client and quota is metered per user.
3. **Persistence** — extend the Firestore `users/{uid}` document with a `credits` field (or a `users/{uid}/wallet` subcollection) updated transactionally by Cloud Functions.
4. **Mobile billing** — `in_app_purchase` (Play Billing / StoreKit) for non-developer-key monetisation, or Stripe for web checkout if the web target is finished.

None of this is currently present.

---

## 12. Blockers & Critical Gaps

While generating this document, the following items were observed that would prevent or impair a clean run/release:

1. **Wardrobe build break (high severity)** — `lib/wardrobe.dart` imports `package:crazy/crazy_app_widget.dart`, but in `pubspec.yaml` the `crazy` dependency is commented out (`# crazy: # path: ...`) following the removal of a hardcoded Windows path. The Wardrobe tab will fail to compile until `crazy` is re-added (path, git, or pub.dev source).
2. **iOS / Web Firebase config missing** — `lib/firebase_options.dart` throws `UnsupportedError` for every platform other than Android. Re-run `flutterfire configure` if those targets matter.
3. **Production API host is an ngrok tunnel** — `ApiService.baseUrl = https://simple-walrus-initially.ngrok-free.app`. This URL is ephemeral; replace with a stable host before release (or for any non-developer testing).
4. **Embedded API keys via `.env` in the bundle** — `.env` is registered as a Flutter asset (`pubspec.yaml: assets: - .env`). On release builds the file ships inside the APK/AAB and can be extracted. Production deployments should proxy these calls through a server or use platform secret management instead.
5. **Release uses debug signing** — `android/app/build.gradle` keeps `// TODO: Add your own signing config for the release build` and reuses `signingConfigs.debug`. Required before any Play Store upload.
6. **No Firestore / Storage security rules in repo** — rules exist only in the Firebase Console (if at all). Without explicit rules, the wide-open Firestore writes in `WardrobePage._saveQuizDataToFirestore` may be exploitable.
7. **`SplashScreen` route fallback bypasses onboarding** — on any `_checkUserState` exception it routes straight to `LoginPage` even for first-time users; minor UX gap.
8. **Several declared dependencies are unused** — `flutter_bloc`, `dio`, `csv`, `animated_bottom_navigation_bar`, `google_generative_ai`, `camera`, `speech_to_text` are in `pubspec.yaml` but unused in code, inflating the build. Optional cleanup item.
9. **Hardcoded model id** — `gemini-2.0-flash-exp` is an experimental model name; if Google retires it, chat will silently start failing. Plan a migration path (env-driven model id).
10. **Anonymous sign-in available but undocumented in UI** — `LoginPage.signInAnonymously` exists but no button calls it; intentional or dead code, worth deciding before release.

Addressing items 1–5 is a hard prerequisite to ship; 6–10 are correctness/quality improvements.
