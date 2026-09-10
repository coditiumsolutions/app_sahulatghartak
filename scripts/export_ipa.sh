#!/bin/bash
set -e

# Script: export_ipa.sh
# Purpose: Package a downloaded Runner.xcarchive into a deliverable .ipa file for Transporter.

TARGET_DIR="${1:-.}"
OUTPUT_IPA="SahulatGharTak.ipa"

# 1. Locate the .xcarchive folder
XCARCHIVE=$(find "$TARGET_DIR" -maxdepth 2 -name "*.xcarchive" | head -n 1)

if [ -z "$XCARCHIVE" ]; then
  echo "Error: No .xcarchive folder found in '$TARGET_DIR'."
  echo "Usage: ./scripts/export_ipa.sh [path_to_folder]"
  exit 1
fi

echo "Found Archive: $XCARCHIVE"

# 2. Locate the .app bundle inside the archive
APP_PATH=$(find "$XCARCHIVE/Products/Applications" -name "*.app" | head -n 1)

if [ -z "$APP_PATH" ]; then
  echo "Error: Could not find an .app bundle inside $XCARCHIVE/Products/Applications."
  exit 1
fi

echo "Found App Bundle: $APP_PATH"

# 3. Create temporary staging area and zip into .ipa
TEMP_STAGING=$(mktemp -d)
mkdir -p "$TEMP_STAGING/Payload"

echo "Copying app bundle to Payload..."
cp -R "$APP_PATH" "$TEMP_STAGING/Payload/"

echo "Zipping into $OUTPUT_IPA..."
(cd "$TEMP_STAGING" && zip -r -q "$OUTPUT_IPA" Payload)

# 4. Move output .ipa back to working directory and clean up
mv "$TEMP_STAGING/$OUTPUT_IPA" "$TARGET_DIR/"
rm -rf "$TEMP_STAGING"

echo "=========================================="
echo " SUCCESS: $OUTPUT_IPA generated at:"
echo " $(pwd)/$OUTPUT_IPA"
echo "=========================================="