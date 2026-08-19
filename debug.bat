@echo off
cd /d %~dp0
echo [INFO] Running JA Compare in DEBUG mode (verbose logging to logs\debug_*.log)...
flutter run -d windows --debug
