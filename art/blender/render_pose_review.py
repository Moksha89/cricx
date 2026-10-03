import bpy, sys
from mathutils import Vector
from pathlib import Path
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root/'art/blender/Bowler.blend'))
s=bpy.context.scene;s.render.engine='BLENDER_WORKBENCH';s.display.shading.light='STUDIO';s.display.shading.color_type='MATERIAL';s.render.resolution_x=480;s.render.resolution_y=540;s.render.resolution_percentage=100
cam=s.camera;cam.animation_data_clear();cam.data.type='ORTHO';cam.data.ortho_scale=2.65
rig=bpy.data.objects['BowlerRig']
for view,offset in [('side',Vector((4,0,1.25))),('rear',Vector((1,4,1.25)))]:
 for f in (range(1,212,2) if '--animation' in sys.argv else [25,55,85,112,124,136,145,158,174,195]):
  s.frame_set(f);pos=rig.location.copy();cam.location=pos+offset;cam.rotation_euler=(pos+Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(root/(f'build/review-{view}-{f:04}.png' if '--animation' in sys.argv else f'build/review-{view}-{f}.png'));bpy.ops.render.render(write_still=True)
