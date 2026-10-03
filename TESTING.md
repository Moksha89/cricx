# Current validation — 0.5.0 (2026-10-03)

Current APK SHA-256: `afc00e7a00d9aef843ff4feb4a0c9ae4d971b69dbbdd73811a0679133ce338be`.

- Godot 4.6.3 import/parse: passed.
- Physics: 764 checks, zero failures (gravity, stepping, bounce, rolling, swept wickets, net containment and energy loss).
- Deliveries: 96 type/speed/target/handedness combinations, zero failures; additional swing direction, mirrored handedness, late reverse swing and cutter spin checks passed. First-bounce preview tolerance: 2.5 cm. Launch velocity magnitude matches selected speed.
- Scene gameplay: 78 checks, zero failures on desktop AND exported Android. Covers all eight delivery buttons, 17-bone character, run-up movement, planted lead foot, hand-synchronised release, speed dragging, raycast target dragging, independent touch IDs, lock/unlock, swipe release, repeat-action blocking, all three cameras, six-ball completion and new over. Android checks run against the installed APK using debug-only opt-in QA, not a separate physics mock.
- Export: v2/v3 APK signatures and 16 KB zip alignment passed. Installed successfully on Android 14 x86_64 AVD `cricx`, ANGLE/SwiftShader.
- Actual Android input injection: speed changed from 132 to 141 km/h; LOCK enabled, confirmed from app state. Remaining gesture coverage comes from the 78 in-app Android checks.
- Desktop and Android landscape renders inspected against the supplied reference. UI placement/colours, eight-icon panel, slider, circular swipe area, target, visible full-body bowler and outdoor lane implemented. A stride capture exposed cropped shoes; follow camera distance and aim were corrected and re-rendered. Android pitch material required separating coplanar ground/pitch surfaces and an explicit uniform after screenshot comparison.

## Remaining gaps

The model and scenery are still stylised procedural art, not reference-quality photoreal assets. Trees, net aliasing, clothing detail, soft lighting and human motion need further art work. The animation is hand-authored IK, not motion capture or a professional bowler's exact action. Ball seams and seam-dependent behaviour are absent; swing, reverse swing and pitch response use tuned coefficients without measured validation. Nets use rigid collision planes, not deformable cloth; bails fall but stump bodies stay upright.

This software-only emulator showed Android system/System UI ANR dialogs and delayed injected inputs during startup/rendering. No physical phone, FPS, thermal, battery or reliable latency claim is made. Passing Android scene checks verifies logic and compatibility, not realistic motion or phone performance. Batting, team play, multiplayer voice, tournaments and face scanning are outside this nets build.

Earlier build reports are in [testing history](docs/testing-history.md).
