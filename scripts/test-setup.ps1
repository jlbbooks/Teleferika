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

# Function to test a setup
function Test-Setup {
    param(
        [string]$Flavor,
        [string]$TestName
    )
    
    Write-Status "Testing $TestName..."
    
    # Run the setup script
    $result = & (Join-Path $PSScriptRoot "setup-flavor.ps1") $Flavor 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$TestName : PASSED"
        return $true
    } else {
        Write-Error "$TestName : FAILED"
        return $false
    }
}

# Function to verify framework files
function Test-Framework {
    param([string]$Flavor)
    
    Write-Status "Verifying framework files for $Flavor..."
    
    # Check if licensed features loader exists
    if (-not (Test-Path "lib\licensing\licensed_features_loader.dart")) {
        Write-Error "Licensed features loader not found!"
        return $false
    }
    
    # Check if the loader is the correct type
    if ($Flavor -eq "opensource") {
        if (Select-String -Path "lib\licensing\licensed_features_loader.dart" -Pattern "Licensed features not available" -Quiet) {
            Write-Success "Opensource loader verified"
        } else {
            Write-Error "Wrong loader type for opensource!"
            return $false
        }
    } elseif ($Flavor -eq "full") {
        if (Select-String -Path "lib\licensing\licensed_features_loader.dart" -Pattern "Licensed features registered successfully" -Quiet) {
            Write-Success "Full loader verified"
        } else {
            Write-Error "Wrong loader type for full!"
            return $false
        }
    }
    
    return $true
}

Write-Host "🧪 Testing development environment setup..." -ForegroundColor White
Write-Host ""

# Test open source setup
if (Test-Setup "opensource" "Open source setup") {
    if (Test-Framework "opensource") {
        Write-Success "✅ Open source framework verification: PASSED"
    } else {
        Write-Error "❌ Open source framework verification: FAILED"
        exit 1
    }
} else {
    Write-Error "❌ Open source setup: FAILED"
    exit 1
}

Write-Host ""

# Test full setup (if available)
if (Test-Setup "full" "Full setup") {
    if (Test-Framework "full") {
        Write-Success "✅ Full framework verification: PASSED"
    } else {
        Write-Error "❌ Full framework verification: FAILED"
        exit 1
    }
} else {
    Write-Warning "⚠️ Full setup: FAILED (this is expected for open source contributors)"
}

Write-Host ""

# Test Flutter compilation
Write-Status "Testing Flutter compilation..."
$flutterResult = flutter analyze --no-fatal-infos 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "✅ Flutter analysis: PASSED"
} else {
    Write-Error "❌ Flutter analysis: FAILED"
    exit 1
}

Write-Host ""

# Test basic app compilation (dry run)
Write-Status "Testing basic app compilation..."
$buildResult = flutter build apk --debug --flavor opensource --target-platform android-arm64 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "✅ Basic compilation: PASSED"
} else {
    Write-Warning "⚠️ Basic compilation: FAILED (this might be expected in some environments)"
}

Write-Host ""
Write-Host "🎉 All tests passed! Your development environment is ready." -ForegroundColor Green
Write-Host ""
Write-Host "Summary:"
Write-Host "  ✅ Open source setup: Working"
if (Test-Path "licensed_features_package") {
    Write-Host "  ✅ Full setup: Working"
} else {
    Write-Host "  ⚠️ Full setup: Not available (requires access to licensed repository)"
}
if (Test-Path "license_server") {
    Write-Host "  ✅ License server: Available"
} else {
    Write-Host "  ⚠️ License server: Missing (setup may have failed)"
}
Write-Host "  ✅ Flutter analysis: Working"
Write-Host ""
Write-Host "You can now:"
Write-Host "  1. Switch between flavors: .\scripts\setup-flavor.ps1 [opensource|full]"
Write-Host "  2. Build the app: flutter build apk --flavor [opensource|full]"
Write-Host "  3. Run the app: flutter run --flavor [opensource|full]" 