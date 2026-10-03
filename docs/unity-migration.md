# Unity / Blender milestone

User-approved scope: bowler, natural bowling action, nets and camera movement. Godot 0.5.0 is historical; it is not the active engine or a Unity build.

## Assets produced

- `art/blender/Bowler.blend`: editable anatomical character, separate shirt/trousers, 49-bone rig including fingers, baked 60 Hz action, palm attachment and review stage.
- `art/blender/BowlingStudy.blend`: the action in an authored outdoor net lane, with the bowler beside the near wicket, rear three-quarter camera, side/roof/end mesh, metal poles, tan pitch, creases and wickets 20.12 m apart.
- `unity/Assets/Cricx/Models/Bowler.fbx` and `Nets.fbx`: Unity-importable models and baked action. Teal weave texture and timing metadata accompany them.
- `art/blender/build_bowler.py`, `build_nets.py`, `verify_action.py`, `render_action.py`: editable and reproducible source workflows.

The human topology is a MakeHuman base mesh explicitly released as CC0. Attribution and source declaration are retained under `art/source`. Clothing, rig, action and net assets are original additions. User reference footage is not redistributed.

## Animation checks

Blender checks: 847, zero failures on the final baked asset. Export/read-back checks also passed: 49 bones, palm socket, skinned mesh, baked action and complete action range. Runtime C# scripts compile against the installed Unity 6 assemblies using its compiler; this does not establish Editor import or gameplay. Checks cover constant limb lengths throughout the action, front-ankle position during the plant/release interval, root run-up travel and ball attachment at the release frame. These checks verify constraints, not whether a viewer finds the motion natural. The action is hand-authored from the reference, not motion capture or a certified recreation of Harbhajan Singh's action.

A rendered full action and release still are published in `downloads`. The action has run-up, gather/bound, lead-arm pull-down, planted front leg, overarm release and follow-through. Facial detail, clothing tailoring, grip shape and movement polish remain work in progress; this is not a scanned or photorealistic athlete.

## Unity setup and validation

Unity 6000.0.23f1 is installed in the cloud. Its archive size and MD5 match official Unity release metadata. Its bundled URP version is 17.0.3. Unity download/package domains and reusable install/start instructions have been saved in the cloud configuration draft.

The Editor starts with XDG config/cache paths under `/workspace/tooling`, but project import stops with **No valid Unity Editor license found**. There is no activated license in this environment. Activate through a supported Unity Hub/licensing workflow; do not send account credentials or licence secrets in chat.

Unity Editor import, generated scene creation, Play Mode, EditMode tests and Android export/runtime are **unverified** until licensing is resolved. Android Build Support and its matching SDK/NDK/JDK also need installation for the new Editor. The old downloadable `cricx-debug.apk` remains the Godot 0.5.0 artifact and must not be labelled as Unity output.

The Unity project contains a scene builder, URP setup, authored asset import, baked animation playback, palm-synchronised ball release, a ballistic target solver, rigidbody containment and follow/side/fixed camera scripts. Only a licensed import can establish that editor APIs, asset axes/materials, scene construction and runtime behave correctly. See `unity/README.md` for exact entry points.
