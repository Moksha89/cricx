# Cricx — active Unity / Blender milestone

The active project is now **Unity with URP**, scoped to a bowler, bowling action, nets and camera movement. Open [unity/README.md](unity/README.md) for setup and [migration status](docs/unity-migration.md) for verified results and remaining blockers. Editable Blender files are in `art/blender`; Unity FBX/texture assets are in `unity/Assets/Cricx`.

[Blender action preview](downloads/blender-bowling-action.mp4) · [Release still](downloads/blender-bowling-release.png) · [Unity + Blender source](downloads/cricx-unity-study.zip).

**No Unity APK has been built yet.** Unity Editor licensing currently blocks import and runtime validation. The APK and Godot source below are historical 0.5.0 artifacts, not the migrated project.

---

# CricX — Outdoor Bowling Nets

Playable Godot 4.6.3 Android practice prototype, version 0.5.0. Download [the APK](downloads/cricx-debug.apk) and see [the Android screenshot](downloads/nets-android.png) and [test report](TESTING.md).

## Play

Use landscape orientation. Select one of eight deliveries on the right. Drag the left speed slider (60–160 km/h; knuckle capped at 110). Drag the lime pitch target to set line and length; LOCK prevents changes. Swipe upward inside BOWL to start the run-up. Another delivery is blocked until the current ball finishes. The camera button cycles follow, side and fixed views. After six balls, swipe again for a new over. Settings provide reset, batter handedness and half-speed playback.

The original skinned bowler has 17 bones, a dark teal kit and white shoes. Idle, run-up, front-foot plant, release and follow-through are driven by bone animation and inverse kinematics. The ball remains in the hand until release; its initial velocity is solved from that actual release point. Outdoor grass, pitch wear, trees, metal poles and green netting are original procedural assets. Both wickets have three stumps and two bails, separated by 20.12 m; far bails fall on a stump hit.

## Simulation

The ball uses SI units, 9.81 m/s² gravity, bounded 240 Hz integration, aerodynamic drag, configurable swing and late reverse swing, angular velocity, friction-limited spin impulses at bounce, rolling friction, swept stump checks and dissipative net-plane collisions. Cutters move after bounce; knuckle balls use lower pace and spin. In/out directions reverse with the batter's handedness. The trajectory preview and launch solver use the same integrator; tests check the actual first bounce within 2.5 cm of the selected target.

The model remains a gameplay approximation: aerodynamic coefficients, restitution and friction are tuned rather than measured. Netting does not deform, stump bodies remain upright, and pitch/seam variations are not modelled. The bowler and scenery are stylised, not photorealistic; animation is hand-authored, not motion capture or an exact recreation of a professional's action. This is a bowling practice prototype, without batting, multiplayer, tournaments or face scanning.

## Develop

Open `project.godot` in Godot 4.6.3. Run:

```sh
./tools/check.sh
./tools/export_android.sh
```

Scripts use prepared cloud tooling when present. Elsewhere, install matching Godot Android export templates and configure the Android SDK, Java and a debug keystore in Editor Settings. ARM64 and x86_64 are exported. Signing keys stay outside the repository. `tools/create_bowler.py` regenerates the original GLB using Blender.

Tests cover physics, delivery profiles, the complete scene and touch ownership. A debug-only opt-in `user://run_qa` marker runs the scene checks on Android and writes `qa_report.json`; it is absent in ordinary play. No user photos or reference footage are packaged. Earlier research notes and versions are retained in Git history and `docs/`.
