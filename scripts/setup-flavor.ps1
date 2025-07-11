#!/usr/bin/env pwsh

# --- Configuration ---
$LICENSED_REPO_URL = "git@github.com:jlbbooks/teleferika_licenced_packages.git"
$LICENSED_PACKAGE_DIR_NAME = "licensed_features_package"
# --- End Configuration ---

# Colors for PowerShell output
$Colors = @{
    Info = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Debug = "Magenta"
}

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Info
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Error
}

function Write-Debug {
    param([string]$Message)
    Write-Host "[DEBUG] $Message" -ForegroundColor $Colors.Debug
}

# Function to verify file exists
function Test-File {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Error "Required file not found: $Path"
        return $false
    }
    return $true
}

# Function to verify directory exists
function Test-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Container)) {
        Write-Error "Required directory not found: $Path"
        return $false
    }
    return $true
}

# Parse command line arguments
$FLAVOR = $args[0]
$CLEAN = $args[1]

if (-not $FLAVOR) { $FLAVOR = "opensource" }
if (-not $CLEAN) { $CLEAN = "false" }

Write-Status "Setting up Flutter app for $FLAVOR flavor..."

# Check if Flutter is installed
try {
    $null = Get-Command flutter -ErrorAction Stop
} catch {
    Write-Error "Flutter is not installed or not in PATH"
    Write-Status "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
}

# Check if Git is installed
try {
    $null = Get-Command git -ErrorAction Stop
} catch {
    Write-Error "Git is not installed or not in PATH."
    Write-Status "Please install Git: https://git-scm.com/downloads"
    exit 1
}

# Navigate to project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
Set-Location $PROJECT_ROOT

Write-Status "Project root: $PROJECT_ROOT"
$LICENSED_PACKAGE_DIR_FULL_PATH = Join-Path $PROJECT_ROOT $LICENSED_PACKAGE_DIR_NAME

# Verify essential directories exist
if (-not (Test-Directory "lib")) { exit 1 }
if (-not (Test-Directory "lib\licensing")) { exit 1 }
if (-not (Test-File "pubspec.yaml")) { exit 1 }

# Clean if requested
if ($CLEAN -eq "true") {
    Write-Status "Cleaning previous build..."
    flutter clean
    if (Test-Path ".dart_tool") { Remove-Item ".dart_tool" -Recurse -Force }
    if (Test-Path "build") { Remove-Item "build" -Recurse -Force }
    
    # Clean up licensed features loader
    if (Test-Path "lib\licensing\licensed_features_loader.dart") {
        Remove-Item "lib\licensing\licensed_features_loader.dart"
        Write-Status "Removed existing licensed features loader"
    }
    
    # Optionally remove the licensed package directory
    if (Test-Path $LICENSED_PACKAGE_DIR_FULL_PATH) {
        Write-Status "Removing licensed package directory..."
        Remove-Item $LICENSED_PACKAGE_DIR_FULL_PATH -Recurse -Force
    }
}

