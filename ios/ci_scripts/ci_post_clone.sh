#!/bin/sh
# Fail this script if any subcommand fails
set -e

# The default execution directory of this script is the ci_scripts directory
# Navigate to the root directory of the project
cd "$CI_PRIMARY_REPOSITORY_PATH"

# 1. Install / Update Flutter SDK
if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
fi

# 2. Add the flutter command to the system PATH
export PATH="$PATH:$HOME/flutter/bin"

# 3. Pre-download the underlying artifacts required for iOS
flutter precache --ios

# 4. Fetch the Flutter project dependencies
flutter pub get

# 5. Generate Generated.xcconfig and .symlinks
flutter build ios --config-only --no-codesign

# 6. Install CocoaPods dependencies
cd ios
pod install --repo-update || pod install

exit 0
