# PowerShell Migration Guide

This document outlines the migration from batch files (.bat) to PowerShell scripts (.ps1) for Windows users.

## Overview

All Windows batch files have been replaced with equivalent PowerShell scripts that provide:
- Better error handling
- Colored output for better user experience
- More robust file operations
- Cross-platform compatibility considerations

## Scripts Migrated

| Original Batch File | New PowerShell Script | Purpose |
|-------------------|---------------------|---------|
| `setup-flavor.bat` | `setup-flavor.ps1` | Main setup script for configuring project flavors |
| `modify-pubspec.bat` | `modify-pubspec.ps1` | Manage licensed package dependencies |
| `setup-opensource.bat` | `setup-opensource.ps1` | Quick setup for opensource flavor |
| `setup-full.bat` | `setup-full.ps1` | Quick setup for full flavor |
| N/A | `build-app.ps1` | Comprehensive build script (new) |
| N/A | `generate-docs.ps1` | Documentation generation (new) |
| N/A | `fix-docs-viewport.ps1` | Fix viewport accessibility (new) |
| N/A | `test-setup.ps1` | Test setup process (new) |

## Usage

### Basic Usage

All PowerShell scripts follow the same command-line interface as their shell script counterparts:

```powershell
# Setup flavors
.\scripts\setup-flavor.ps1 opensource
.\scripts\setup-flavor.ps1 full
.\scripts\setup-flavor.ps1 full true  # Clean setup

# Manage dependencies
.\scripts\modify-pubspec.ps1 add-licensed
.\scripts\modify-pubspec.ps1 remove-licensed
.\scripts\modify-pubspec.ps1 status

# Build and run
.\scripts\build-app.ps1 setup opensource
.\scripts\build-app.ps1 build opensource --mode release --type apk
.\scripts\build-app.ps1 run full --mode debug
.\scripts\build-app.ps1 docs full

# Documentation
.\scripts\generate-docs.ps1 opensource
.\scripts\generate-docs.ps1 full
.\scripts\fix-docs-viewport.ps1

# Testing
.\scripts\test-setup.ps1
```

**Note**: Always use `.\` prefix when running scripts from the current directory to avoid PowerShell command precedence issues.

### Execution Policy

If you encounter execution policy issues, you can:

1. **Set execution policy for current user:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Run with bypass for specific scripts:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\setup-flavor.ps1 opensource
   ```

3. **Run from PowerShell ISE or VS Code terminal** (usually has relaxed policies)

## Features

### Colored Output

All PowerShell scripts provide colored output for better readability:
- **Cyan**: Information messages
- **Green**: Success messages
- **Yellow**: Warning messages
- **Red**: Error messages

### Error Handling

PowerShell scripts include comprehensive error handling:
- File existence checks
- Command availability verification
- Graceful failure with helpful error messages
- Automatic cleanup on errors

### Cross-Platform Compatibility

While designed for Windows, the PowerShell scripts use:
- Cross-platform path separators where possible
- Environment variable handling
- Portable file operations
- Platform-agnostic YAML path handling (forward slashes in pubspec.yaml)

## Migration Benefits

1. **Better Error Messages**: More descriptive error messages with context
2. **Colored Output**: Easier to read and understand script output
3. **Robust File Operations**: Better handling of file operations and edge cases
4. **Modern Scripting**: PowerShell is the modern Windows scripting solution
5. **Consistent Interface**: Same command-line interface as shell scripts
6. **Platform-Agnostic YAML Handling**: Proper handling of forward slashes in pubspec.yaml

## Troubleshooting

### Common Issues

1. **"Execution policy prevents running scripts"**
   - Solution: Set execution policy or use bypass method above

2. **"Script not found"**
   - Ensure you're running from the project root directory
   - Use relative paths: `.\scripts\script-name.ps1`

3. **"Permission denied"**
   - Run PowerShell as Administrator if needed
   - Check file permissions

4. **"Flutter not found"**
   - Ensure Flutter is in your PATH
   - Use FVM: `fvm flutter` instead of `flutter`

### Getting Help

All scripts support help commands:
```powershell
.\scripts\setup-flavor.ps1 -h
.\scripts\build-app.ps1 --help
.\scripts\generate-docs.ps1 help
```

**Important**: Always use `.\` prefix when running scripts to avoid PowerShell command precedence warnings.

## Future Development

The PowerShell scripts are designed to be:
- **Maintainable**: Clear structure and comments
- **Extensible**: Easy to add new features
- **Consistent**: Follow PowerShell best practices
- **Documented**: Comprehensive help and usage information

## Comparison with Shell Scripts

| Feature | Shell Scripts | PowerShell Scripts |
|---------|---------------|-------------------|
| Platform | Linux/macOS | Windows |
| Error Handling | Basic | Comprehensive |
| Output Formatting | ANSI colors | PowerShell colors |
| File Operations | Unix commands | PowerShell cmdlets |
| Error Messages | Standard | Contextual |
| Help System | Manual | Built-in |

Both script types provide the same functionality with platform-appropriate implementations. 