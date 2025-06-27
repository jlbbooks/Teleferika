@echo off
setlocal EnableDelayedExpansion

:: Colors for Windows (limited, using prefixes)
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

:: Function to show usage
:show_usage
echo Usage: %~nx0 [COMMAND]
echo.
echo Commands:
echo   add-licensed     Add licensed_features_package dependency
echo   remove-licensed  Remove licensed_features_package dependency
echo   status          Show current status of licensed package in pubspec.yaml
echo.
echo Examples:
echo   %~nx0 add-licensed
echo   %~nx0 remove-licensed
echo   %~nx0 status
goto :eof

:: Function to add licensed package dependency
:add_licensed_package
set "pubspec_file=pubspec.yaml"

if not exist "%pubspec_file%" (
    echo %ERROR% pubspec.yaml not found
    exit /b 1
)

:: Check if already exists
findstr /c:"licensed_features_package:" "%pubspec_file%" >nul 2>&1
if not errorlevel 1 (
    echo %WARNING% Licensed package dependency already exists
    exit /b 0
)

:: Create temporary file
set "temp_file=%TEMP%\pubspec_temp_%RANDOM%.yaml"

:: Process the file line by line
for /f "usebackq delims=" %%i in ("%pubspec_file%") do (
    set "line=%%i"
    echo !line!>> "%temp_file%"
    
    :: If we find the placeholder, replace it with the actual dependency
    echo !line! | findstr /c:"LICENSED_PACKAGE_PLACEHOLDER" >nul 2>&1
    if not errorlevel 1 (
        echo   licensed_features_package:>> "%temp_file%"
        echo     path: ./licensed_features_package>> "%temp_file%"
        echo.>> "%temp_file%"
    )
)

:: Replace original file
move /y "%temp_file%" "%pubspec_file%" >nul 2>&1

echo %SUCCESS% Added licensed_features_package dependency
exit /b 0

:: Function to remove licensed package dependency
:remove_licensed_package
set "pubspec_file=pubspec.yaml"

if not exist "%pubspec_file%" (
    echo %ERROR% pubspec.yaml not found
    exit /b 1
)

:: Check if exists
findstr /c:"licensed_features_package:" "%pubspec_file%" >nul 2>&1
if errorlevel 1 (
    echo %WARNING% Licensed package dependency not found
    exit /b 0
)

:: Create temporary file
set "temp_file=%TEMP%\pubspec_temp_%RANDOM%.yaml"
set "skip_next=false"

:: Process the file line by line
for /f "usebackq delims=" %%i in ("%pubspec_file%") do (
    set "line=%%i"
    
    :: Skip the licensed_features_package line and its indented content
    echo !line! | findstr /c:"licensed_features_package:" >nul 2>&1
    if not errorlevel 1 (
        set "skip_next=true"
        goto :continue_loop
    )
    
    :: Skip indented lines after licensed_features_package
    if "!skip_next!"=="true" (
        :: Check if line starts with non-whitespace character
        for /f "tokens=1* delims= " %%a in ("!line!") do (
            if not "%%a"=="" (
                :: Found a non-indented line, stop skipping
                set "skip_next=false"
            ) else (
                :: Still indented, continue skipping
                goto :continue_loop
            )
        )
    )
    
    echo !line!>> "%temp_file%"
    
    :continue_loop
)

:: Replace original file
move /y "%temp_file%" "%pubspec_file%" >nul 2>&1

echo %SUCCESS% Removed licensed_features_package dependency
exit /b 0

:: Function to show status
:show_status
set "pubspec_file=pubspec.yaml"

if not exist "%pubspec_file%" (
    echo %ERROR% pubspec.yaml not found
    exit /b 1
)

findstr /c:"licensed_features_package:" "%pubspec_file%" >nul 2>&1
if not errorlevel 1 (
    echo %SUCCESS% Licensed package dependency is present
    echo Current configuration:
    findstr /c:"licensed_features_package:" "%pubspec_file%" /n
) else (
    echo %WARNING% Licensed package dependency is not present
)

exit /b 0

:: Parse command line arguments
set "command=%~1"

if "%command%"=="add-licensed" goto add_licensed_package
if "%command%"=="remove-licensed" goto remove_licensed_package
if "%command%"=="status" goto show_status
if "%command%"=="" goto show_usage
if "%command%"=="-h" goto show_usage
if "%command%"=="--help" goto show_usage

echo %ERROR% Unknown command: %command%
goto show_usage 