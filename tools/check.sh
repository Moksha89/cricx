#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -d /workspace/tooling/config ]]; then
  export XDG_CONFIG_HOME=/workspace/tooling/config
  export XDG_DATA_HOME=/workspace/tooling/data
  export XDG_CACHE_HOME=/workspace/tooling/cache
fi
godot --headless --editor --import --quit > /tmp/cricx-check-import.log 2>&1
if rg -n 'SCRIPT ERROR|ERROR:' /tmp/cricx-check-import.log; then exit 1; fi
godot --headless --script res://tests/physics_test.gd
godot --headless --script res://tests/ui_test.gd
godot --headless --script res://tests/animation_test.gd
timeout 30 godot --headless -- --smoke-test > /tmp/cricx-check-scene.log 2>&1
cat /tmp/cricx-check-scene.log
if rg -n 'SCRIPT ERROR|ERROR:' /tmp/cricx-check-scene.log; then exit 1; fi
rg -q '^PASS:' /tmp/cricx-check-scene.log
