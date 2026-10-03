# CricX — Bowling Nets

An Android **nets-only environment and straight-ball test**, built with Godot 4.6.3. The old stadium, players, batting, fielders, umpire and character animations have been removed. Previous versions remain in Git history.

## Test it

Install `downloads/cricx-debug.apk` (0.4.0) on a 64-bit Android 7+ device.

- Choose **LINE**, **LENGTH** and **PACE**, then **LAUNCH**.
- The camera first follows an empty approach anchor, moves closer to the release location, then tracks the actual ball. This is preparation for attaching a future bowler; no character is currently present.
- **CAM** cycles follow, side and fixed views. Drag the scene horizontally while idle in follow view for a limited orbit. UI touches remain separate.
- **REPLAY** cycles 1×, ½× and ¼× playback.
- A gold spot appears at the actual first bounce. The result reports stump hit/miss, bounce distance, lateral line and release height.
- Six launches complete a session. **RESET** starts again. **LICENCES** displays engine and dependency notices.

## Reusable elements

One original indoor hall and enclosed practice lane, procedural surface materials, net posts, batched net wires, pitch, creases and wickets. Wickets are 20.12 m apart, pitch width is 3.05 m, stumps are 711.2 mm high, popping creases are 1.22 m in front of the wicket and return creases are 1.32 m from centre. Ball rendering and simulation share a 36 mm radius.

`BowlingCameraRig` takes an actor-position anchor for the approach and actual ball position/velocity during delivery. It does not read a predicted landing point. It can be reused with a future animated player. The camera references are the two user-supplied game clips; none of their footage, art or audio is included in the application.

## Physics and limits

The test launcher computes an initial velocity for the selected bounce point. After launch the ball advances through gravity, ground impact and rolling friction; it is not teleported to a landing target. Swept wicket checks avoid missing fast crossings. Side, end and roof net surfaces contain the ball and dissipate energy. The net response is a stationary-plane approximation, not deformable cloth. Wicket impact uses an initial damped response; stumps/bails do not fall.

This is working test infrastructure, **not a finished realistic cricket simulation or photorealistic asset pack**. Restitution and friction need calibration. There is no player, bowling action, swing, spin, aerodynamic drag, seam model, manual bowling timing or batting. Surface textures are procedural. The hall uses low-cost lighting suitable for this renderer, not an offline-rendered scene.

## Development

Open `project.godot` in Godot 4.6.3, or run:

```sh
./tools/check.sh
./tools/export_android.sh
```

These scripts activate prepared cloud tooling under `/workspace/tooling` when available. Locally, install matching Godot export templates and configure the Android SDK, Java and debug keystore in Godot Editor Settings. Export supports ARM64 phones and x86_64 emulators. Keys stay outside the repository.

`tests/physics_test.gd` checks analytic gravity, timestep agreement, bounce, rolling friction, net energy loss and swept wicket tests. `tests/bowling_nets_test.gd` checks all 27 delivery settings, actual first bounce, stump results, side/end/roof containment, session completion, controls, licences and camera tracking. These do not establish physical-phone performance or realism against measured cricket trajectories. See [TESTING.md](TESTING.md).

[Camera preview](downloads/nets-camera-preview.mp4) shows the current no-player camera and launcher sequence. The earlier off-spin research brief in `docs/` is historical planning, with explicit unverified-source limitations.
