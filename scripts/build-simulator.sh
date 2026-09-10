#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
xcodebuild -project PhoneDuo.xcodeproj -scheme PhoneDuo -configuration Debug \
  -sdk iphonesimulator -derivedDataPath .build build CODE_SIGNING_ALLOWED=NO
