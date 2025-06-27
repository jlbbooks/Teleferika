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
set "DEBUG=[DEBUG]"

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

:: Verify essential directories exist
if not exist "lib" (
    echo %ERROR% Required directory not found: lib
    exit /b 1
)
if not exist "lib\licensing" (
    echo %ERROR% Required directory not found: lib\licensing
    exit /b 1
)
if not exist "pubspec.yaml" (
    echo %ERROR% Required file not found: pubspec.yaml
    exit /b 1
)

:: Clean if requested
if /i "%CLEAN%"=="true" (
    echo %INFO% Cleaning previous build...
    flutter clean
    if exist .dart_tool rmdir /s /q .dart_tool
    if exist build rmdir /s /q build
    
    :: Clean up licensed features loader
    if exist "lib\licensing\licensed_features_loader.dart" (
        del "lib\licensing\licensed_features_loader.dart"
        echo %INFO% Removed existing licensed features loader
    )
    
    :: Optionally remove the licensed package directory
    if exist "%LICENSED_PACKAGE_DIR_FULL_PATH%" (
        echo %INFO% Removing licensed package directory...
        rmdir /s /q "%LICENSED_PACKAGE_DIR_FULL_PATH%"
    )
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

:: Verify required files exist
if not exist "lib\licensing\licensed_features_loader_stub.dart" (
    echo %ERROR% Required file not found: lib\licensing\licensed_features_loader_stub.dart
    exit /b 1
)

:: Remove licensed package dependency if present
if exist "scripts\modify-pubspec.bat" (
    call scripts\modify-pubspec.bat remove-licensed
) else (
    echo %WARNING% modify-pubspec.bat not found, manually removing licensed package dependency
)

:: Set up stub loader
copy "lib\licensing\licensed_features_loader_stub.dart" "lib\licensing\licensed_features_loader.dart" >nul
echo %SUCCESS% Copied stub loader

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
    echo %INFO% Removing existing directory and re-cloning...
    rmdir /s /q "%LICENSED_PACKAGE_DIR_FULL_PATH%"
    git clone "%LICENSED_REPO_URL%" "%LICENSED_PACKAGE_DIR_NAME%"
    if errorlevel 1 (
        echo %ERROR% Failed to clone licensed features repository from %LICENSED_REPO_URL%.
        echo %ERROR% Please ensure you have access to the repository and SSH keys are set up if needed.
        exit /b 1
    )
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

:: Verify the licensed package structure
if not exist "%LICENSED_PACKAGE_DIR_FULL_PATH%\lib" (
    echo %ERROR% Required directory not found: %LICENSED_PACKAGE_DIR_NAME%\lib
    exit /b 1
)
if not exist "%LICENSED_PACKAGE_DIR_FULL_PATH%\lib\licensed_features_loader_full.dart" (
    echo %ERROR% Required file not found: %LICENSED_PACKAGE_DIR_NAME%\lib\licensed_features_loader_full.dart
    exit /b 1
)
if not exist "%LICENSED_PACKAGE_DIR_FULL_PATH%\lib\licensed_plugin.dart" (
    echo %ERROR% Required file not found: %LICENSED_PACKAGE_DIR_NAME%\lib\licensed_plugin.dart
    exit /b 1
)

:: Add licensed package dependency
if exist "scripts\modify-pubspec.bat" (
    call scripts\modify-pubspec.bat add-licensed
) else (
    echo %WARNING% modify-pubspec.bat not found, manually adding licensed package dependency
)

:: Set up full loader
copy "%LICENSED_PACKAGE_DIR_FULL_PATH%\lib\licensed_features_loader_full.dart" "lib\licensing\licensed_features_loader.dart" >nul
echo %SUCCESS% Copied full loader

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
    ) else (
        echo %SUCCESS% ✅ Code generation completed
    )
) else (
    echo %INFO% No build_runner detected, skipping code generation
)

:: Verify setup
echo %INFO% Verifying setup...
flutter doctor >nul 2>&1
if errorlevel 1 (
    echo %WARNING% Flutter doctor reported issues, but continuing...
)

:: Verify the licensed features loader exists
if not exist "lib\licensing\licensed_features_loader.dart" (
    echo %ERROR% Licensed features loader not found after setup!
    exit /b 1
)

:: Show completion message
echo.
echo %SUCCESS% 🎉 Setup complete!
echo.
echo Current Configuration:
echo   Flavor: %FLAVOR%
echo   Licensed Features Loader: licensed_features_loader.dart

:: Count dependencies (simplified for Windows)
for /f %%i in ('findstr /c:"  " pubspec.yaml ^| find /c /v ""') do set DEP_COUNT=%%i
echo   Dependencies: %DEP_COUNT% packages (approx)

:: Show framework status
if /i "%FLAVOR%"=="full" (
    echo   Framework: Full version with licensed features
    if exist "%LICENSED_PACKAGE_DIR_FULL_PATH%" (
        echo   Licensed Package: Available
    ) else (
        echo   Licensed Package: Missing (setup may have failed)
    )
) else (
    echo   Framework: Opensource version
)

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
echo To test the setup, run:
echo   scripts\test-setup.sh

endlocal
exit /b 0