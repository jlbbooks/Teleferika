#!/usr/bin/env pwsh

# Colors for PowerShell output
$Colors = @{
    Info = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
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

# Function to show usage
function Show-Usage {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [COMMAND] [FLAVOR] [OPTIONS]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  build     Build the app"
    Write-Host "  run       Run the app"
    Write-Host "  clean     Clean build artifacts"
    Write-Host "  setup     Setup the specified flavor"
    Write-Host "  docs      Generate API documentation (opensource or full)"
    Write-Host ""
    Write-Host "Flavors:"
    Write-Host "  opensource  Open source version"
    Write-Host "  full        Full version with licensed features"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --mode MODE          Build mode (debug, release, profile)"
    Write-Host "  --type TYPE          Build type (apk, appbundle, ios)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  $($MyInvocation.MyCommand.Name) setup opensource"
    Write-Host "  $($MyInvocation.MyCommand.Name) build opensource --mode release --type apk"
    Write-Host "  $($MyInvocation.MyCommand.Name) run full --mode debug"
    Write-Host "  $($MyInvocation.MyCommand.Name) docs full"
    Write-Host "  $($MyInvocation.MyCommand.Name) clean"
}

# Default values
$COMMAND = ""
$FLAVOR = ""
$MODE = "debug"
$TYPE = "apk"

# Parse command line arguments
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        { $_ -in @("build", "run", "clean", "setup", "docs") } {
            $COMMAND = $args[$i]
            $i++
        }
        { $_ -in @("opensource", "full") } {
            $FLAVOR = $args[$i]
            $i++
        }
        "--mode" {
            if ($i + 1 -lt $args.Count) {
                $MODE = $args[$i + 1]
                $i += 2
            } else {
                Write-Error "Missing value for --mode"
                Show-Usage
                exit 1
            }
        }
        "--type" {
            if ($i + 1 -lt $args.Count) {
                $TYPE = $args[$i + 1]
                $i += 2
            } else {
                Write-Error "Missing value for --type"
                Show-Usage
                exit 1
            }
        }
        { $_ -in @("-h", "--help") } {
            Show-Usage
            exit 0
        }
        default {
            Write-Error "Unknown option: $($args[$i])"
            Show-Usage
            exit 1
        }
    }
}

# Validate command
if (-not $COMMAND) {
    Write-Error "No command specified"
    Show-Usage
    exit 1
}

# Handle clean command (doesn't need flavor)
if ($COMMAND -eq "clean") {
    Write-Status "Cleaning build artifacts..."
    flutter clean
    if (Test-Path "build") { Remove-Item "build" -Recurse -Force }
    if (Test-Path ".dart_tool") { Remove-Item ".dart_tool" -Recurse -Force }
    Write-Success "✅ Clean completed"
    exit 0
}

# Validate flavor for other commands
if (-not $FLAVOR) {
    Write-Error "No flavor specified"
    Show-Usage
    exit 1
}

# Validate flavor value
if ($FLAVOR -notin @("opensource", "full")) {
    Write-Error "Invalid flavor: $FLAVOR"
    Show-Usage
    exit 1
}

# Check if Flutter is installed
try {
    $null = Get-Command flutter -ErrorAction Stop
} catch {
    Write-Error "Flutter is not installed or not in PATH"
    exit 1
}

# Navigate to project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
Set-Location $PROJECT_ROOT

Write-Status "Project root: $PROJECT_ROOT"
Write-Status "Command: $COMMAND"
Write-Status "Flavor: $FLAVOR"

# Handle setup command
if ($COMMAND -eq "setup") {
    Write-Status "Setting up $FLAVOR flavor..."
    $result = & (Join-Path $SCRIPT_DIR "setup-flavor.ps1") $FLAVOR 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Setup completed for $FLAVOR"
    } else {
        Write-Error "❌ Setup failed for $FLAVOR"
        exit 1
    }
    exit 0
}

# Verify the app is set up for the specified flavor
if (-not (Test-Path "lib\licensing\licensed_features_loader.dart")) {
    Write-Error "App not set up. Run setup first: $($MyInvocation.MyCommand.Name) setup $FLAVOR"
    exit 1
}

# Verify the correct loader is in place
if ($FLAVOR -eq "opensource") {
    if (-not (Select-String -Path "lib\licensing\licensed_features_loader.dart" -Pattern "Licensed features not available" -Quiet)) {
        Write-Error "Wrong flavor setup. Run: $($MyInvocation.MyCommand.Name) setup opensource"
        exit 1
    }
} elseif ($FLAVOR -eq "full") {
    if (-not (Select-String -Path "lib\licensing\licensed_features_loader.dart" -Pattern "Licensed features registered successfully" -Quiet)) {
        Write-Error "Wrong flavor setup. Run: $($MyInvocation.MyCommand.Name) setup full"
        exit 1
    }
}

# Handle build command
if ($COMMAND -eq "build") {
    Write-Status "Building $FLAVOR flavor in $MODE mode..."
    
    switch ($TYPE) {
        "apk" {
            $result = flutter build apk --flavor $FLAVOR --$MODE 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ APK built successfully"
                Write-Status "APK location: build\app\outputs\flutter-apk\app-$FLAVOR-$MODE.apk"
            } else {
                Write-Error "❌ APK build failed"
                exit 1
            }
        }
        "appbundle" {
            $result = flutter build appbundle --flavor $FLAVOR --$MODE 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ App bundle built successfully"
                Write-Status "Bundle location: build\app\outputs\bundle\${FLAVOR}Release\app-$FLAVOR-release.aab"
            } else {
                Write-Error "❌ App bundle build failed"
                exit 1
            }
        }
        "ios" {
            $result = flutter build ios --flavor $FLAVOR --$MODE 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ iOS build completed"
            } else {
                Write-Error "❌ iOS build failed"
                exit 1
            }
        }
        default {
            Write-Error "Unknown build type: $TYPE"
            exit 1
        }
    }
}

# Handle run command
if ($COMMAND -eq "run") {
    Write-Status "Running $FLAVOR flavor in $MODE mode..."
    
    $result = flutter run --flavor $FLAVOR --$MODE 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ App started successfully"
    } else {
        Write-Error "❌ App failed to start"
        exit 1
    }
}

# Handle docs command
if ($COMMAND -eq "docs") {
    Write-Status "Generating documentation for $FLAVOR flavor..."
    if (-not $FLAVOR) {
        $FLAVOR = "opensource"
    }
    if ($FLAVOR -notin @("opensource", "full")) {
        Write-Error "Invalid flavor: $FLAVOR"
        Show-Usage
        exit 1
    }
    $result = & (Join-Path $SCRIPT_DIR "generate-docs.ps1") $FLAVOR 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Documentation generated for $FLAVOR flavor"
    } else {
        Write-Error "❌ Documentation generation failed for $FLAVOR flavor"
        exit 1
    }
    exit 0
}

Write-Success "🎉 Command completed successfully!" 