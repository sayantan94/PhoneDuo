#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
# Pass a simulator UUID to select another device.
device="${1:-$(./scripts/simulator-id.sh)}"
if ! xcrun simctl list devices booted | /usr/bin/grep -q "$device"; then
  xcrun simctl boot "$device"
fi
xcrun simctl bootstatus "$device" -b
./scripts/build-simulator.sh
xcrun simctl install "$device" .build/Build/Products/Debug-iphonesimulator/PhoneDuo.app
open -a Simulator
xcrun simctl launch "$device" app.phoneduo.PhoneDuo --show-controls
