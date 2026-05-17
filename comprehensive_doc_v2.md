# Fashion AI — Comprehensive Documentation (v2)

> Generated: 2026-05-16
> Repository: `Fashion-AI` (Flutter package: `thefashionai`)
> Firebase project: `iems-c0c29`
> Primary branch: `master`

---

## 1. System Overview

**Fashion AI** is a Flutter mobile application (Android-only at present) that uses AI to assist users with fashion discovery, styling, and virtual try-on. It is targeted primarily at Pakistani fashion brands (Breakout, Chase Value, Ideas, Outfitter).

### Primary Features
- **AI Fashion Bot** — conversational stylist powered by Google **Gemini 2.0 Flash**, supports text and image queries (color analysis, outfit suggestions, body-type advice).
- **Virtual Try-On** — generates an image of the user wearing a selected garment via the **Try-On Diffusion** API (RapidAPI).
- **Outfit Recommendations** — quiz-based personalization served by a custom backend exposed via ngrok.
- **Wardrobe / Style Quiz** — captures user style preferences, persists to Firestore (`crazy` quiz widget currently stubbed).
- **Multi-brand catalog browsing** — asset-bundled product images organized by brand, gender, and category.
- **Authentication** — Firebase Auth with Email/Password, Google Sign-In, and anonymous fallback.

---

## 2. System Flow

### Process Flow (cold start → feature use)

1. `main()` → `WidgetsFlutterBinding.ensureInitialized()` → `dotenv.load('.env')` → `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` → `runApp(MyApp())`.
2. `SplashScreen` (3-second animation) reads `SharedPreferences.hasSeenOnboarding` and `FirebaseAuth.instance.currentUser`.
3. Routing decision:
   - New user → `OnboardingScreen` → `LoginPage`.
   - Returning, unauthenticated → `LoginPage`.
   - Authenticated → `HomePage`.
4. `HomePage` hosts a `ConvexAppBar` with 4 tabs: **Home**, **AI Fashion**, **Virtual Try-On**, **Wardrobe**.
5. Each feature initiates its own data flow (see Data Flow below).

### Data Flow per Feature

| Feature | Source → Sink | Transport |
|---|---|---|
| Auth | Client ↔ Firebase Auth | Firebase SDK |
| Fashion Bot | Client → `generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent` → Client | HTTPS POST (JSON; Base64 for images) |
| Virtual Try-On | Client → RapidAPI `try-on-diffusion` endpoint → Client | HTTPS multipart POST |
| Recommendations | Client → `https://simple-walrus-initially.ngrok-free.app/{questions,preferences,recommendations}` → Client | HTTPS GET/POST (JSON) |
| Wardrobe / Profile | Client ↔ Firestore `users/{uid}` | Firestore SDK |
| Category Browse | Asset bundle → `CategoryManager` singleton → UI | In-memory (AssetManifest.json scan) |
| Try-On asset handoff | `BrandPage` / `UnifiedCategoryPage` → `SharedPreferences['selectedClothingPath']` → `VirtualTryOn` init | Local KV store |

---

## 3. User Flow

A canonical first-time user journey:

1. **Launch** → animated splash screen.
2. **Onboarding carousel** — three pages: "The AI Fashion App That…", "Makes You Look Your Best", "Discover Your Style". Sets `hasSeenOnboarding = true`.
3. **Sign-up / Login** — choose Email+Password, Google, or anonymous. Profile picture optional at signup (path saved to SharedPreferences).
4. **Home tab** — browse brand cards (Breakout, Chase Value, Ideas, Outfitter). Tap a brand → `BrandPage` (tabbed by gender).
5. **Tap product** → "Send to Try-On" stores asset path locally.
6. **Virtual Try-On tab** — auto-loads saved garment. Pick user image (camera/gallery), specify gender, submit → RapidAPI returns generated image.
7. **AI Fashion tab** — chat with StyleBot; attach a photo for analysis if desired.
8. **Wardrobe tab** — take the style quiz (currently stubbed placeholder). Quiz tags persist to Firestore.
9. **Profile** (from app bar) — view username, email, last survey results, and recommendation thumbnails.
10. **Sign out** — clears Firebase session; next launch returns to `LoginPage`.

---

## 4. Architecture

### Layered View

