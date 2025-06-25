@echo off
setlocal EnableDelayedExpansion

:: --- Configuration ---
set "LICENSED_REPO_URL=git@github.com:jlbbooks/teleferika_licenced_packages.git"
set "LICENSED_PACKAGE_DIR_NAME=licensed_features_package"
:: --- End Configuration ---

:: Colors for Windows (limited, using prefixes)
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

:: Check if Git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Git is not installed or not in PATH.
    echo %INFO% Please install Git: https://git-scm.com/downloads
    exit /b 1
)

:: Navigate to project root (assuming script is in a 'scripts' subdirectory)
cd /d "%~dp0\.."
set "PROJECT_ROOT=%CD%"
echo %INFO% Project root: %PROJECT_ROOT%
set "LICENSED_PACKAGE_DIR_FULL_PATH=%PROJECT_ROOT%\%LICENSED_PACKAGE_DIR_NAME%"


:: Clean if requested
if /i "%CLEAN%"=="true" (
    echo %INFO% Cleaning previous build...
    flutter clean
    if exist .dart_tool rmdir /s /q .dart_tool
    if exist build rmdir /s /q build
    :: Optionally remove the licensed package directory if you want a fresh clone every time with clean
    :: if exist "%LICENSED_PACKAGE_DIR_FULL_PATH%" rmdir /s /q "%LICENSED_PACKAGE_DIR_FULL_PATH%"
)

:: Configure based on flavor
if /i "%FLAVOR%"=="opensource" goto setup_opensource
if /i "%FLAVOR%"=="open" goto setup_opensource
if /i "%FLAVOR%"=="free" goto setup_opensource
if /i "%FLAVOR%"=="full" goto setup_full
if /i "%FLAVOR%"=="premium" goto setup_full
if /i "%FLAVOR%"=="licensed" goto setup_full

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
    if not exist "lib\licensing" mkdir "lib\licensing"
    copy "lib\licensing\licensed_features_loader_stub.dart" "lib\licensing\licensed_features_loader.dart" >nul
) else (
    echo %WARNING% Stub loader not found, creating basic one...
    if not exist "lib\licensing" mkdir "lib\licensing"
    (
        echo class LicensedFeaturesLoader {
        echo   static Future^<void^> registerLicensedFeatures^(^) async {
        echo     // Stub implementation
        echo     print^('Licensed features not available in this build (stub loader)'^);
        echo   }
        echo }
    ) > "lib\licensing\licensed_features_loader.dart"
)

echo %SUCCESS% ✅ Open Source configuration applied
goto install_deps

:setup_full
set "FLAVOR=full"
echo %INFO% ⭐ Configuring for Full version with licensed features...

:: Clone or update the licensed features repository
if exist "%LICENSED_PACKAGE_DIR_FULL_PATH%\.git" (
    echo %INFO% Licensed features repository already exists in "%LICENSED_PACKAGE_DIR_NAME%". Attempting to pull latest changes...
    cd /d "%LICENSED_PACKAGE_DIR_FULL_PATH%"
    git pull
    if errorlevel 1 (
        echo %WARNING% Failed to pull latest changes for licensed features. Using existing version.
    ) else (
        echo %SUCCESS% Pulled latest changes for licensed features.
    )
    cd /d "%PROJECT_ROOT%"
) else if exist "%LICENSED_PACKAGE_DIR_FULL_PATH%" (
    echo %WARNING% Directory "%LICENSED_PACKAGE_DIR_NAME%" exists but is not a git repository.
    echo %WARNING% Please remove it or ensure it's the correct repository.
    :: Optionally, to force re-clone:
    :: echo %INFO% Removing existing directory and re-cloning.
    :: rmdir /s /q "%LICENSED_PACKAGE_DIR_FULL_PATH%"
    :: git clone "%LICENSED_REPO_URL%" "%LICENSED_PACKAGE_DIR_NAME%"
    :: if errorlevel 1 (
    ::     echo %ERROR% Failed to clone licensed features repository from %LICENSED_REPO_URL%.
    ::     echo %ERROR% Please ensure you have access to the repository and SSH keys are set up if needed.
    ::     exit /b 1
    :: ) else (
    ::     echo %SUCCESS% Cloned licensed features repository successfully.
    :: )
) else (
    echo %INFO% Cloning licensed features from %LICENSED_REPO_URL% into %LICENSED_PACKAGE_DIR_NAME%...
    git clone "%LICENSED_REPO_URL%" "%LICENSED_PACKAGE_DIR_NAME%"
    if errorlevel 1 (
        echo %ERROR% Failed to clone licensed features repository from %LICENSED_REPO_URL%.
        echo %ERROR% Please ensure you have access to the repository and SSH keys are set up if needed.
        exit /b 1
    ) else (
        echo %SUCCESS% Cloned licensed features repository successfully.
    )
)

if not exist "build_configs\pubspec.full.yaml" (
    echo %ERROR% build_configs\pubspec.full.yaml not found!
    exit /b 1
)

copy "build_configs\pubspec.full.yaml" pubspec.yaml >nul

set "FULL_LOADER_SOURCE_PATH=%LICENSED_PACKAGE_DIR_FULL_PATH%\lib\licensed_features_loader_full.dart"
set "FULL_LOADER_DEST_PATH=lib\licensing\licensed_features_loader.dart"

if exist "%FULL_LOADER_SOURCE_PATH%" (
    if not exist "lib\licensing" mkdir "lib\licensing"
    copy "%FULL_LOADER_SOURCE_PATH%" "%FULL_LOADER_DEST_PATH%" >nul
    echo %INFO% Copied full loader from %LICENSED_PACKAGE_DIR_NAME%\lib\licensed_features_loader_full.dart
) else (
    echo %ERROR% Full loader not found at %FULL_LOADER_SOURCE_PATH%
    echo %ERROR% Licensed features may not work properly. Ensure the repository was cloned correctly and the file path is accurate.
    :: Optionally, exit here
    :: exit /b 1
)

echo %SUCCESS% ✅ Full version configuration applied
goto install_deps

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
    echo %INFO% Running build_runner...
    flutter packages pub run build_runner build --delete-conflicting-outputs
    if errorlevel 1 (
        echo %ERROR% Build runner failed.
        exit /b 1
    )
) else (
    echo %INFO% No build_runner detected in pubspec.yaml, skipping code generation.
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
echo   %~nx0 opensource
echo   %~nx0 full
echo   %~nx0 full true  (to also clean before setup)
echo.


endlocal
exit /b 0