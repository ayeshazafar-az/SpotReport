@echo off
echo ================================================
echo  SpotClear - Flutter Web Runner
echo ================================================
cd /d "c:\Users\Ayesha Zafar\Desktop\spot_report"
echo Running flutter pub get...
flutter pub get
echo.
echo Starting app on Chrome...
flutter run --dart-define-from-file=env.json -d chrome
pause