```
┌──────────────────────────────────────────────────────────┐
│  Presentation (Flutter Widgets)                          │
│  splashscreen, login, sighup, homepage, brand_page,      │
│  unified_category_page, virtual_try_on, fashion_bot,     │
│  wardrobe, profilepage, screens/, widgets/                │
├──────────────────────────────────────────────────────────┤
│  Domain / Models                                          │
│  lib/models/ (Question, Recommendation, UserPreferences)  │
├──────────────────────────────────────────────────────────┤
│  Services                                                 │
│  lib/services/api_service.dart   → ngrok recommender      │
│  lib/services/storage_service.dart → SharedPreferences    │
│  lib/category_manager.dart       → asset catalog          │
│  ApiService inside fashion_bot.dart → Gemini              │
├──────────────────────────────────────────────────────────┤
│  Platform / Backends                                      │
│  Firebase (Auth, Firestore, Storage)                      │
│  Google Generative AI (Gemini 2.0 Flash)                  │
│  RapidAPI (Try-On Diffusion)                              │
│  Custom ngrok backend (recommendations)                   │
└──────────────────────────────────────────────────────────┘
```

### State Management
- **No global state library.** All screens are `StatefulWidget` with local `setState` and cross-screen coordination via `SharedPreferences`.
- `CategoryManager` is a **singleton** that lazily scans `AssetManifest.json` to build a brand/gender/category index.

### Initialization Sequence (`lib/main.dart`)
```dart
WidgetsFlutterBinding.ensureInitialized();
await dotenv.load(fileName: ".env");
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
runApp(MyApp());
```

### External Integrations
- **Gemini** — `ApiService` class inside `lib/fashion_bot.dart` (lines 400–509). REST POST with a system prompt establishing the "StyleBot" persona.
- **RapidAPI** — direct `http.MultipartRequest` from `lib/virtual_try_on.dart`. Key read from `dotenv`.
- **ngrok backend** — `lib/services/api_service.dart` (66 lines), three endpoints: `GET /questions`, `POST /preferences`, `GET /recommendations`.

---

## 5. Folder Structure

### Top-level
| Directory | Purpose |
|---|---|
| `android/` | Android Gradle project; `app/build.gradle`, `google-services.json` (project: `iems-c0c29`) |
| `ios/` | iOS scaffold (NOT configured — `firebase_options.dart` throws on iOS) |
| `web/` | Flutter web scaffold (unsupported by Firebase config) |
| `lib/` | Dart source (26 files; see below) |
| `assets/` | Brand product images, CSV catalogs, UI graphics, onboarding imagery |
| `test/` | Default `widget_test.dart` only |
| `build/` | Build output (gitignored) |
| `.backup-firebase-fyp-fashion/` | Backup of pre-migration Firebase config |

### `lib/` source files
| File | Role |
|---|---|
| `main.dart` | Entry point; Firebase + dotenv init |
| `splashscreen.dart` | Animated splash + routing decision |
| `onboardingscreen.dart` | 3-page intro carousel |
| `login.dart` | Email / Google / anonymous sign-in |
| `sighup.dart` | Email signup, display name update, profile image |
| `homepage.dart` | Bottom-tab shell, 4 features |
| `brand_page.dart` | Per-brand product grid (gender tabs) |
| `unified_category_page.dart` | Cross-brand category browse |
| `subcategory.dart` | Sub-filter within a category |
| `category_manager.dart` | Singleton asset catalog from `AssetManifest.json` |
| `virtual_try_on.dart` | Image capture, EXIF/compression, RapidAPI call |
| `fashion_bot.dart` | Chat UI + `ApiService` (Gemini integration) |
| `wardrobe.dart` | Style quiz (stubbed) + Firestore write |
| `profilepage.dart` | Profile + survey/recommendation display |
| `app_theme.dart` | `AppTheme` constants (Deep Blue primary palette) |
| `firebase_options.dart` | FlutterFire-generated Firebase config |

### `lib/` subfolders
| Folder | Files | Purpose |
|---|---|---|
| `models/` | `question.dart`, `recommendation_model.dart`, `user_preferences_model.dart` | JSON-serializable DTOs for the recommender |
| `screens/` | `choice_screen.dart`, `questionnaire_screen.dart`, `results_screen.dart`, `outfit_details_screen.dart` | Quiz flow screens |
| `services/` | `api_service.dart`, `storage_service.dart` | ngrok client and local persistence |
| `widgets/` | `question_widget.dart` | Reusable quiz question widget |

### `assets/`
- `All Brands/` — `Break Out Men/`, `Break Out Women/`, `Chase Value Men/`, `Chase Value Women/`, `Ideas Men/`, `Ideas Women/`, `Outfitter Men/`, `Outfitter Women/` with category subfolders.
- `csv/` — `questions.csv`, `clothing.csv` (currently **unreferenced** in code).
- `images/` — 136 UI icons / thumbnails.
- Loose files: `bg.jpg`, `bg2.jpg`, `logo*.{jpg,png,webp}`, `img1/2/3.jpg` (onboarding), `F*.jpeg` (sample products).

