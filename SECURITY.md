# 🔐 API Key Security & Management Guide

This guide explains how to securely manage API keys and sensitive configuration in the Fashion AI project.

## 🚨 **Critical Security Practices**

### ❌ **NEVER Do This:**
- Don't commit API keys directly in code
- Don't push `.env` files to GitHub
- Don't hardcode sensitive data in source files
- Don't share API keys in chat/email/documents

### ✅ **ALWAYS Do This:**
- Use environment variables for all sensitive data
- Add `.env` to `.gitignore`
- Use GitHub Secrets for CI/CD
- Implement proper access controls

---

## 🛡️ **Method 1: Environment Variables (Development)**

### **Setup Steps:**

1. **Create Environment File**
   ```bash
   cp .env.example .env
   ```

2. **Fill in Your API Keys**
   ```env
   RAPIDAPI_KEY=your_actual_rapidapi_key_here
   GOOGLE_AI_API_KEY=your_actual_google_ai_key_here
   ```

3. **Update .gitignore**
   ```gitignore
   # Environment variables
   .env
   .env.local
   .env.*.local
   
   # API Keys
   **/api_keys.dart
   **/secrets.dart
   ```

4. **Load in Flutter**
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   void main() async {
     await dotenv.load(fileName: ".env");
     runApp(MyApp());
   }
   
   // Usage
   String? apiKey = dotenv.env['RAPIDAPI_KEY'];
   ```

---

## 🔑 **Method 2: Github Secrets (Production)**

### **For GitHub Actions/CI/CD:**

1. **Go to Repository Settings**
   - Navigate to your GitHub repository
   - Click on "Settings" tab
   - Go to "Secrets and variables" → "Actions"

2. **Add Repository Secrets**
   ```
   Name: RAPIDAPI_KEY
   Value: your_actual_rapidapi_key

   Name: GOOGLE_AI_API_KEY  
   Value: your_actual_google_ai_key

   Name: FIREBASE_CONFIG
   Value: your_firebase_config_json
   ```

3. **Use in GitHub Actions**
   ```yaml
   # .github/workflows/build.yml
   name: Build and Deploy
   
   on:
     push:
       branches: [ main ]
   
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         
         - name: Create .env file
           run: |
             echo "RAPIDAPI_KEY=${{ secrets.RAPIDAPI_KEY }}" >> .env
             echo "GOOGLE_AI_API_KEY=${{ secrets.GOOGLE_AI_API_KEY }}" >> .env
             
         - name: Build Flutter
           run: flutter build apk
   ```

---

## 🔒 **Method 3: Flutter Secure Storage (Runtime)**

### **Installation**
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

### **Implementation**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureApiManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );
  
  // Store API key securely
  static Future<void> storeApiKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  // Retrieve API key
  static Future<String?> getApiKey(String key) async {
    return await _storage.read(key: key);
  }
  
  // Delete API key
  static Future<void> deleteApiKey(String key) async {
    await _storage.delete(key: key);
  }
  
  // Initialize API keys (call this once on app start)
  static Future<void> initializeApiKeys() async {
    // Only store if not already present
    String? rapidApiKey = await getApiKey('rapidapi_key');
    if (rapidApiKey == null) {
      // Fetch from secure remote config or user input
      String key = await _fetchFromSecureSource('rapidapi');
      await storeApiKey('rapidapi_key', key);
    }
  }
  
  // Secure remote config fetch (implement based on your backend)
  static Future<String> _fetchFromSecureSource(String keyType) async {
    // Implement your secure key distribution mechanism
    // This could be from Firebase Remote Config, your own API, etc.
    throw UnimplementedError('Implement secure key fetching');
  }
}

// Usage in your app
class ApiService {
  static Future<String?> getRapidApiKey() async {
    return await SecureApiManager.getApiKey('rapidapi_key');
  }
  
  static Future<String?> getGoogleAiKey() async {
    return await SecureApiManager.getApiKey('google_ai_key');
  }
}
```

---

## 🛠️ **Method 4: Encrypted Configuration**

### **Advanced Encryption Approach**

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptedConfig {
  static const String _encryptedApiKeys = '''
    {
      "rapidapi": "encrypted_rapidapi_key_base64",
      "google_ai": "encrypted_google_ai_key_base64"
    }
  ''';
  
  static const String _keyHash = "your_key_hash_here";
  
  static String? decryptApiKey(String keyName, String userPassword) {
    try {
      // Verify user password
      var bytes = utf8.encode(userPassword);
      var digest = sha256.convert(bytes);
      
      if (digest.toString() != _keyHash) {
        throw Exception('Invalid password');
      }
      
      // Decrypt and return key
      Map<String, dynamic> keys = json.decode(_encryptedApiKeys);
      String encryptedKey = keys[keyName];
      
      // Implement your decryption logic here
      return _decrypt(encryptedKey, userPassword);
      
    } catch (e) {
      print('Decryption failed: $e');
      return null;
    }
  }
  
  static String _decrypt(String encryptedData, String password) {
    // Implement your preferred encryption/decryption algorithm
    // This is a placeholder - use a proper encryption library
    throw UnimplementedError('Implement proper decryption');
  }
}
```

---

## 🔧 **Method 5: Firebase Remote Config**

### **Setup Firebase Remote Config**

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static FirebaseRemoteConfig? _remoteConfig;
  
  static Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    // Set default values
    await _remoteConfig!.setDefaults({
      'rapidapi_key': '',
      'google_ai_key': '',
      'enable_debug': false,
    });
    
    await _remoteConfig!.fetchAndActivate();
  }
  
  static String getRapidApiKey() {
    return _remoteConfig?.getString('rapidapi_key') ?? '';
  }
  
  static String getGoogleAiKey() {
    return _remoteConfig?.getString('google_ai_key') ?? '';
  }
  
  static bool isDebugEnabled() {
    return _remoteConfig?.getBool('enable_debug') ?? false;
  }
}

// Usage
await RemoteConfigService.initialize();
String apiKey = RemoteConfigService.getRapidApiKey();
```

---

## 📊 **Best Practices Summary**

### **Development Environment**
1. Use `.env` files for local development
2. Never commit `.env` to version control
3. Use `.env.example` as a template

### **Production Environment**
1. Use GitHub Secrets for CI/CD
2. Use Firebase Remote Config for runtime config
3. Implement proper access controls

### **Mobile App Security**
1. Use Flutter Secure Storage for sensitive data
2. Implement biometric authentication
3. Use certificate pinning for API calls
4. Implement root/jailbreak detection

### **Team Collaboration**
1. Share API keys through secure channels only
2. Use different keys for development/production
3. Rotate keys regularly
4. Monitor API key usage

---

## 🚨 **Emergency Response**

### **If API Keys Are Compromised:**

1. **Immediate Actions**
   - Revoke compromised keys immediately
   - Generate new API keys
   - Update all environments

2. **Investigation**
   - Check commit history for exposure
   - Review access logs
   - Identify affected systems

3. **Prevention**
   - Update security practices
   - Implement monitoring
   - Train team on security

---

## 📋 **Security Checklist**

- [ ] `.env` file is in `.gitignore`
- [ ] No API keys in source code
- [ ] GitHub Secrets configured
- [ ] Firebase Remote Config setup
- [ ] Secure Storage implemented
- [ ] Team trained on security practices
- [ ] Key rotation schedule established
- [ ] Monitoring and alerting configured

---

## 🔗 **Additional Resources**

- [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/security)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security-testing-guide/)

---

**Remember: Security is not a one-time setup but an ongoing practice!**
