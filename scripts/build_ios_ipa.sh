#!/bin/zsh
set -e # Stop script execution immediately if any command fails

flutter clean
flutter pub get
cd ios && pod install && cd ..

flutter build ipa --release

# Use --export-options-plist if you want Flutter to output the .ipa file directly
# flutter build ipa --release --export-options-plist=ios/ExportOptions.plist