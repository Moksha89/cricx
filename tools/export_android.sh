#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -d /workspace/tooling/config ]]; then
  export XDG_CONFIG_HOME=/workspace/tooling/config
  export XDG_DATA_HOME=/workspace/tooling/data
  export XDG_CACHE_HOME=/workspace/tooling/cache
fi
mkdir -p build
# Prevent a stale APK from being mistaken for a successful export.
rm -f build/cricx-debug.apk
godot --headless --export-debug Android build/cricx-debug.apk > /tmp/cricx-android-export.log 2>&1
if rg -n 'SCRIPT ERROR|ERROR:' /tmp/cricx-android-export.log; then
  tail -50 /tmp/cricx-android-export.log
  exit 1
fi
test -s build/cricx-debug.apk
if [[ -x /workspace/tooling/android-sdk/build-tools/36.0.0/apksigner ]]; then
  /workspace/tooling/android-sdk/build-tools/36.0.0/apksigner verify --verbose build/cricx-debug.apk
  /workspace/tooling/android-sdk/build-tools/36.0.0/zipalign -c -P 16 4 build/cricx-debug.apk
fi
printf 'Android debug APK: %s/build/cricx-debug.apk\n' "$PWD"
