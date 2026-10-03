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
