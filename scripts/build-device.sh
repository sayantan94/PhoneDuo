#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
# Compile-check the real iPhone target. This does not sign, install, or distribute the app.
xcodebuild -project PhoneDuo.xcodeproj -scheme PhoneDuo -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath .build-device build CODE_SIGNING_ALLOWED=NO
