@echo off
echo ====================================
echo   Refreshing Android Studio Setup
echo ====================================
echo.

echo [1/6] Running flutter pub get...
flutter pub get

echo.
echo [2/6] Running flutter packages get...
flutter packages get

echo.
echo [3/6] Generating files...
flutter packages pub run build_runner build --delete-conflicting-outputs 2>nul

echo.
echo [4/6] Refreshing Dart packages...
dart pub get

echo.
echo [5/6] Checking Flutter doctor...
flutter doctor

echo.
echo [6/6] Project structure verification...
echo Checking new modules directory...
if exist "lib\modules\auth\screens\login_screen.dart" (
    echo ✅ New login screen found
) else (
    echo ❌ New login screen not found
)

if exist "lib\modules\auth\providers\auth_provider.dart" (
    echo ✅ Auth provider found
) else (
    echo ❌ Auth provider not found
)

if exist "lib\modules\auth\models\auth_user_model.dart" (
    echo ✅ Auth models found
) else (
    echo ❌ Auth models not found
)

echo.
echo ====================================
echo       Android Studio Instructions
echo ====================================
echo.
echo Please follow these steps in Android Studio:
echo.
echo 1. File ^> Invalidate Caches and Restart...
echo    ^> Choose "Invalidate and Restart"
echo.
echo 2. File ^> Sync Project with Gradle Files
echo.
echo 3. Build ^> Clean Project
echo.
echo 4. Build ^> Rebuild Project
echo.
echo 5. In the Project panel, right-click on 'lib' folder
echo    ^> Choose "Reload from Disk"
echo.
echo 6. Go to Tools ^> Flutter ^> Flutter Pub Get
echo.
echo 7. If you see any import errors, press Ctrl+Shift+O
echo    to optimize imports
echo.
echo ====================================
echo   Project is ready for Android Studio!
echo ====================================

pause