---

## 6. Backend Overview

Fashion AI has **no first-party server** in this repository. The "backend" is a composition of managed services and one external service:

### 6.1 Firebase (Google)
- **Auth** — Email/Password ✅, Google ✅ (both confirmed enabled in console). Anonymous available.
- **Firestore** — `(default)` database provisioned in `asia-south1` (Mumbai); rules deployed.
- **Storage** — Rules file present but **bucket not provisioned** (deferred; not required by current feature set).
- **Rules** (`firestore.rules`):
  ```
  match /users/{uid}/{document=**} {
    allow read, write: if isOwner(uid);
  }
  function isOwner(uid) {
    return request.auth != null && request.auth.uid == uid;
  }
  ```
- **Indexes** (`firestore.indexes.json`) — empty; defaults only.

### 6.2 Google Generative AI (Gemini)
- Direct REST from the client.
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key={GOOGLE_AI_API_KEY}`.
- Two paths: text-only, and text + Base64-encoded image (multipart JSON via `contents.parts[].inline_data`).
- Implementation: `ApiService` class at the bottom of `lib/fashion_bot.dart` (~lines 400–509). System prompt establishes the "StyleBot" persona.

### 6.3 RapidAPI — Try-On Diffusion
- Direct REST from the client with `RAPIDAPI_KEY` header.
- Garment image and user image are uploaded; resulting composite image is downloaded.
- Implementation: `lib/virtual_try_on.dart` (image picking, EXIF, compression, then HTTP request).

### 6.4 ngrok-fronted recommender
- Base URL: `https://simple-walrus-initially.ngrok-free.app`
- Endpoints used by `lib/services/api_service.dart`:
  - `GET /questions` → `List<Question>`
  - `POST /preferences` (JSON body of `UserPreferences`)
  - `GET /recommendations` → `List<OutfitRecommendation>`
- **Warning**: ngrok URLs are ephemeral; production must replace this with a stable host.

### Request Handling Pattern
All HTTP work uses the `http` package directly. Responses are parsed with `jsonDecode` then mapped into model classes (`fromJson`). There is no retry, backoff, or centralized error handler — errors bubble to UI via `setState({ errorMessage })`.

---

## 7. Frontend Overview

### Framework
- **Flutter 3.6+** (Dart SDK).
- **Material** widgets with a custom theme defined in `lib/app_theme.dart` (Deep Blue primary).

### Major Components
| Component | Role |
|---|---|
| `MyApp` (`main.dart`) | Root `MaterialApp`, sets theme, `home: SplashScreen()` |
| `SplashScreen` | Auth + onboarding routing |
| `OnboardingScreen` | `PageView` of 3 intro pages |
| `LoginPage` / `SignupPage` | Auth forms; Google button; error message via `setState` |
| `HomePage` | `Scaffold` + `ConvexAppBar`; swaps body widget per tab |
| `HomeContent` | Brand selection grid |
| `BrandPage` | Per-brand grid with gender tabs and "Send to Try-On" |
| `UnifiedCategoryPage` / `SubcategoryPage` | Category browsing |
| `VirtualTryOn` | Image pickers, processing, API submission, result preview |
| `ChatScreen` (`fashion_bot.dart`) | Bubble chat UI, image attachment, Gemini calls |
| `WardrobePage` | Style quiz host (currently shows placeholder); writes to Firestore |
| `ProfilePage` | Reads `users/{uid}` and renders survey + recommendation grid |

### UI Libraries
- `convex_bottom_bar` — primary nav.
- `shimmer` — loading skeletons.
- `cached_network_image` — recommendation thumbnails.
- `palette_generator` — extract colors from images for the bot.
- `flutter_linkify` + `url_launcher` — clickable links in chat.

### Major Workflows
- **Auth → Home**: covered in §3.
- **Try-On**: Brand grid → Send to Try-On → Try-On tab → Pick user photo → Submit → Display result.
- **Bot**: Tab → Type or attach image → Submit → Render Gemini response (markdown cleaned).
- **Wardrobe**: Tab → Quiz (stub) → Save to Firestore → Visible in Profile.

---

## 8. Schema

There is **no SQL database**. Data lives in Firestore, SharedPreferences, and the asset bundle. The recommender API uses JSON DTOs.

