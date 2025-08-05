@echo off
setlocal enabledelayedexpansion

REM 🚀 Fashion AI - Quick Setup Script (Windows)
REM This script helps you set up the Fashion AI development environment

echo 🌟 Welcome to Fashion AI Setup!
echo ================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first:
    echo    https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version | findstr /C:"Flutter"

REM Check Flutter doctor
echo.
echo 🔍 Running Flutter doctor...
flutter doctor

REM Install dependencies
echo.
echo 📦 Installing Flutter dependencies...
flutter pub get

REM Check if .env exists
if not exist ".env" (
    echo.
    echo ⚠️  .env file not found!
    echo 📝 Creating .env from template...
    
    if exist ".env.example" (
        copy ".env.example" ".env" >nul
        echo ✅ Created .env file from template
        echo 🔑 Please edit .env file and add your API keys:
        echo    - RAPIDAPI_KEY=your_rapidapi_key_here
        echo    - GOOGLE_AI_API_KEY=your_google_ai_key_here
    ) else (
        echo ❌ .env.example not found. Creating basic .env file...
        (
            echo # Fashion AI Environment Variables
            echo RAPIDAPI_KEY=your_rapidapi_key_here
            echo GOOGLE_AI_API_KEY=your_google_ai_key_here
            echo ENVIRONMENT=development
            echo DEBUG_MODE=true
        ) > .env
        echo ✅ Created basic .env file
    )
) else (
    echo ✅ .env file already exists
)

REM Check Firebase setup
echo.
echo 🔥 Checking Firebase setup...
firebase --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Firebase CLI found
    firebase --version
    
    REM Check if user is logged in
    firebase projects:list >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ Firebase authenticated
    ) else (
        echo ⚠️  Firebase not authenticated. Run 'firebase login'
    )
) else (
    echo ⚠️  Firebase CLI not found. Install with:
    echo    npm install -g firebase-tools
)

REM Check FlutterFire CLI
dart pub global list | findstr "flutterfire_cli" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ FlutterFire CLI found
) else (
    echo 📦 Installing FlutterFire CLI...
    dart pub global activate flutterfire_cli
)

REM Generate icons (if configured)
findstr "flutter_launcher_icons" pubspec.yaml >nul 2>&1
if %errorlevel% equ 0 (
    echo 🎨 Generating app icons...
    flutter pub run flutter_launcher_icons:main
)

REM Clean and get dependencies again
echo.
echo 🧹 Cleaning project...
flutter clean
flutter pub get

echo.
echo 🎉 Setup Complete!
echo ===================
echo.
echo 📋 Next Steps:
echo 1. Edit .env file with your API keys
echo 2. Configure Firebase: flutterfire configure
echo 3. Run the app: flutter run
echo.
echo 📚 Documentation:
echo - README.md - Complete project documentation
echo - SECURITY.md - API key security guide
echo - .env.example - Environment variables template
echo.
echo 🆘 Need help? Check the documentation or create an issue on GitHub
echo.

REM Try to open the project in VS Code if available
where code >nul 2>&1
if %errorlevel% equ 0 (
    set /p choice="📝 Open project in VS Code? (y/n): "
    if /i "!choice!"=="y" (
        code .
    )
)

echo ✨ Happy coding with Fashion AI!
echo.
pause
