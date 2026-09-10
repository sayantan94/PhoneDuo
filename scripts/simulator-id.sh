#!/bin/zsh
set -euo pipefail
xcrun simctl list devices available --json | python3 -c '
import json, sys
all_devices = [device for group in json.load(sys.stdin)["devices"].values() for device in group if device["name"].startswith("iPhone")]
if not all_devices:
    sys.exit("Install an iPhone simulator runtime in Xcode first.")
print(next((device for device in all_devices if device["state"] == "Booted"), all_devices[0])["udid"])
'
