#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
device="${1:-$(./scripts/simulator-id.sh)}"
xcodebuild -project PhoneDuo.xcodeproj -scheme PhoneDuo \
  -destination "platform=iOS Simulator,id=$device" -derivedDataPath .build \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
