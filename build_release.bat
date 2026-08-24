@echo off
setlocal enabledelayedexpansion
title Build Release Packager

set WORKSPACE_DIR=%~dp0
cd /d "%WORKSPACE_DIR%"

:: Keep the package name tied to pubspec.yaml instead of a stale hardcoded tag.
for /f "tokens=2 delims=: " %%v in ('findstr /r /c:"^version:" pubspec.yaml') do set APP_VERSION=%%v
for /f "tokens=1 delims=+" %%v in ("!APP_VERSION!") do set APP_VERSION=%%v
if not defined APP_VERSION (
  echo [ERROR] Could not read version from pubspec.yaml
  exit /b 1
)

set "RELEASE_DIR=%WORKSPACE_DIR%build\windows\x64\runner\Release"
set "DIST_DIR=%WORKSPACE_DIR%dist"
set "STAGING_DIR=%WORKSPACE_DIR%dist_pack"
set "PACKAGE_NAME=JA_Compare_v!APP_VERSION!_Windows_x64"

:: 0. Kill running instances of the app
echo [0/5] Terminating any active app instances...
powershell -NoProfile -Command "Get-Process -Name 'ja_compare' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Start-Sleep -Milliseconds 500"

:: 1. Compile before touching previous distribution output.
echo [1/5] Compiling Windows application (Release mode)...
call flutter build windows --release
if errorlevel 1 (
  echo [ERROR] Flutter release build failed. Existing dist/ was preserved.
  exit /b 1
)

if not exist "%RELEASE_DIR%\ja_compare.exe" (
  echo [ERROR] Release executable was not produced.
  exit /b 1
)

:: 2. Copy bin, assets, i18n, and docs to build output
echo [2/5] Bundling embedded binaries, assets, and docs...
if exist "bin" xcopy /e /i /y /q "bin" "%RELEASE_DIR%\bin\"
if exist "assets" xcopy /e /i /y /q "assets" "%RELEASE_DIR%\assets\"
if exist "i18n" xcopy /e /i /y /q "i18n" "%RELEASE_DIR%\i18n\"
if exist "ABOUT.txt" copy /y "ABOUT.txt" "%RELEASE_DIR%\" >nul
if exist "README.md" copy /y "README.md" "%RELEASE_DIR%\" >nul
if exist "CHANGELOG.md" copy /y "CHANGELOG.md" "%RELEASE_DIR%\" >nul
if exist "RELEASE_NOTES.md" copy /y "RELEASE_NOTES.md" "%RELEASE_DIR%\" >nul
if exist "LICENSE" copy /y "LICENSE" "%RELEASE_DIR%\" >nul

:: Settings and history belong in %LOCALAPPDATA%\\JA Compare. Logs are
:: intentionally written beside the EXE and the fresh build starts without old logs.
for %%f in (config.ini config.json history.json) do if exist "%RELEASE_DIR%\%%f" del /q "%RELEASE_DIR%\%%f"
if exist "%RELEASE_DIR%\logs" powershell -NoProfile -Command "$p='%RELEASE_DIR%\logs'; if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force }"

:: Create debug.bat for quick debugging (hardcoded exe name — the blueprint's
:: generic nested-for-loop one-liner is fragile to caret-escaping across batch
:: files; ja_compare.exe is fixed for this project, so skip the loop entirely).
(
echo @echo off
echo cd /d %%~dp0
echo start "" "ja_compare.exe" -debug
) > "%RELEASE_DIR%\debug.bat"

:: Create .Release shortcut in project root
powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%WORKSPACE_DIR%\.Release.lnk'); $s.TargetPath='%RELEASE_DIR%'; $s.Save()"

:: 3. Backup old output only after the new build has succeeded.
echo [3/5] Moving previous distribution output to backup/...
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { $root=[IO.Path]::GetFullPath('%WORKSPACE_DIR%'); $backup=Join-Path $root 'backup'; New-Item -ItemType Directory -Force -Path $backup | Out-Null; $stamp=Get-Date -Format 'yyyyMMdd_HHmmss'; foreach($name in @('dist','dist_pack')) { $source=Join-Path $root $name; if(Test-Path -LiteralPath $source) { Move-Item -LiteralPath $source -Destination (Join-Path $backup ('{0}_{1}' -f $name,$stamp)) } } } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
  echo [ERROR] Could not backup previous distribution output.
  exit /b 1
)

:: 4. Copy to dist/ and create x64 zip
echo [4/5] Copying complete self-contained release to dist/...
mkdir "%DIST_DIR%" >nul 2>&1
xcopy /e /i /y /q "%RELEASE_DIR%\*" "%DIST_DIR%\" >nul
if errorlevel 2 exit /b 1

echo [5/5] Packaging standalone Windows x64 ZIP release wrapped in parent folder...
mkdir "%STAGING_DIR%\!PACKAGE_NAME!" >nul 2>&1
xcopy /e /i /y /q "%DIST_DIR%\*" "%STAGING_DIR%\!PACKAGE_NAME!\" >nul
if errorlevel 2 exit /b 1
powershell -NoProfile -Command "Compress-Archive -Path '%STAGING_DIR%\*' -DestinationPath '%DIST_DIR%\!PACKAGE_NAME!.zip' -Force"
if errorlevel 1 exit /b 1
powershell -NoProfile -Command "$root=[IO.Path]::GetFullPath('%WORKSPACE_DIR%'); $staging=Join-Path $root 'dist_pack'; if(Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }"

echo [SUCCESS] Release build ^& packaging complete in dist/
exit /b 0