# Configure based on flavor
switch ($FLAVOR.ToLower()) {
    { $_ -in @("opensource", "open", "free") } {
        $FLAVOR = "opensource"
        Write-Status "🆓 Configuring for Open Source version..."

        # Verify required files exist
        if (-not (Test-File "lib\licensing\licensed_features_loader_stub.dart")) { exit 1 }

        # Remove licensed package dependency if present
        $modifyScriptPath = Join-Path $SCRIPT_DIR "modify-pubspec.ps1"
        if (Test-Path $modifyScriptPath) {
            & $modifyScriptPath "remove-licensed"
        } else {
            Write-Warning "modify-pubspec.ps1 not found, manually removing licensed package dependency"
        }

        # Set up stub loader
        Copy-Item "lib\licensing\licensed_features_loader_stub.dart" "lib\licensing\licensed_features_loader.dart"
        Write-Success "Copied stub loader"
        
        Write-Success "✅ Open Source configuration applied"
    }
    
    { $_ -in @("full", "premium", "licensed") } {
        $FLAVOR = "full"
        Write-Status "⭐ Configuring for Full version with licensed features..."

        # Clone or update the licensed features repository
        if (Test-Path (Join-Path $LICENSED_PACKAGE_DIR_FULL_PATH ".git")) {
            Write-Status "Licensed features repository already exists. Attempting to pull latest changes..."
            Set-Location $LICENSED_PACKAGE_DIR_FULL_PATH
            $gitResult = git pull 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Pulled latest changes for licensed features."
            } else {
                Write-Warning "Failed to pull latest changes for licensed features. Using existing version."
            }
            Set-Location $PROJECT_ROOT
        } elseif (Test-Path $LICENSED_PACKAGE_DIR_FULL_PATH) {
            Write-Warning "Directory '$LICENSED_PACKAGE_DIR_NAME' exists but is not a git repository."
            Write-Status "Removing existing directory and re-cloning..."
            Remove-Item $LICENSED_PACKAGE_DIR_FULL_PATH -Recurse -Force
            $gitResult = git clone $LICENSED_REPO_URL $LICENSED_PACKAGE_DIR_NAME 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to clone licensed features repository from $LICENSED_REPO_URL."
                Write-Error "Please ensure you have access to the repository and SSH keys are set up if needed."
                exit 1
            }
        } else {
            Write-Status "Cloning licensed features from $LICENSED_REPO_URL into $LICENSED_PACKAGE_DIR_NAME..."
            $gitResult = git clone $LICENSED_REPO_URL $LICENSED_PACKAGE_DIR_NAME 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to clone licensed features repository from $LICENSED_REPO_URL."
                Write-Error "Please ensure you have access to the repository and SSH keys are set up if needed."
                exit 1
            } else {
                Write-Success "Cloned licensed features repository successfully."
            }
        }

        # Verify the licensed package structure
        if (-not (Test-Directory (Join-Path $LICENSED_PACKAGE_DIR_FULL_PATH "lib"))) { exit 1 }
        if (-not (Test-File (Join-Path $LICENSED_PACKAGE_DIR_FULL_PATH "lib\licensed_features_loader_full.dart"))) { exit 1 }
        if (-not (Test-File (Join-Path $LICENSED_PACKAGE_DIR_FULL_PATH "lib\licensed_plugin.dart"))) { exit 1 }

        # Add licensed package dependency
        $modifyScriptPath = Join-Path $SCRIPT_DIR "modify-pubspec.ps1"
        if (Test-Path $modifyScriptPath) {
            & $modifyScriptPath "add-licensed"
        } else {
            Write-Warning "modify-pubspec.ps1 not found, manually adding licensed package dependency"
        }

        # Set up full loader
        Copy-Item (Join-Path $LICENSED_PACKAGE_DIR_FULL_PATH "lib\licensed_features_loader_full.dart") "lib\licensing\licensed_features_loader.dart"
        Write-Success "Copied full loader"

        Write-Success "✅ Full version configuration applied"
    }
    
    default {
        Write-Error "Unknown flavor: $FLAVOR"
        Write-Status "Available flavors: opensource, full"
        exit 1
    }
}

# Get dependencies
Write-Status "Getting Flutter dependencies..."
$flutterResult = flutter pub get 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "✅ Dependencies installed successfully"
} else {
    Write-Error "Failed to get dependencies"
    exit 1
}

# Generate any necessary files
Write-Status "Generating code if needed..."
if (Select-String -Path "pubspec.yaml" -Pattern "build_runner" -Quiet) {
    Write-Status "Running build_runner..."
    $buildResult = dart run build_runner build --delete-conflicting-outputs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Code generation completed"
    } else {
        Write-Error "Build runner failed."
        exit 1
    }
} else {
    Write-Status "No build_runner detected, skipping code generation"
}

# Verify setup
Write-Status "Verifying setup..."
$doctorResult = flutter doctor 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Flutter doctor reported issues, but continuing..."
}

# Verify the licensed features loader exists
if (-not (Test-File "lib\licensing\licensed_features_loader.dart")) {
    Write-Error "Licensed features loader not found after setup!"
    exit 1
}

# Show current configuration
Write-Success "🎉 Setup complete!"
Write-Host ""
Write-Host "Current Configuration:"
Write-Host "  Flavor: $FLAVOR"
Write-Host "  Licensed Features Loader: $(Split-Path -Leaf 'lib\licensing\licensed_features_loader.dart')"

# Count dependencies
$depCount = (Get-Content "pubspec.yaml" | Where-Object { $_ -match '^\s*[a-zA-Z]' -and $_ -notmatch '^#' -and $_ -notmatch '^$' } | Measure-Object).Count
Write-Host "  Dependencies: $depCount packages (approx)"

# Show framework status
if ($FLAVOR -eq "full") {
    Write-Host "  Framework: Full version with licensed features"
    if (Test-Path $LICENSED_PACKAGE_DIR_FULL_PATH) {
        Write-Host "  Licensed Package: Available"
    } else {
        Write-Host "  Licensed Package: Missing (setup may have failed)"
    }
} else {
    Write-Host "  Framework: Opensource version"
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open/Restart your IDE (Android Studio, VS Code, etc.)"
Write-Host "  2. Run the app normally (F5 in VS Code, or Run button in Android Studio)"
Write-Host "  3. The app will launch with $FLAVOR features"
Write-Host ""
Write-Host "To switch flavors, run:"
Write-Host "  .\scripts\setup-flavor.ps1 opensource"
Write-Host "  .\scripts\setup-flavor.ps1 full"
Write-Host "  .\scripts\setup-flavor.ps1 full true  (to also clean before setup)"
Write-Host ""
Write-Host "To test the setup, run:"
Write-Host "  .\scripts\test-setup.ps1" 