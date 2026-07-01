@echo off
setlocal enabledelayedexpansion

@REM SET ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
SET GRADLE_USER_HOME=D:\.gradle
SET ANDROID_HOME=D:\Android\Sdk
SET ANDROID_SDK_ROOT=%ANDROID_HOME%
SET ANDROID_PLATFORM_TOOLS=%ANDROID_HOME%\platform-tools

for /f "tokens=2" %%a in ('findstr /b "version:" pubspec.yaml') do set APP_VERSION=%%a
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
set SYMBOLS_PATH=build\app\outputs\symbols

echo.
echo ========================================
echo TLU Calendar Release Build
echo ========================================
echo Version: !APP_VERSION!
echo Target : Android APK
echo Mode   : release, obfuscated
echo.

flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

if errorlevel 1 (
  echo.
  echo Release build failed.
  exit /b 1
)

echo.
echo Release build completed.
echo APK    : !APK_PATH!
echo Symbols: !SYMBOLS_PATH!

where certutil >nul 2>nul
if not errorlevel 1 (
  echo.
  echo SHA-256:
  certutil -hashfile "!APK_PATH!" SHA256
)

echo.
echo Attach the APK and keep symbols for crash deobfuscation.
