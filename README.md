# CricX — First Nets

An original, offline 3D Android cricket **prototype**, built with Godot 4.6.3. First milestone: validate a pitch, stadium, characters and a playable delivery before adding multiplayer or personalised players.

## Play

Install `build/cricx-debug.apk` on a 64-bit Android phone (Android 7.0+). This is a debug build for local testing, not a Play Store release. Transfer the APK to your phone and permit installation from that source if prompted. No accounts, network or microphone permissions are needed.

1. Tap **BOWL**. The bowler runs up and releases a delivery with varied line and pace.
2. Tap **SWING** just before the ball reaches the batsman. There is no predicted pitching marker.
3. Toggle **SHOT: DRIVE / LOFT** and cycle **AIM: STRAIGHT / LEFT / RIGHT** for the next shot.
4. Bat for six deliveries. **CAMERA** switches between batting and stadium views; **RESTART** resets the session immediately.

The **LICENCES** button shows Godot's MIT licence, native dependency notices and licence texts, and Android component attribution. All player and stadium geometry in this prototype is original procedural art.

This is *boundary nets*: four runs for a grounded boundary, six for an airborne boundary, otherwise a dot. Wickets only count when a missed ball crosses the stumps. Practice continues after wickets so every session contains six deliveries. This is not a full cricket innings.

## Included

- Original procedural stadium, boundary rope, turf, pitch, creases and wickets.
- Batsman with bat, helmet and pads; bowler with articulated run-up, delivery stride and follow-through; umpire with six signal; practice fielders with idle motion.
- Touch buttons and desktop Space input.
- Ball flight with SI-unit gravity, ground impact restitution and rolling friction.
- Swept bat-plane and wicket checks, boundary-before-ground event ordering, over completion and reset.
- Compatibility renderer with a conservative two-light-per-object budget.
- Stadium geometry grouped into five MultiMeshes instead of 504 individual stadium objects; shared materials and modest mesh subdivisions.

## Development

Open `project.godot` in **Godot 4.6.3** and press F6/F5, or run:

```sh
cd /workspace/cricx
./tools/check.sh
godot --path .
```

The cloud setup keeps Android tools and Godot settings under `/workspace/tooling`. `tools/check.sh` and `tools/export_android.sh` activate those paths when present. On a local machine, configure Godot's Android SDK, JDK and debug keystore in Editor Settings, install matching export templates, then run:

```sh
./tools/export_android.sh
```

The export preset includes ARM64 phones and x86_64 emulators. APKs and screenshots are ignored build outputs; signing keys stay outside the repository. To produce an iPhone build later, an Apple toolchain and signing setup are still required.

## Validation and limits

See [TESTING.md](TESTING.md) for the recorded checks and APK checksum.

`tests/physics_test.gd` checks analytic gravity, 30/120 Hz agreement, no ground penetration, pitch bounce, friction, four/six/dot scoring, event ordering and swept wicket checks. `tests/ui_test.gd` verifies shot/aim selection, camera switching, touch-down action mode, bowl/swing wiring, restart during a delivery, keyboard input and the licence popup. The scene smoke test exercises early swings, six-ball completion, restart, a lofted six, a bounced four and a missed ball outside the stumps. The scripts fail on engine errors and reject stale APKs.

This is a simplified, deterministic gameplay model, **not validated real-world cricket simulation**:

- Contact is a timed strike-zone plane, not collision against a moving bat surface.
- No seam, swing, spin, drag, bat edges, LBW, wides, no-balls, catches or manual running yet.
- The ball is visually enlarged for readability; its simulated radius remains 36 mm.
- Restitution and friction are initial tuning values, not calibrated measurements.
- Characters are procedural placeholder art, not photorealistic scanned humans; motion capture is not included.
- Fielders have idle motion but do not chase or catch; no fielding AI, multiplayer, voice, auctions, face scanning or persistence exists yet.
- Desktop/emulator results do not establish real-phone frame rate, heat, input latency or battery use.

Before the next milestone, test the APK on actual phones: ball visibility, touch timing, camera comfort, UI scaling/notches, suspend/resume and a complete six-ball session. Record the phone model, Android version and observed issues. Refine gameplay before committing to detailed character art or networking.

## Player movement update (0.2.0)

Original articulated athletes replace fixed-limb characters. Two-link arm IK keeps hands on the bat through drive and loft animations. Bowler legs stride and gather before an overarm release; the ball starts at the actual animated hand position. Fielders breathe in place. `tests/animation_test.gd` checks limb lengths, foot height, bat grip and actual release linkage. These are procedural stylised models, not realistic textured assets or motion capture.
