#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build
if [[ -d /workspace/tooling/cache ]]; then export XDG_CACHE_HOME=/workspace/tooling/cache; fi
blender -b --python-exit-code 1 --python art/blender/build_bowler.py -- --no-render
blender -b --python-exit-code 1 --python art/blender/verify_action.py
blender -b --python-exit-code 1 --python art/blender/verify_exports.py
blender -b --python-exit-code 1 --python art/blender/build_nets.py
blender -b --python-exit-code 1 --python art/blender/render_action.py
ffmpeg -loglevel error -y -framerate 30 -pattern_type glob -i 'build/blender-action-frames/frame_*.png' -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart downloads/blender-bowling-action.mp4
cp build/blender-nets-release.png downloads/blender-bowling-release.png
cp build/blender-action-checks.json downloads/blender-action-checks.json
cp build/blender-fbx-checks.json downloads/blender-fbx-checks.json
