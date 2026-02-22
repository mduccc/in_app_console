#!/usr/bin/env bash

# Script to bump the version of in_app_console and update it in all packages

if [ -z "$1" ]; then
  echo "Usage: ./bump_version.sh <new_version>"
  echo "Example: ./bump_version.sh 3.0.0"
  exit 1
fi

NEW_VERSION=$1
ROOT_DIR=$(pwd)
PACKAGES_DIR="$ROOT_DIR/packages"

echo "Bumping in_app_console version to $NEW_VERSION..."


# 2. Update the in_app_console dependency in all packages
if [ -d "$PACKAGES_DIR" ]; then
  for dir in "$PACKAGES_DIR"/*/; do
    if [ -f "${dir}pubspec.yaml" ]; then
      PACKAGE_NAME=$(basename "$dir")
      # Use sed to replace the in_app_console dependency.
      # This matches 'in_app_console: ^X.Y.Z' and replaces it with the new version.
      sed -i '' -E "s/in_app_console: \^[0-9]+\.[0-9]+\.[0-9]+/in_app_console: ^$NEW_VERSION/" "${dir}pubspec.yaml"
      echo "✅ Updated in_app_console dependency in $PACKAGE_NAME"
    fi
  done
else
  echo "⚠️ Packages directory not found at $PACKAGES_DIR. Skipping package updates."
fi

echo "🎉 Version bump complete! Please review the changes using 'git diff'."
echo "Note: You should also update the CHANGELOG.md manually before committing."
