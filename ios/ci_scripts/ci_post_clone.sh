#!/bin/sh
# Fail this script if any subcommand fails
set -e

# The default execution directory of this script is the ci_scripts directory
# Navigate to the root directory of the project
cd "$CI_PRIMARY_REPOSITORY_PATH"

# 1. Install / Update Flutter SDK with quiet shallow clone
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Installing Flutter SDK..."
    git clone --depth 1 -b stable --single-branch https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

# 2. Add the flutter command to the system PATH
export PATH="$PATH:$FLUTTER_DIR/bin"

echo "Flutter SDK ready:"
flutter --version

# 3. Pre-download the underlying artifacts required for iOS
echo "Precaching iOS artifacts..."
flutter precache --ios

# 4. Fetch the Flutter project dependencies
echo "Fetching pub dependencies..."
flutter pub get

# 5. Generate Generated.xcconfig and .symlinks
echo "Building iOS configuration..."
flutter build ios --config-only --no-codesign

# 6. Install CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
cd ios
pod install

echo "ci_post_clone.sh completed successfully!"
exit 0
