#!/bin/zsh
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release