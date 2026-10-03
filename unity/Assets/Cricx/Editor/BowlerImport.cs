using UnityEditor;
public sealed class BowlerImport : AssetPostprocessor {
    void OnPreprocessModel() {
        if (!assetPath.EndsWith("Cricx/Models/Bowler.fbx")) return;
        var importer = (ModelImporter)assetImporter;
        importer.animationType = ModelImporterAnimationType.Generic;
        importer.importAnimation = true;
        importer.animationCompression = ModelImporterAnimationCompression.Off;
        importer.resampleCurves = true;
        importer.globalScale = 1;
        importer.useFileScale = true;
        importer.importCameras = false;
        importer.importLights = false;
    }
}
