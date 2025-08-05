#!/bin/bash

# 🚀 Fashion AI - Quick Setup Script
# This script helps you set up the Fashion AI development environment

echo "🌟 Welcome to Fashion AI Setup!"
echo "================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Check Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor

# Install dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found!"
    echo "📝 Creating .env from template..."
    
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ Created .env file from template"
        echo "🔑 Please edit .env file and add your API keys:"
        echo "   - RAPIDAPI_KEY=your_rapidapi_key_here"
        echo "   - GOOGLE_AI_API_KEY=your_google_ai_key_here"
    else
        echo "❌ .env.example not found. Creating basic .env file..."
        cat > .env << EOF
# Fashion AI Environment Variables
RAPIDAPI_KEY=your_rapidapi_key_here
GOOGLE_AI_API_KEY=your_google_ai_key_here
ENVIRONMENT=development
DEBUG_MODE=true
EOF
        echo "✅ Created basic .env file"
    fi
else
    echo "✅ .env file already exists"
fi

# Check Firebase setup
echo "🔥 Checking Firebase setup..."
if command -v firebase &> /dev/null; then
    echo "✅ Firebase CLI found: $(firebase --version)"
    
    # Check if user is logged in
    if firebase projects:list &> /dev/null; then
        echo "✅ Firebase authenticated"
    else
        echo "⚠️  Firebase not authenticated. Run 'firebase login'"
    fi
else
    echo "⚠️  Firebase CLI not found. Install with:"
    echo "   npm install -g firebase-tools"
fi

# Check FlutterFire CLI
if dart pub global list | grep -q flutterfire_cli; then
    echo "✅ FlutterFire CLI found"
else
    echo "📦 Installing FlutterFire CLI..."
    dart pub global activate flutterfire_cli
fi

# Generate icons (if configured)
if grep -q flutter_launcher_icons pubspec.yaml; then
    echo "🎨 Generating app icons..."
    flutter pub run flutter_launcher_icons:main
fi

# Clean and get dependencies again
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

echo ""
echo "🎉 Setup Complete!"
echo "==================="
echo ""
echo "📋 Next Steps:"
echo "1. Edit .env file with your API keys"
echo "2. Configure Firebase: flutterfire configure"
echo "3. Run the app: flutter run"
echo ""
echo "📚 Documentation:"
echo "- README.md - Complete project documentation"
echo "- SECURITY.md - API key security guide"
echo "- .env.example - Environment variables template"
echo ""
echo "🆘 Need help? Check the documentation or create an issue on GitHub"
echo ""

# Try to open the project in VS Code if available
if command -v code &> /dev/null; then
    read -p "📝 Open project in VS Code? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        code .
    fi
fi

echo "✨ Happy coding with Fashion AI!"
