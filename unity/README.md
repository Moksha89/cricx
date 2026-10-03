# Cricx Unity bowling study

This is the new Unity project, separate from the historical Godot prototype in the repository root. Scope: one anatomical bowler, Blender-authored right-arm finger-spin action, practice nets, ball release and three camera views.

Pinned editor: **Unity 6000.0.23f1**, URP **17.0.3**. Open this `unity` directory in Unity Hub. Install Android Build Support with its SDK, NDK and OpenJDK modules. Activate an eligible Unity licence through the supported Unity Hub flow. No credentials belong in the repository.

After package restore and FBX import, choose **Cricx → Create Bowling Nets Scene**, then Play. BOWL starts the baked action. CAMERA cycles follow, side and fixed views; RESET restarts the study. **Cricx → Build Android Study** exports `Builds/cricx-unity-study.apk`. Existing downloads/cricx-debug.apk is the old Godot 0.5.0 build, not Unity output.

The scene builder creates the URP pipeline and materials, regulation 20.12 m wickets, creases, containment, character, ball and camera. The Blender action uses 60 Hz keyframes and a palm socket named BallGrip. The runtime samples the exact release frame before launching the ball, including when a rendered frame crosses the release time. The target solver launches at the selected actual speed; physics is still an uncalibrated approximation.

Editable Blender sources are under `../art/blender`; FBX and texture assets are under `Assets/Cricx`. The anatomical base mesh has an explicit CC0 declaration, recorded in `../art/source/ASSET-LICENSE.txt`. This is an original reference-informed action, not motion capture or an exact professional-player likeness.

Validation status and remaining setup requirements are in `../docs/unity-migration.md`. An installed Editor, successful import and runtime checks are required before this project can be called playable or its Android build verified.
