@echo off
setlocal enabledelayedexpansion
title Build Release Packager

set WORKSPACE_DIR=%~dp0
cd /d "%WORKSPACE_DIR%"

:: 0. Kill running instances of the app
echo [0/5] Terminating any active app instances...
taskkill /IM ja_compare.exe /F 2>nul
timeout /t 1 /nobreak >nul

:: 1. Clear previous distribution folder
echo [1/5] Clearing previous dist/ folder...
if exist "dist" rmdir /s /q "dist"
mkdir "dist"

:: 2. Compile Windows Release App
echo [2/5] Compiling Windows application (Release mode)...
call flutter build windows --release
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set RELEASE_DIR=build\windows\x64\runner\Release

:: 3. Copy bin, assets, i18n, and docs to build output
echo [3/5] Bundling embedded binaries, assets, and docs...
if exist "bin" xcopy /e /i /y /q "bin" "%RELEASE_DIR%\bin\"
if exist "assets" xcopy /e /i /y /q "assets" "%RELEASE_DIR%\assets\"
if exist "i18n" xcopy /e /i /y /q "i18n" "%RELEASE_DIR%\i18n\"
if exist "ABOUT.txt" copy /y "ABOUT.txt" "%RELEASE_DIR%\" >nul
if exist "README.md" copy /y "README.md" "%RELEASE_DIR%\" >nul
if exist "LICENSE" copy /y "LICENSE" "%RELEASE_DIR%\" >nul

:: Create debug.bat for quick debugging (hardcoded exe name — the blueprint's
:: generic nested-for-loop one-liner is fragile to caret-escaping across batch
:: files; ja_compare.exe is fixed for this project, so skip the loop entirely).
(
echo @echo off
echo cd /d %%~dp0
echo start "" "ja_compare.exe" -debug
) > "%RELEASE_DIR%\debug.bat"

:: Create .Release shortcut in project root
powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%WORKSPACE_DIR%\.Release.lnk'); $s.TargetPath='%WORKSPACE_DIR%\%RELEASE_DIR%'; $s.Save()"

:: 4. Copy to dist/ and create x64 zip
echo [4/5] Copying complete self-contained release to dist/...
xcopy /e /i /y /q "%RELEASE_DIR%\*.*" "dist\"

echo [5/5] Packaging standalone Windows x64 ZIP release wrapped in parent folder...
if exist "dist_pack" rmdir /s /q "dist_pack"
mkdir "dist_pack\JA_Compare_v1.0.0_Windows_x64"
xcopy /e /i /y /q "dist\*.*" "dist_pack\JA_Compare_v1.0.0_Windows_x64\"
powershell -Command "Compress-Archive -Path 'dist_pack\*' -DestinationPath 'dist\JA_Compare_v1.0.0_Windows_x64.zip' -Force"
if exist "dist_pack" rmdir /s /q "dist_pack"

echo [SUCCESS] Release build ^& packaging complete in dist/
pause
