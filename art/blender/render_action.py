from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/blender/BowlingStudy.blend'))
scene=bpy.context.scene;scene.frame_step=2
scene.render.resolution_x=960;scene.render.resolution_y=540;scene.eevee.taa_render_samples=4
folder=ROOT/'build/blender-action-frames';folder.mkdir(exist_ok=True)
for old in folder.glob('frame_*.png'):old.unlink()
scene.render.filepath=str(folder/'frame_')
bpy.ops.render.render(animation=True)
