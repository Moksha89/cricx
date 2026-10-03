from pathlib import Path
import bpy,json,sys
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(root/'unity/Assets/Cricx/Models/Bowler.fbx'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
checks={'49_bones':len(rig.data.bones)==49,'ball_grip':bpy.data.objects.get('BallGrip') is not None,'baked_action':rig.animation_data is not None and rig.animation_data.action is not None,'skinned_mesh':any(o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers) for o in bpy.context.scene.objects)}
if checks['baked_action']:
 a=rig.animation_data.action;checks['action_range']=a.frame_range[1]-a.frame_range[0]>=209
result={'checks':checks,'failures':[k for k,v in checks.items() if not v]};(root/'build/blender-fbx-checks.json').write_text(json.dumps(result,indent=2));print('FBX_CHECKS',result)
if result['failures']:sys.exit(1)
