#!/usr/bin/env pwsh

# Modify pubspec.yaml to add/remove licensed_features_package dependency
# 
# Platform-specific considerations:
# - YAML files use forward slashes (/) for paths regardless of platform
# - This script maintains forward slashes in pubspec.yaml paths
# - Pattern matching is platform-agnostic for dependency detection

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
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [COMMAND]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  add-licensed     Add licensed_features_package dependency"
    Write-Host "  remove-licensed  Remove licensed_features_package dependency"
    Write-Host "  status          Show current status of licensed package in pubspec.yaml"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  $($MyInvocation.MyCommand.Name) add-licensed"
    Write-Host "  $($MyInvocation.MyCommand.Name) remove-licensed"
    Write-Host "  $($MyInvocation.MyCommand.Name) status"
}

# Function to add licensed package dependency
function Add-LicensedPackage {
    $pubspecFile = "pubspec.yaml"
    
    if (-not (Test-Path $pubspecFile)) {
        Write-Error "pubspec.yaml not found"
        return 1
    }
    
    # Check if already exists (use platform-agnostic pattern matching)
    if (Select-String -Path $pubspecFile -Pattern "licensed_features_package:" -Quiet) {
        Write-Warning "Licensed package dependency already exists"
        return 0
    }
    
    # Create temporary file
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    # Process the file line by line
    $content = Get-Content $pubspecFile -Encoding UTF8
    $newContent = @()
    $placeholderFound = $false
    
    foreach ($line in $content) {
        $newContent += $line
        
        # If we find the placeholder, replace it with the actual dependency
        # Use platform-agnostic path separator for YAML files (always forward slash)
        if ($line -match "LICENSED_PACKAGE_PLACEHOLDER") {
            $placeholderFound = $true
            $newContent += "  licensed_features_package:"
            $newContent += "    path: ./licensed_features_package"
            $newContent += ""
        }
    }
    
    # Check if placeholder was found
    if (-not $placeholderFound) {
        Write-Error "LICENSED_PACKAGE_PLACEHOLDER not found in pubspec.yaml"
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        return 1
    }
    
    # Write to temporary file first
    $newContent | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
    
    # Replace original file
    Move-Item $tempFile $pubspecFile -Force
    
    Write-Success "Added licensed_features_package dependency"
    return 0
}

# Function to remove licensed package dependency
function Remove-LicensedPackage {
    $pubspecFile = "pubspec.yaml"
    
    if (-not (Test-Path $pubspecFile)) {
        Write-Error "pubspec.yaml not found"
        return 1
    }
    
    # Check if exists (use platform-agnostic pattern matching)
    if (-not (Select-String -Path $pubspecFile -Pattern "licensed_features_package:" -Quiet)) {
        Write-Warning "Licensed package dependency not found"
        return 0
    }
    
    # Create temporary file
    $tempFile = [System.IO.Path]::GetTempFileName()
    $newContent = @()
    $skipNext = $false
    $dependencyFound = $false
    
    # Process the file line by line
    $content = Get-Content $pubspecFile -Encoding UTF8
    
    foreach ($line in $content) {
        # Skip the licensed_features_package line and its indented content
        if ($line -match "licensed_features_package:") {
            $skipNext = $true
            $dependencyFound = $true
            continue
        }
        
        # Skip indented lines after licensed_features_package
        if ($skipNext) {
            if ($line -match "^\s*[a-zA-Z]") {
                # Found a non-indented line, stop skipping
                $skipNext = $false
            } else {
                # Still indented, continue skipping
                continue
            }
        }
        
        $newContent += $line
    }
    
    # Check if dependency was actually found and removed
    if (-not $dependencyFound) {
        Write-Warning "Licensed package dependency not found in file content"
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        return 0
    }
    
    # Write to temporary file first
    $newContent | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
    
    # Replace original file
    Move-Item $tempFile $pubspecFile -Force
    
    Write-Success "Removed licensed_features_package dependency"
    return 0
}

# Function to show status
function Show-Status {
    $pubspecFile = "pubspec.yaml"
    
    if (-not (Test-Path $pubspecFile)) {
        Write-Error "pubspec.yaml not found"
        return 1
    }
    
    # Use platform-agnostic pattern matching
    if (Select-String -Path $pubspecFile -Pattern "licensed_features_package:" -Quiet) {
        Write-Success "Licensed package dependency is present"
        Write-Host "Current configuration:"
        Get-Content $pubspecFile -Encoding UTF8 | Select-String "licensed_features_package:" -Context 0,2
    } else {
        Write-Warning "Licensed package dependency is not present"
    }
    
    return 0
}

# Parse command line arguments
$command = $args[0]

switch ($command) {
    "add-licensed" {
        Add-LicensedPackage
    }
    "remove-licensed" {
        Remove-LicensedPackage
    }
    "status" {
        Show-Status
    }
    { $_ -in @("", "-h", "--help") } {
        Show-Usage
    }
    default {
        Write-Error "Unknown command: $command"
        Show-Usage
        exit 1
    }
} 