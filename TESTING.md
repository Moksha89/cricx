# Prototype validation

Build: CricX First Nets 0.1.0 (Android debug).
SHA-256: `2e83f2c047c13cdc22739105bb143e757ff5d47f5a031f37e1ccd1b38a67c027`

- Godot 4.6.3 import/parse checks: passed.
- Ball-physics suite: 1,845 assertions, zero failures (many assertions check ground penetration over simulation steps).
- UI suite: shot/aim controls, camera switching, touch-down mode, bowl/swing, active restart, keyboard, licence display and pause/resume: passed.
- Gameplay smoke test: six-ball completion, early swings, wickets, lofted six, bounced four, outside-stump dot and restart: passed.
- Desktop rendered scene: inspected.
- Final APK: signature verification (v2/v3) and 16 KB alignment checks passed.
- Final APK: installation and 3D scene rendering verified on Android 14 x86_64 with ANGLE/SwiftShader.
- Android touch interaction: a delivery advanced the score to 0.1 overs on the preceding build. The final stump-height correction passed the physics/UI/gameplay tests.

The emulator initially failed with the deprecated SwiftShader graphics path (shader uniform errors). Switching to ANGLE and resetting the test emulator data resolved the graphics/startup blockers. No assertions, checksum checks or TLS verification were disabled.

Real Android phone performance, input latency, heat, battery use, suspend/resume and a full manually played over remain unverified. The software-only emulator is too slow for meaningful performance measurement.

Physics is an initial gameplay approximation: flat-ground gravity/restitution/friction, a timed bat strike zone and swept stump checks. It is not calibrated against real cricket footage or measured ball/pitch data. Characters and stadium use original procedural placeholder art.


## Movement update — 0.2.0 (2026-10-03)

This section supersedes prior APK checksums for the current download.

- Physics: 1,845 checks, zero failures. UI and six-ball gameplay checks passed.
- New animation suite passed: constant arm lengths across run-up, feet above local ground, both hands tracking bat grip throughout the swing, ball released from animated hand.
- Desktop OpenGL rendered player close-up inspected visually. Android debug export, v2/v3 signatures and 16 KB zip alignment verified.
- No Android emulator or physical phone was connected for this update. Android runtime/performance and Samsung testing remain unverified.
- Art remains original stylised procedural geometry; no scans, texture maps or motion-capture assets. Fielders do not pursue the ball.

Current APK SHA-256: `151b9ce83ce31d7fc5616819d785522318d5ebb6202107c808b345e0397958f7`.

## Reference-action source update (2026-10-03; not packaged in APK)

All physics (1,845 checks), UI, animation and six-ball gameplay checks passed after the action changes. Animation validation additionally checks front-foot world position from plant to release, near-straight release arm and lateral torso lean. The longer run-up required a longer smoke-test simulation horizon; scoring and wicket expectations remain unchanged. All script suites now fail on engine errors as well as test failure exit codes.

180 side/front review frames rendered under desktop OpenGL; release poses inspected. The review MP4 is hand-authored from uploaded reference footage, not motion capture. Online research requests returned HTTP 403; repertoire notes explicitly remain provisional. No new APK was built and no Android runtime test was performed for this source update. The current APK and its checksum above still refer to version 0.2.0.

## Bowling nets — APK 0.3.0 (2026-10-03)

This entry supersedes previous APK checksums and source-only status.

- All physics, UI, animation and batting smoke checks passed.
- Bowling nets suite passed all 27 combinations of three lines, three lengths and three paces. Actual first bounce is within 25 mm of the target, and hits/misses follow the actual wicket crossing. Six-ball completion, switching to batting, active restart and half-speed playback passed.
- Bowling nets screen rendered under desktop OpenGL and inspected visually; controls fit the 1280 × 720 layout.
- Android debug export succeeded; v2/v3 signatures and 16 KB zip alignment verified.
- No physical Android phone or emulator was connected for this version. Android runtime, Samsung compatibility, heat and performance remain unverified.
- Net walls are visual geometry. This is straight-ball simulation with uncalibrated surface parameters and estimated animation, not measured Harbhajan deliveries or a realistic scanned character.

Current APK SHA-256: `8547f1ce895bbb0e36a2a615548cf5359d0108a3752c15a3d0bf50b9794d1016`.
