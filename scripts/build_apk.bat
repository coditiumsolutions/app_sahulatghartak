@echo off
where flutter >nul 2>nul || set PATH=D:\flutter\bin;%PATH%
cd /d "%~dp0.."
flutter build apk --release
