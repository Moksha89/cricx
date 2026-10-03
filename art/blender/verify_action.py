import bpy, json, math
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root/'art/blender/Bowler.blend'))
rig=bpy.data.objects['BowlerRig'];scene=bpy.context.scene
points=[];issues=[];checks=0
for frame in range(124,155):
 scene.frame_set(frame);bpy.context.view_layer.update()
 points.append(rig.matrix_world@rig.pose.bones['foot_L'].head)
error=max((p-points[0]).length for p in points)
checks+=1
if error>.01:issues.append('Front-foot drift %.4f m exceeds 1 cm'%error)
for frame in range(1,212):
 scene.frame_set(frame);bpy.context.view_layer.update()
 for bone in ['upper_arm_R','forearm_R','thigh_L','shin_L']:
  p=rig.pose.bones[bone];checks+=1
  if abs((p.tail-p.head).length-rig.data.bones[bone].length)>.0001:issues.append('Bone length changes at frame %d'%frame)
for frame in [1,145]:
 scene.frame_set(frame);bpy.context.view_layer.update()
 if frame==1:first=rig.location.copy()
 else:travel=(rig.location-first).length
checks+=1
if travel<5:issues.append('Run-up root travel too short')
scene.frame_set(145);bpy.context.view_layer.update()
checks+=1
hand=bpy.data.objects['BallGrip'].matrix_world.translation
if (bpy.data.objects['Preview_ball'].location-hand).length>.001:issues.append('Ball not attached to bowling hand at release')
result={'checks':checks,'failures':issues,'front_foot_drift_m':error,'root_travel_m':travel,'release_hand_height_m':hand.z}
(root/'build/blender-action-checks.json').write_text(json.dumps(result,indent=2));print('ACTION_CHECKS',result)
if issues:raise RuntimeError('; '.join(issues))