### Firestore document — `users/{uid}`
```json
{
  "surveyData": {
    "timestamp": "<server timestamp>",
    "Style": ["minimalist", "casual"],
    "Color Palette": "blue,white,black",
    "Clothing Type": ["shirts", "jeans"],
    "Gender": "Not specified",
    "recommendationUrls": [
      "https://.../outfit1.jpg",
      "https://.../outfit2.jpg"
    ]
  },
  "lastSurveyDate": "<server timestamp>"
}
```

### Recommender DTOs (`lib/models/`)
```dart
// question.dart
class Question {
  String id;
  String question;
  String questionType;   // single / multi / text
  List<String> options;
  String? correctAnswer; // unused at runtime
}

// recommendation_model.dart
class Recommendation {
  String id;
  String name;
  String description;
  String imageUrl;        // alias: image_url
  double confidenceScore; // alias: confidence_score
  List<String> tags;
}

class OutfitRecommendation {
  int outfitNumber;
  Map<String, String> components; // slot → item label/url
}

// user_preferences_model.dart
class UserPreferences {
  String gender;
  List<String> itemTypes;
  List<String> styleVibes;
  List<String> favoriteColors;
  List<String> preferredMaterials;
  List<String> keyOccasions;
  List<String> primarySeasons;
  String casualOutfitStyle;
  String formalOutfitColor;
  String specificOccasion;
  Map<String, ItemSpecificPreference> itemSpecificPreferences;
}

class ItemSpecificPreference {
  List<String> colors;
  List<String> materials;
}
```

### SharedPreferences keys
| Key | Purpose |
|---|---|
| `hasSeenOnboarding` | Skip onboarding on next launch |
| `profileImagePath` | Local path to user-uploaded profile photo |
| `selectedClothingPath` | Asset path passed from catalog → Try-On |
| (quiz cache) | Cached recommendations / tags |

---

## 9. Essentials Checklist

To build and run the app locally:

### Toolchain
- [ ] Flutter SDK ≥ 3.6 (`flutter --version`)
- [ ] Dart ≥ 3.6
- [ ] Android Studio + Android SDK (target ≥ 21)
- [ ] JDK 17 (for Gradle)
- [ ] Kotlin 1.8+ (warning surfaces in build logs if mismatched)
- [ ] Firebase CLI (for rules/index deploys, not required to run the app)

### Repository setup
- [ ] `flutter pub get`
- [ ] Create `.env` from `.env.example` and populate:
  - `GOOGLE_AI_API_KEY` — https://aistudio.google.com/app/apikey
  - `RAPIDAPI_KEY` — RapidAPI account subscribed to **Try-On Diffusion**
- [ ] Ensure `android/app/google-services.json` matches Firebase project `iems-c0c29` (already in repo)
- [ ] `lib/firebase_options.dart` is generated and points at `iems-c0c29` (already done)

### Backend dependencies
- [ ] Firebase project `iems-c0c29` Auth providers: **Email/Password** + **Google** enabled (verified 2026-05-16)
- [ ] Firestore database created in `asia-south1` with rules deployed (done)
- [ ] Recommender ngrok URL reachable: `https://simple-walrus-initially.ngrok-free.app/questions`
  - **Note**: ngrok tunnels rotate; verify before each demo.

### Known stubs / warnings
- `crazy` package (style quiz UI) is commented out in `pubspec.yaml`; `wardrobe.dart` displays placeholder.
- iOS/web platforms are unsupported by current Firebase config (`firebase_options.dart` throws).
- `.env` is bundled as a Flutter asset → API keys ship inside the APK. For production: move to `--dart-define` or proxy through a backend.

### Run
```bash
flutter pub get
flutter run -d <android_device_id>
# or
flutter build apk --debug
```

---

## 10. Deployments Checklist

The project is currently a **debug-only** Android Flutter app with no CI/CD wiring and no first-party server to deploy. Below is what is configured today and what must be added for a production rollout.

### Mobile (Android — current target)
- **Platform**: Google Play Store.
- **Artifact**: APK / AAB built via `flutter build appbundle --release`.
- **App id**: `com.example.thefashionai` (must be changed before publishing — `com.example.*` is rejected by Play).
- **Signing**: No release `keystore` is configured. Add `android/key.properties` + signing config in `android/app/build.gradle`.
- **Min SDK**: 21 / **Target SDK**: Flutter default (currently 34).
- **Permissions** (declared by Flutter plugins): camera, photo library, internet.

