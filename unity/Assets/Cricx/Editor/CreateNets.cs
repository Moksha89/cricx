using System;
using System.IO;
using System.Linq;
using Cricx;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.Build;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;

public static class CreateNets {
    const string Folder = "Assets/Cricx/Generated";
    static Material Mat(string name, Color color) {
        string path = Folder + "/" + name + ".mat";
        var existing = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (existing) return existing;
        var mat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
        mat.color = color; mat.SetFloat("_Smoothness", .22f);
        AssetDatabase.CreateAsset(mat, path); return mat;
    }
    static GameObject Box(string name, Vector3 pos, Vector3 size, Material mat, bool collide = true) {
        var obj = GameObject.CreatePrimitive(PrimitiveType.Cube); obj.name = name;
        obj.transform.position = pos; obj.transform.localScale = size;
        obj.GetComponent<Renderer>().sharedMaterial = mat;
        if (!collide) UnityEngine.Object.DestroyImmediate(obj.GetComponent<Collider>());
        return obj;
    }
    [MenuItem("Cricx/Create Bowling Nets Scene")]
    public static void BuildScene() {
        Directory.CreateDirectory(Folder); AssetDatabase.Refresh();
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        // Use ordinary non-HDR targets initially; improve art through authored materials and lighting.
        var renderer = ScriptableObject.CreateInstance<UniversalRendererData>();
        renderer.name = "CricxRenderer";
        string rendererPath = Folder + "/CricxRenderer.asset";
        if (AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(rendererPath)) AssetDatabase.DeleteAsset(rendererPath);
        AssetDatabase.CreateAsset(renderer, rendererPath);
        var pipeline = UniversalRenderPipelineAsset.Create(renderer);
        pipeline.name = "CricxURP"; pipeline.supportsHDR = false; pipeline.msaaSampleCount = 4;
        pipeline.shadowDistance = 45;
        string pipelinePath = Folder + "/CricxURP.asset";
        if (AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(pipelinePath)) AssetDatabase.DeleteAsset(pipelinePath);
        AssetDatabase.CreateAsset(pipeline, pipelinePath);
        GraphicsSettings.defaultRenderPipeline = pipeline; QualitySettings.renderPipeline = pipeline;
        var turf = Mat("Grass", new Color(.15f, .23f, .075f));
        var pitch = Mat("WornPitch", new Color(.53f, .38f, .22f));
        var metal = Mat("ForestMetal", new Color(.055f, .13f, .10f));
        var wood = Mat("Wood", new Color(.65f, .44f, .24f));
        var crease = Mat("Crease", new Color(.87f, .86f, .78f));
        Box("Ground", new Vector3(0, -.07f, 7), new Vector3(55, .12f, 65), turf);
        Box("Pitch", new Vector3(0, 0, 5), new Vector3(3.05f, .08f, 35), pitch);
        for (int end = 0; end < 2; end++) {
            float z = end * 20.12f;
            for (int i = -1; i <= 1; i++) Box("Stump", new Vector3(i * .0953f, .3956f, z), new Vector3(.038f, .7112f, .038f), wood);
            for (int i = -1; i <= 1; i += 2) Box("Bail", new Vector3(i * .0535f, .757f, z), new Vector3(.107f, .012f, .035f), wood);
            Box("Bowling crease", new Vector3(0, .046f, z), new Vector3(2.64f, .008f, .045f), crease, false);
            Box("Popping crease", new Vector3(0, .046f, z + (end == 0 ? 1.22f : -1.22f)), new Vector3(3.66f, .008f, .045f), crease, false);
            foreach (float x in new[] {-1.32f, 1.32f}) Box("Return crease", new Vector3(x, .046f, z), new Vector3(.045f, .008f, 2.44f), crease, false);
        }
        var net = new GameObject("Net enclosure");
        // A shared mesh for each wall avoids the broken-looking one-pixel wire patterns of the old prototype.
        var netMat = Mat("GreenMesh", new Color(.08f, .22f, .14f));
        foreach (float x in new[] {-2.6f, 2.6f}) {
            for (float z = -9; z <= 23; z += 4) Box("Pole", new Vector3(x, 1.7f, z), new Vector3(.06f, 3.4f, .06f), metal);
            for (float y = .08f; y < 3.3f; y += .16f) Box("Net cord", new Vector3(x, y, 7), new Vector3(.003f, .003f, 32), netMat, false).transform.SetParent(net.transform);
            for (float z = -9; z <= 23; z += .16f) Box("Net cord", new Vector3(x, 1.66f, z), new Vector3(.003f, 3.2f, .003f), netMat, false).transform.SetParent(net.transform);
            Box("Invisible containment", new Vector3(x, 1.65f, 7), new Vector3(.02f, 3.3f, 32), metal).GetComponent<Renderer>().enabled = false;
        }
        for (float x = -2.6f; x <= 2.6f; x += .16f) Box("Roof cord", new Vector3(x, 3.3f, 7), new Vector3(.003f, .003f, 32), netMat, false).transform.SetParent(net.transform);
        for (float z = -9; z <= 23; z += .16f) Box("Roof cord", new Vector3(0, 3.3f, z), new Vector3(5.2f, .003f, .003f), netMat, false).transform.SetParent(net.transform);
        Box("Invisible roof", new Vector3(0, 3.32f, 7), new Vector3(5.2f, .02f, 32), metal).GetComponent<Renderer>().enabled = false;
        Box("Back net containment", new Vector3(0, 1.65f, 23), new Vector3(5.2f, 3.3f, .02f), metal).GetComponent<Renderer>().enabled = false;
        Box("Back practice screen", new Vector3(0, .9f, 23), new Vector3(5.2f, 1.7f, .025f), metal, false);
        // Use the authored Blender nets for all visible geometry; primitives above are collision proxies.
        foreach (var r in UnityEngine.Object.FindObjectsByType<MeshRenderer>(FindObjectsSortMode.None)) {
            if (r.GetComponent<Collider>()) r.enabled = false;
            else UnityEngine.Object.DestroyImmediate(r.gameObject);
        }
        var netsAsset = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Cricx/Models/Nets.fbx");
        if (!netsAsset) throw new InvalidOperationException("Blender Nets.fbx is missing or failed to import.");
        var authoredNets = (GameObject)PrefabUtility.InstantiatePrefab(netsAsset);
        foreach (var r in authoredNets.GetComponentsInChildren<Renderer>()) {
            r.sharedMaterials = r.sharedMaterials.Select(m => {
                string n = m ? m.name : "";
                if (n.Contains("WornPitch")) return pitch;
                if (n.Contains("Grass")) return turf;
                if (n.Contains("Wood")) return wood;
                if (n.Contains("Crease")) return crease;
                if (n.Contains("GreenMesh")) return netMat;
                return metal;
            }).ToArray();
        }
        var sun = new GameObject("Warm daylight").AddComponent<Light>(); sun.type = LightType.Directional;
        sun.color = new Color(1, .92f, .80f); sun.intensity = 1.4f; sun.shadows = LightShadows.Soft;
        sun.transform.rotation = Quaternion.Euler(48, -35, 0);
        RenderSettings.ambientMode = AmbientMode.Flat; RenderSettings.ambientLight = new Color(.45f, .52f, .56f);
        var root = new GameObject("Bowling study"); var study = root.AddComponent<BowlingStudy>();
        var modelAsset = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Cricx/Models/Bowler.fbx");
        if (!modelAsset) throw new InvalidOperationException("Blender FBX is missing or failed to import.");
        var model = (GameObject)PrefabUtility.InstantiatePrefab(modelAsset);
        var placement = new GameObject("Bowler placement").transform;
        placement.position = new Vector3(.8f, .04f, -5.6f);
        model.transform.SetParent(placement, false);
        foreach (var animator in model.GetComponentsInChildren<Animator>()) animator.enabled = false;
        study.athlete = model;
        study.deliveryClip = AssetDatabase.LoadAllAssetsAtPath("Assets/Cricx/Models/Bowler.fbx").OfType<AnimationClip>().First(c => !c.name.StartsWith("__preview__"));
        var bones = model.GetComponentsInChildren<Transform>();
        study.bowlingHand = bones.First(t => t.name == "BallGrip"); study.pelvis = bones.First(t => t.name == "pelvis");
        var skin = Mat("Skin", new Color(.38f, .205f, .125f));
        var kit = Mat("TealKit", new Color(.09f, .29f, .31f));
        kit.color = Color.white;
        kit.SetTexture("_BaseMap", AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Cricx/Textures/TealWeave.png"));
        foreach (var rendererObject in model.GetComponentsInChildren<Renderer>()) {
            rendererObject.sharedMaterials = rendererObject.sharedMaterials.Select(m => {
                string name = m ? m.name : "";
                if (name.Contains("kit", StringComparison.OrdinalIgnoreCase) || name.Contains("trim", StringComparison.OrdinalIgnoreCase)) return kit;
                if (name.Contains("Hair")) return Mat("Hair", new Color(.025f, .017f, .012f));
                if (name.Contains("shoe") || name.Contains("Eye")) return Mat("Shoe", new Color(.78f, .79f, .74f));
                return skin;
            }).ToArray();
        }
        var ball = GameObject.CreatePrimitive(PrimitiveType.Sphere); ball.name = "Cricket ball"; ball.transform.localScale = Vector3.one * .072f;
        ball.GetComponent<Renderer>().sharedMaterial = Mat("RedBall", new Color(.40f, .016f, .025f));
        study.ball = ball.AddComponent<Rigidbody>(); study.ball.mass = .156f; study.ball.maxAngularVelocity = 120;
        study.ball.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic; study.ball.interpolation = RigidbodyInterpolation.Interpolate;
        var bounce = new PhysicsMaterial("Cricket ball bounce") { bounciness = .55f, dynamicFriction = .28f, staticFriction = .28f, bounceCombine = PhysicsMaterialCombine.Maximum };
        string bouncePath = Folder + "/CricketBall.physicsMaterial";
        var savedBounce = AssetDatabase.LoadAssetAtPath<PhysicsMaterial>(bouncePath);
        if (!savedBounce) AssetDatabase.CreateAsset(bounce, bouncePath);
        ball.GetComponent<Collider>().sharedMaterial = savedBounce ? savedBounce : bounce;
        var cameraObject = new GameObject("Bowling camera"); var camera = cameraObject.AddComponent<Camera>(); camera.tag = "MainCamera";
        camera.fieldOfView = 42; camera.nearClipPlane = .05f; camera.allowHDR = false;
        camera.backgroundColor = new Color(.63f, .74f, .78f); camera.clearFlags = CameraClearFlags.SolidColor;
        cameraObject.AddComponent<AudioListener>(); var rig = cameraObject.AddComponent<StudyCamera>();
        rig.pelvis = study.pelvis; rig.ball = study.ball; rig.study = study; study.studyCamera = rig;
        camera.transform.position = new Vector3(.3f, 2.4f, -10.2f); camera.transform.LookAt(new Vector3(.8f, 1, -4.8f));
        PlayerSettings.colorSpace = ColorSpace.Linear;
        PlayerSettings.companyName = "Cricx"; PlayerSettings.productName = "Cricx Bowling Study";
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
        PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, "com.cricx.unitynets");
        PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.bundleVersion = "0.1.0-unity-study";
        PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
        PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { GraphicsDeviceType.OpenGLES3 });
        EditorSceneManager.SaveScene(scene, Folder + "/BowlingNets.unity");
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(Folder + "/BowlingNets.unity", true) };
        AssetDatabase.SaveAssets(); Debug.Log("CRICX_UNITY_SCENE_CREATED");
    }
    [MenuItem("Cricx/Build Android Study")]
    public static void BuildAndroid() {
        BuildScene(); Directory.CreateDirectory("Builds");
        var report = BuildPipeline.BuildPlayer(EditorBuildSettings.scenes.Select(s => s.path).ToArray(), "Builds/cricx-unity-study.apk", BuildTarget.Android, BuildOptions.Development);
        if (report.summary.result != UnityEditor.Build.Reporting.BuildResult.Succeeded) throw new Exception("Android build failed: " + report.summary.result);
    }
}
