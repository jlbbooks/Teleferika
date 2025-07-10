#!/usr/bin/env pwsh

# Generate documentation for Teleferika project using FVM
# This script uses dartdoc (via FVM) to generate API documentation
#
# Usage:
#   .\scripts\generate-docs.ps1 [opensource|full]
#   - opensource: Generate docs for main project only
#   - full: Generate docs for main project and licensed features package

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
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [opensource|full]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  opensource  Generate documentation for main project only"
    Write-Host "  full        Generate documentation for main project and licensed features package"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  $($MyInvocation.MyCommand.Name) opensource"
    Write-Host "  $($MyInvocation.MyCommand.Name) full"
    Write-Host ""
    Write-Host "If no parameter is provided, defaults to 'opensource'"
}

# Parse command line arguments
$FLAVOR = $args[0]
if (-not $FLAVOR) { $FLAVOR = "opensource" }

# Show help if requested
if ($FLAVOR -in @("-h", "--help", "help")) {
    Show-Usage
    exit 0
}

# Validate flavor
if ($FLAVOR -notin @("opensource", "full")) {
    Write-Error "Invalid flavor: $FLAVOR"
    Show-Usage
    exit 1
}

Write-Status "📚 Generating Teleferika Documentation (FVM) for $FLAVOR flavor..."

# Check if FVM is installed
try {
    $null = Get-Command fvm -ErrorAction Stop
} catch {
    Write-Error "FVM is not installed. Please install FVM (https://fvm.app/) and try again."
    exit 1
}

# Check if dartdoc is installed in the FVM environment
$dartdocCheck = fvm dart pub global list 2>&1 | Select-String "dartdoc"
if (-not $dartdocCheck) {
    Write-Status "dartdoc is not installed in FVM environment. Installing..."
    fvm dart pub global activate dartdoc
}

# Function to generate documentation for a project
function Generate-Docs {
    param(
        [string]$ProjectName,
        [string]$ProjectPath,
        [string]$OutputPath
    )
    
    Write-Status "Generating documentation for $ProjectName..."
    
    # Navigate to project directory
    $originalLocation = Get-Location
    Set-Location $ProjectPath
    
    try {
        # Clean previous documentation
        if (Test-Path $OutputPath) {
            Write-Status "Cleaning previous documentation..."
            Remove-Item $OutputPath -Recurse -Force
        }
        
        # Generate documentation using FVM-managed Dart
        $env:PATH = "$env:PATH;$env:USERPROFILE\.pub-cache\bin"
        Write-Status "Generating documentation with FVM..."
        
        $result = fvm dart pub global run dartdoc --output $OutputPath --include-source 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ Documentation generated successfully for $ProjectName!"
            Write-Status "📁 Documentation is available at: $OutputPath\index.html"
            return $true
        } else {
            Write-Error "❌ Documentation generation failed for $ProjectName!"
            return $false
        }
    } finally {
        Set-Location $originalLocation
    }
}

# Get the script directory and project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR

# Generate documentation for main project
Write-Status "Generating documentation for main Teleferika project..."
if (Generate-Docs "main project" $PROJECT_ROOT "doc\api") {
    Write-Success "✅ Main project documentation completed"
    
    # Fix viewport meta tag accessibility issues
    Write-Status "🔧 Fixing viewport meta tag accessibility issues..."
    $fixResult = & (Join-Path $SCRIPT_DIR "fix-docs-viewport.ps1") "doc\api" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Viewport meta tag fixes completed"
    } else {
        Write-Warning "⚠️ Viewport meta tag fixes failed (continuing...)"
    }
} else {
    Write-Error "❌ Main project documentation failed"
    exit 1
}

# Generate documentation for licensed features package if full flavor
if ($FLAVOR -eq "full") {
    Write-Status "Generating documentation for licensed features package..."
    
    # Check if licensed features package exists
    $licensedPackagePath = Join-Path $PROJECT_ROOT "licensed_features_package"
    if (Test-Path $licensedPackagePath) {
        if (Generate-Docs "licensed features package" $licensedPackagePath "doc\api") {
            Write-Success "✅ Licensed features package documentation completed"
            
            # Fix viewport meta tag accessibility issues for licensed features package
            Write-Status "🔧 Fixing viewport meta tag accessibility issues for licensed features package..."
            $fixResult = & (Join-Path $SCRIPT_DIR "fix-docs-viewport.ps1") (Join-Path $licensedPackagePath "doc\api") 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "✅ Licensed features package viewport meta tag fixes completed"
            } else {
                Write-Warning "⚠️ Licensed features package viewport meta tag fixes failed (continuing...)"
            }
        } else {
            Write-Warning "⚠️ Licensed features package documentation failed (continuing...)"
        }
    } else {
        Write-Warning "⚠️ Licensed features package directory not found, skipping..."
    }
}

# Open documentation in browser (optional)
Write-Status "Opening documentation in browser..."
$docPath = Join-Path $PROJECT_ROOT "doc\api\index.html"
try {
    Start-Process $docPath
} catch {
    Write-Warning "Could not automatically open browser. Please open: $docPath"
}

Write-Success "🎉 Documentation generation complete for $FLAVOR flavor!" 