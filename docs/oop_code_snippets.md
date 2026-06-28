# Object Oriented Approach — Code Snippets

Fit Mirror uses an object-oriented approach to manage system logic. Below are the core classes, their attributes, and methods implemented in Dart.

---

## 1. User Object

```dart
class User {
  final String userId;
  String username;
  String email;

  User({
    required this.userId,
    required this.username,
    required this.email,
  });

  static Future<User?> registerUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'userId': uid,
        'username': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return User(userId: uid, username: name, email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration failed: ${e.message}');
      return null;
    }
  }
}
```

---

## 2. Product Object

```dart
class Product {
  final String productId;
  final String brand;
  final String category;
  final double price;

  Product({
    required this.productId,
    required this.brand,
    required this.category,
    required this.price,
  });

  static Future<Product?> getProductDetails(String productId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();

    if (!snapshot.exists) return null;

    final data = snapshot.data()!;
    return Product(
      productId: productId,
      brand: data['brand'] as String,
      category: data['category'] as String,
      price: (data['price'] as num).toDouble(),
    );
  }
}
```

---

## 3. Try-on Engine Object

```dart
class TryOnEngine {
  final String tryOnId;
  final String userImageRef;
  String status; // 'pending' | 'processing' | 'completed' | 'failed'

  TryOnEngine({
    required this.tryOnId,
    required this.userImageRef,
    this.status = 'pending',
  });

  Future<String?> generateTryOn(
    String userPhoto,
    String garmentPhoto,
  ) async {
    status = 'processing';

    final response = await http.post(
      Uri.parse('https://try-on-diffusion.p.rapidapi.com/try-on-url'),
      headers: {
        'X-RapidAPI-Key': dotenv.env['RAPIDAPI_KEY']!,
        'X-RapidAPI-Host': 'try-on-diffusion.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clothing_image_url': garmentPhoto,
        'avatar_image_url': userPhoto,
      }),
    );

    if (response.statusCode == 200) {
      status = 'completed';
      final data = jsonDecode(response.body);
      return data['result_url'] as String?;
    }

    status = 'failed';
    return null;
  }
}
```

---

## 4. Fashion Assistant Object

```dart
class FashionAssistant {
  final String assistantId;
  final List<Map<String, String>> chatHistory;

  FashionAssistant({
    required this.assistantId,
    List<Map<String, String>>? chatHistory,
  }) : chatHistory = chatHistory ?? [];

  Future<String> getStylingAdvice(String queryText) async {
    chatHistory.add({'role': 'user', 'content': queryText});

    final reply = await _callGemini(queryText);

    chatHistory.add({'role': 'assistant', 'content': reply});
    return reply;
  }

  Future<String> suggestOutfit(String occasion) async {
    final prompt =
        'Suggest a complete outfit suitable for the following occasion: $occasion. '
        'Include top, bottom, footwear, and accessories.';
    return getStylingAdvice(prompt);
  }

  Future<String> _callGemini(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-2.0-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
```

---

## 5. Wardrobe Object

```dart
class Wardrobe {
  final String wardrobeId;
  final String ownerId;
  final List<String> itemsLists;

  Wardrobe({
    required this.wardrobeId,
    required this.ownerId,
    List<String>? itemsLists,
  }) : itemsLists = itemsLists ?? [];

  Future<void> addItem(String productId) async {
    if (itemsLists.contains(productId)) return;

    itemsLists.add(productId);

    await FirebaseFirestore.instance
        .collection('wardrobes')
        .doc(wardrobeId)
        .update({
      'itemsLists': FieldValue.arrayUnion([productId]),
    });
  }

  Future<void> removeItem(String productId) async {
    itemsLists.remove(productId);

    await FirebaseFirestore.instance
        .collection('wardrobes')
        .doc(wardrobeId)
        .update({
      'itemsLists': FieldValue.arrayRemove([productId]),
    });
  }
}
```
