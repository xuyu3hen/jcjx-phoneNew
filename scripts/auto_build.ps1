# PowerShell Auto Build Script
# Usage: .\scripts\auto_build.ps1 [env] [version_type]
# Example: .\scripts\auto_build.ps1 release patch

param(
    [string]$env = "release",
    [string]$versionType = "patch"
)

# Validate environment parameter
if ($env -notin @("dev", "test", "release")) {
    Write-Host "Error: Invalid environment parameter '$env'" -ForegroundColor Red
    Write-Host "Available environments: dev, test, release" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Build Script (Local Build)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Environment: $env"
Write-Host "Version Type: $versionType"
Write-Host ""

# Set environment variables
$flavor = switch ($env) {
    "dev" { "env_dev"; break }
    "test" { "env_test"; break }
    "release" { "env_release"; break }
}

$mainFile = switch ($env) {
    "dev" { "lib/main_env_dev.dart"; break }
    "test" { "lib/main_env_test.dart"; break }
    "release" { "lib/main_env_release.dart"; break }
}

# Step 1: Update version
Write-Host "[1/4] Updating version..." -ForegroundColor Yellow
& dart scripts\bump_version.dart $versionType
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Version update failed" -ForegroundColor Red
    exit 1
}

# Read new version
$pubspecContent = Get-Content "pubspec.yaml" -Raw -Encoding UTF8
$versionMatch = [regex]::Match($pubspecContent, 'version:\s*([\d.]+)\+(\d+)')
if (-not $versionMatch.Success) {
    Write-Host "Error: Cannot read version number" -ForegroundColor Red
    exit 1
}

$newVersion = $versionMatch.Groups[0].Value -replace 'version:\s*', ''
$versionName = $versionMatch.Groups[1].Value
$buildNumber = $versionMatch.Groups[2].Value

Write-Host "Version updated: $newVersion (Version: $versionName, Build: $buildNumber)" -ForegroundColor Green
Write-Host ""

# Step 2: Clean and get dependencies
Write-Host "[2/4] Cleaning and getting dependencies..." -ForegroundColor Yellow
& flutter clean | Out-Null
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies retrieved" -ForegroundColor Green
Write-Host ""

# Step 3: Build APK
Write-Host "[3/4] Building APK..." -ForegroundColor Yellow
& flutter build apk --flavor $flavor -t $mainFile --target-platform android-arm,android-arm64 --no-tree-shake-icons --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: APK build failed" -ForegroundColor Red
    exit 1
}

# Determine output file path
$apkFile = "build\app\outputs\flutter-apk\app-$flavor-release.apk"
if (-not (Test-Path $apkFile)) {
    Write-Host "Error: Cannot find built APK file: $apkFile" -ForegroundColor Red
    exit 1
}

# Generate versioned filename
$apkName = "jcjx-phone-$versionName-build$buildNumber-$env.apk"
$apkNewPath = "build\app\outputs\flutter-apk\$apkName"

Copy-Item $apkFile $apkNewPath -Force | Out-Null
Write-Host "APK build completed: $apkNewPath" -ForegroundColor Green
Write-Host ""

# Step 4: Complete
Write-Host "[4/4] Build completed!" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Build Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "APK File: $apkNewPath" -ForegroundColor Green
Write-Host "Version: $newVersion"
Write-Host "Environment: $env"
Write-Host ""
Write-Host "Note:" -ForegroundColor Yellow
Write-Host "  - APK file generated, ready for testing or upload"
Write-Host "  - Version updated but NOT committed to Git (local build)"
Write-Host "  - To commit version, run: git add pubspec.yaml; git commit -m 'chore: build version $newVersion'"
