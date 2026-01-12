#!/usr/bin/env pwsh

# Fix viewport meta tag accessibility issue in generated documentation
# This script removes 'user-scalable=no' from viewport meta tags in HTML files
# to improve accessibility by allowing users to zoom the page

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
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [doc_path]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  doc_path    Path to documentation directory (default: doc\api)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  $($MyInvocation.MyCommand.Name)"
    Write-Host "  $($MyInvocation.MyCommand.Name) doc\api"
    Write-Host "  $($MyInvocation.MyCommand.Name) licensed_features_package\doc\api"
    Write-Host ""
    Write-Host "This script fixes viewport meta tag accessibility issues by removing"
    Write-Host "'user-scalable=no' from HTML files to allow users to zoom."
}

# Parse command line arguments
$DOC_PATH = $args[0]
if (-not $DOC_PATH) { $DOC_PATH = "doc\api" }

# Show help if requested
if ($DOC_PATH -in @("-h", "--help", "help")) {
    Show-Usage
    exit 0
}

# Check if documentation directory exists
if (-not (Test-Path $DOC_PATH -PathType Container)) {
    Write-Error "Documentation directory not found: $DOC_PATH"
    exit 1
}

Write-Status "🔧 Fixing viewport meta tag accessibility issues in $DOC_PATH..."

# Count HTML files
$htmlFiles = Get-ChildItem -Path $DOC_PATH -Filter "*.html" -Recurse
$htmlCount = $htmlFiles.Count
Write-Status "Found $htmlCount HTML files to process..."

# Find files that contain user-scalable=no
$filesToFix = Get-ChildItem -Path $DOC_PATH -Filter "*.html" -Recurse | Where-Object {
    (Get-Content $_.FullName -Raw) -match 'user-scalable=no'
}

if ($filesToFix) {
    $fixCount = $filesToFix.Count
    Write-Status "Found $fixCount files that need fixing..."
    
    # Process each file
    foreach ($file in $filesToFix) {
        Write-Status "Fixing: $($file.Name)"
        
        # Create backup
        $backupPath = "$($file.FullName).bak"
        Copy-Item $file.FullName $backupPath
        
        try {
            # Read file content
            $content = Get-Content $file.FullName -Raw
            
            # Apply the fix - replace viewport meta tags with user-scalable=no
            $fixedContent = $content -replace '<meta name="viewport" content="[^"]*user-scalable=no[^"]*"', '<meta name="viewport" content="width=device-width, initial-scale=1.0"'
            
            # Write the fixed content back
            $fixedContent | Out-File -FilePath $file.FullName -Encoding UTF8
            
            # Verify the fix
            $verifyContent = Get-Content $file.FullName -Raw
            if ($verifyContent -notmatch 'user-scalable=no') {
                Write-Success "✅ Fixed: $($file.Name)"
            } else {
                Write-Warning "⚠️ Could not fix: $($file.Name)"
                # Restore backup
                Move-Item $backupPath $file.FullName -Force
            }
        } catch {
            Write-Warning "⚠️ Error processing: $($file.Name)"
            # Restore backup if it exists
            if (Test-Path $backupPath) {
                Move-Item $backupPath $file.FullName -Force
            }
        }
    }
    
    Write-Success "🎉 Viewport meta tag fix complete!"
    Write-Status "Processed $fixCount files"
} else {
    Write-Status "ℹ️ No files found with user-scalable=no - all files are already accessible"
}

# Clean up backup files
Write-Status "🧹 Cleaning up backup files..."
$backupFiles = Get-ChildItem -Path $DOC_PATH -Filter "*.bak" -Recurse
if ($backupFiles) {
    $backupFiles | Remove-Item -Force
    Write-Success "✅ Backup files cleaned up"
} else {
    Write-Status "ℹ️ No backup files found to clean up"
}

Write-Status "📁 Documentation is now accessible and users can zoom the pages" 