### Firebase (already provisioned)
| Resource | State |
|---|---|
| Project `iems-c0c29` | Created |
| Auth — Email/Password | Enabled |
| Auth — Google | Enabled |
| Firestore `(default)` in `asia-south1` | Created |
| Firestore rules | Deployed |
| Firestore indexes | Deployed (empty) |
| Storage bucket | **NOT provisioned** (not required by current features) |

Deploy command:
```bash
firebase deploy --only firestore:rules,firestore:indexes --project iems-c0c29
```

### Backend (recommender)
- Currently exposed via ngrok (`simple-walrus-initially.ngrok-free.app`) — ephemeral.
- **Pre-launch**: migrate to a stable host. Candidates:
  - **Google Cloud Run** (good fit — already in Google ecosystem; pay-per-use; HTTPS by default)
  - **Render / Fly.io** for low-cost containers
- Update `baseUrl` in `lib/services/api_service.dart` after migration.

### Secrets handling
- `.env` is currently asset-bundled → **not safe for production**. Replace with:
  - Build-time injection: `--dart-define=GOOGLE_AI_API_KEY=...`
  - Or proxy Gemini + RapidAPI calls through your own backend so keys never ship to the device.

### Suggested release pipeline
1. Bump `version` in `pubspec.yaml`.
2. `flutter analyze && flutter test`.
3. `flutter build appbundle --release --dart-define=GOOGLE_AI_API_KEY=... --dart-define=RAPIDAPI_KEY=...`.
4. Upload AAB to Play Console (internal testing → closed → production).
5. Tag release in git; deploy Firestore rules if changed.

There is currently **no GitHub Actions / Codemagic / Bitrise** workflow — CI must be added.

---

## 11. Payment Integration & Credit / Token System

**Status: NOT IMPLEMENTED.**

Verification performed on 2026-05-16:

```bash
grep -ri "stripe\|payment\|subscription\|in_app_purchase\|billing\|credit\|token\|purchase" lib/
```

Findings:
- No references to Stripe, PayPal, Razorpay, JazzCash, Easypaisa, or any other payment provider.
- No use of `in_app_purchase`, `pay`, `flutter_stripe`, or `purchases_flutter` (RevenueCat).
- The word "token" appears only in the context of Firebase auth tokens (`idToken`, `accessToken`) in `lib/login.dart` and Gemini API keys — **not** as a credit/usage unit.
- No credit balance, quota, or metering logic is present in `lib/services/` or anywhere in `lib/`.
- The app is currently **free-to-use** with no monetization layer.

### If payments are required next
A typical Flutter monetization stack to add:
- **In-app subscriptions**: `in_app_purchase` (native Play Billing) — most appropriate for Play Store launch.
- **Credits / metering**: a Firestore subcollection `users/{uid}/credits` with server-side decrement via Cloud Functions to prevent client tampering. Each call to Gemini or Try-On Diffusion would consume credits.
- **Cross-platform billing aggregator**: RevenueCat (`purchases_flutter`) for receipt validation and entitlements.
- **Web checkout fallback**: Stripe Checkout if the catalog ever ships to the web.

None of the above is currently scaffolded.

---

## Blockers & Critical Gaps (Review)

Reviewed after writing this document — items that could prevent the app from running or being shipped:

1. **ngrok URL is ephemeral** (`lib/services/api_service.dart`). If the tunnel is down, the Wardrobe quiz → recommendations flow fails. **Blocker for any reliable run.**
2. **API keys are asset-bundled** (`.env` listed in `pubspec.yaml` assets). Functional, but a **security blocker** before release.
3. **`crazy` package stubbed** (`lib/wardrobe.dart`, `pubspec.yaml` line 12). Wardrobe style-quiz UI shows a placeholder — not a runtime blocker but a feature gap.
4. **App ID is `com.example.thefashionai`** — Play Store will reject this; must be renamed before publishing.
5. **No release signing config** — release builds will not be installable on user devices.
6. **No CI/CD** — manual builds only.
7. **iOS and web are not configured** — `firebase_options.dart` throws on those platforms.
8. **Tests are essentially empty** (`test/widget_test.dart` is the default Flutter counter test) — quality gate missing.
9. **Storage bucket not provisioned** — not currently required by features in `lib/`, but `pubspec.yaml` declares `firebase_storage` so any future upload code will need the console "Get Started" click first.
10. **No payment system** — see §11; required if monetization is on the roadmap.

Items 1, 2, 4, and 5 are pre-release blockers. Items 3, 7, 8, 10 are feature/quality gaps. The app **will run today** for local development with the existing `.env` and live ngrok tunnel.
