@echo off
setlocal EnableDelayedExpansion

:: Colors for Windows (limited)
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

:: Default values
set "FLAVOR=%~1"
set "CLEAN=%~2"
if "%FLAVOR%"=="" set "FLAVOR=opensource"
if "%CLEAN%"=="" set "CLEAN=false"

echo %INFO% Setting up Flutter app for %FLAVOR% flavor...

:: Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Flutter is not installed or not in PATH
    echo %INFO% Please install Flutter: https://docs.flutter.dev/get-started/install
    exit /b 1
)

:: Navigate to project root
cd /d "%~dp0\.."
echo %INFO% Project root: %CD%

:: Clean if requested
if "%CLEAN%"=="true" (
    echo %INFO% Cleaning previous build...
    flutter clean
    if exist .dart_tool rmdir /s /q .dart_tool
    if exist build rmdir /s /q build
)

:: Backup current pubspec
if exist pubspec.yaml (
    copy pubspec.yaml pubspec.yaml.backup >nul
    echo %INFO% Backed up current pubspec.yaml
)

:: Configure based on flavor
if /i "%FLAVOR%"=="opensource" goto :setup_opensource
if /i "%FLAVOR%"=="open" goto :setup_opensource
if /i "%FLAVOR%"=="free" goto :setup_opensource
if /i "%FLAVOR%"=="full" goto :setup_full
if /i "%FLAVOR%"=="premium" goto :setup_full
if /i "%FLAVOR%"=="licensed" goto :setup_full

echo %ERROR% Unknown flavor: %FLAVOR%
echo %INFO% Available flavors: opensource, full
exit /b 1

:setup_opensource
set "FLAVOR=opensource"
echo %INFO% 🆓 Configuring for Open Source version...

if not exist "build_configs\pubspec.opensource.yaml" (
    echo %ERROR% build_configs\pubspec.opensource.yaml not found!
    exit /b 1
)

copy "build_configs\pubspec.opensource.yaml" pubspec.yaml >nul

if exist "lib\licensing\licensed_features_loader_stub.dart" (
    copy "lib\licensing\licensed_features_loader_stub.dart" "lib\licensing\licensed_features_loader.dart" >nul
) else (
    echo %WARNING% Stub loader not found, creating basic one...
    if not exist "lib\licensing" mkdir "lib\licensing"
    (
        echo import 'feature_registry.dart';
        echo.
        echo class LicensedFeaturesLoader {
        echo   static Future^<void^> registerLicensedFeatures^(^) async {
        echo     print^('Licensed features not available in this build'^);
        echo   }
        echo }
    ) > "lib\licensing\licensed_features_loader.dart"
)

echo %SUCCESS% ✅ Open Source configuration applied
goto :install_deps

:setup_full
set "FLAVOR=full"
echo %INFO% ⭐ Configuring for Full version with licensed features...

if not exist "build_configs\pubspec.full.yaml" (
    echo %ERROR% build_configs\pubspec.full.yaml not found!
    exit /b 1
)

copy "build_configs\pubspec.full.yaml" pubspec.yaml >nul

if exist "lib\licensing\licensed_features_loader_full.dart" (
    copy "lib\licensing\licensed_features_loader_full.dart" "lib\licensing\licensed_features_loader.dart" >nul
) else (
    echo %ERROR% Full loader not found at lib\licensing\licensed_features_loader_full.dart
    echo %ERROR% Licensed features may not work properly
)

echo %SUCCESS% ✅ Full version configuration applied

:install_deps
echo %INFO% Getting Flutter dependencies...
flutter pub get

if errorlevel 1 (
    echo %ERROR% Failed to get dependencies
    exit /b 1
)

echo %SUCCESS% ✅ Dependencies installed successfully

:: Generate code if needed
echo %INFO% Generating code if needed...
findstr /c:"build_runner" pubspec.yaml >nul 2>&1
if not errorlevel 1 (
    flutter packages pub run build_runner build --delete-conflicting-outputs
)

:: Show completion message
echo.
echo %SUCCESS% 🎉 Setup complete!
echo.
echo Current Configuration:
echo   Flavor: %FLAVOR%
echo.
echo Next steps:
echo   1. Open your IDE (Android Studio, VS Code, etc.)
echo   2. Run the app normally (F5 in VS Code, or Run button in Android Studio)
echo   3. The app will launch with %FLAVOR% features
echo.
echo To switch flavors, run:
echo   scripts\setup-flavor.bat opensource
echo   scripts\setup-flavor.bat full