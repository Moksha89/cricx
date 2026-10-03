"""Editable Blender athlete + baked right-arm finger-spin study. Run with Blender 4.3."""
from pathlib import Path
import bpy, math, json, numpy as np
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'unity/Assets/Cricx/Models'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
verts=[];uv=[];faces=[];groups={};group=''
for line in (ROOT/'art/source/makehuman-base.obj').open():
 p=line.split()
 if not p:continue
 if p[0]=='v':verts.append(Vector(tuple(map(float,p[1:4]))))
 elif p[0]=='vt':uv.append(tuple(map(float,p[1:3])))
 elif p[0]=='g':group=p[1];groups.setdefault(group,set())
 elif p[0]=='f':
  ids=[int(s.split('/')[0])-1 for s in p[1:]];groups[group].update(ids)
  if group=='body':faces.append((ids,[int(s.split('/')[1])-1 for s in p[1:]]))
scale=1.84/(max(verts[i].y for i in groups['body'])-min(verts[i].y for i in groups['body']))
floor=min(verts[i].y for i in groups['body'])
def convert(v):
 z=(v.y-floor)*scale
 width=1.10 if 1.34<z<1.57 else (.90 if .78<z<1.10 else 1)
 return Vector((v.x*scale*width,-v.z*scale,z))
def joint(name):
 ids=groups['joint-'+name];return convert(sum((verts[i] for i in ids),Vector())/len(ids))
ids=sorted(groups['body']);remap={v:i for i,v in enumerate(ids)}
mesh=bpy.data.meshes.new('Anatomical topology');mesh.from_pydata([convert(verts[i]) for i in ids],[],[[remap[i] for i in f[0]] for f in faces]);mesh.update()
body=bpy.data.objects.new('Athlete_skin',mesh);bpy.context.collection.objects.link(body)
layer=mesh.uv_layers.new(name='UVMap')
for polygon,face in zip(mesh.polygons,faces):
 polygon.use_smooth=True
 for li,ui in zip(polygon.loop_indices,face[1]):layer.data[li].uv=uv[ui]

def material(name,color,rough=.7):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough
 return m
skin=material('Skin',(0.38,.205,.125),.52)
bs=skin.node_tree.nodes.get('Principled BSDF');bs.inputs['Subsurface Weight'].default_value=.08
noise=skin.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=180
bump=skin.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.12;bump.inputs['Distance'].default_value=.0007
skin.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);skin.node_tree.links.new(bump.outputs['Normal'],bs.inputs['Normal'])
kit=material('Teal_woven_kit',(.02,.11,.12),.85)
# Texture file survives FBX import; weave is an original tiled texture, no branded kit.
N=512;yy,xx=np.mgrid[0:N,0:N];rng=np.random.default_rng(17)
grain=.95+.012*np.sin(xx*np.pi/2)+.012*np.sin(yy*np.pi/2)+rng.normal(0,.008,(N,N))
pixels=np.ones((N,N,4),dtype=np.float32);pixels[:,:,:3]=grain[:,:,None]*np.array([.014,.065,.07])
image=bpy.data.images.new('TealWeave',width=N,height=N);image.pixels.foreach_set(pixels.ravel());image.filepath_raw=str(ROOT/'unity/Assets/Cricx/Textures/TealWeave.png');image.file_format='PNG';image.save()
tex=kit.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;kit.node_tree.links.new(tex.outputs['Color'],kit.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
clothnoise=kit.node_tree.nodes.new('ShaderNodeTexNoise');clothnoise.inputs['Scale'].default_value=250
clothbump=kit.node_tree.nodes.new('ShaderNodeBump');clothbump.inputs['Strength'].default_value=.18;clothbump.inputs['Distance'].default_value=.0008
kit.node_tree.links.new(clothnoise.outputs['Fac'],clothbump.inputs['Height']);kit.node_tree.links.new(clothbump.outputs['Normal'],kit.node_tree.nodes.get('Principled BSDF').inputs['Normal'])
white=material('White_shoe',(.72,.74,.70),.57);dark=material('Hair',(.015,.01,.009),.88);trim=material('Kit_trim',(.09,.38,.37),.75)
body.data.materials.append(skin)
arm=bpy.data.armatures.new('BowlerRig');rig=bpy.data.objects.new('BowlerRig',arm);bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
rest={}
def bone(name,head,tail,parent=None):
 b=arm.edit_bones.new(name);b.head=head;b.tail=tail
 if parent:b.parent=arm.edit_bones[parent]
 rest[name]=(Vector(head),Vector(tail))
bone('pelvis',joint('pelvis'),joint('spine-4'))
bone('spine',joint('spine-4'),joint('spine-1'),'pelvis')
bone('chest',joint('spine-1'),joint('neck'),'spine')
bone('neck',joint('neck'),joint('head'),'chest')
bone('head',joint('head'),Vector((0,0,1.84)),'neck')
for tag,s in [('L','l'),('R','r')]:
 bone('clavicle_'+tag,joint(s+'-clavicle'),joint(s+'-shoulder'),'chest')
 bone('upper_arm_'+tag,joint(s+'-shoulder'),joint(s+'-elbow'),'clavicle_'+tag)
 bone('forearm_'+tag,joint(s+'-elbow'),joint(s+'-hand'),'upper_arm_'+tag)
 bone('hand_'+tag,joint(s+'-hand'),joint(s+'-hand-3'),'forearm_'+tag)
 bone('thigh_'+tag,joint(s+'-upper-leg'),joint(s+'-knee'),'pelvis')
 bone('shin_'+tag,joint(s+'-knee'),joint(s+'-ankle'),'thigh_'+tag)
 bone('foot_'+tag,joint(s+'-ankle'),joint(s+'-foot-2'),'shin_'+tag)
 for finger in range(1,6):
  for segment in range(1,4):
   name=f'finger_{tag}_{finger}_{segment}'
   bone(name,joint(f'{s}-finger-{finger}-{segment}'),joint(f'{s}-finger-{finger}-{segment+1}'),'hand_'+tag if segment==1 else f'finger_{tag}_{finger}_{segment-1}')
bpy.ops.object.mode_set(mode='OBJECT')
# Bone heat produces connected anatomical deformation, with a checked fallback for isolated vertices.
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
def distance_segment(p,a,b):
 t=max(0,min(1,(p-a).dot(b-a)/(b-a).length_squared));return (p-(a+(b-a)*t)).length
for v in body.data.vertices:
 if not v.groups:
  near=sorted((distance_segment(v.co,*line),name) for name,line in rest.items())[:3]
  weights=[1/max(d,.006)**4 for d,n in near];total=sum(weights)
  for (_,name),w in zip(near,weights):body.vertex_groups.get(name).add([v.index],w/total,'REPLACE')
# Tailored garment shells inherit exactly the anatomical weights/UVs.
def garment(name,predicate,offset):
 selected=[p for p in mesh.polygons if predicate(p)]
 used=sorted({i for p in selected for i in p.vertices});mapping={i:j for j,i in enumerate(used)}
 coordinates=[]
 for i in used:
  v=mesh.vertices[i];co=v.co+v.normal*offset
  # Small cloth folds: geometry moves with the skinned cloth rather than rigid parts.
  co+=v.normal*(.0018*math.sin(co.z*100+co.x*23)*math.sin(co.y*38))
  coordinates.append(co)
 gm=bpy.data.meshes.new(name);gm.from_pydata(coordinates,[],[[mapping[i] for i in p.vertices] for p in selected]);gm.update();obj=bpy.data.objects.new(name,gm);bpy.context.collection.objects.link(obj);obj.data.materials.append(kit)
 uvl=gm.uv_layers.new(name='UVMap')
 for newp,oldp in zip(gm.polygons,selected):
  newp.use_smooth=True
  for a,b in zip(newp.loop_indices,oldp.loop_indices):uvl.data[a].uv=layer.data[b].uv
 for vg in body.vertex_groups:obj.vertex_groups.new(name=vg.name)
 for old,new in mapping.items():
  for g in mesh.vertices[old].groups:obj.vertex_groups[g.group].add([new],g.weight,'REPLACE')
 mod=obj.modifiers.new('Skin','ARMATURE');mod.object=rig;obj.parent=rig
 sub=obj.modifiers.new('Tailoring surface','SUBSURF');sub.levels=1;sub.render_levels=1
 return obj

def region(p):
 co=sum((mesh.vertices[i].co for i in p.vertices),Vector())/len(p.vertices)
 return co
shirt=garment('Jersey',lambda p:.99<region(p).z<1.56 and (abs(region(p).x)<.235 or region(p).z>1.36),.012)
trousers=garment('Trousers',lambda p:.12<region(p).z<1.045,.012)
# Original shoes, eyes, collar and short hair geometry.
def oval(name,loc,scale_value,mat,bn):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=loc);o=bpy.context.object;o.name=name;o.scale=scale_value
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 vg=o.vertex_groups.new(name=bn);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Skin','ARMATURE');mod.object=rig;o.parent=rig
 for p in o.data.polygons:p.use_smooth=True
 return o
for tag,s in [('L','l'),('R','r')]:
 ankle=joint(s+'-ankle');oval('Trainer_'+tag,Vector((ankle.x,-.09,.07)),(.078,.15,.062),white,'foot_'+tag)
 oval('Sole_'+tag,Vector((ankle.x,-.09,.024)),(.081,.153,.018),trim,'foot_'+tag)
 eye=joint(s+'-eye');oval('Eye_'+tag,eye,(.013,.013,.013),white,'head');oval('Iris_'+tag,eye+Vector((0,-.011,0)),(.006,.003,.006),dark,'head')
# Fit scalp cap to the head's surface instead of a detached spherical haircut.
hairfaces=[p for p in mesh.polygons if region(p).z>1.765 and region(p).y>-.065]
used=sorted({i for p in hairfaces for i in p.vertices});mapping={i:j for j,i in enumerate(used)}
hm=bpy.data.meshes.new('Scalp');hm.from_pydata([mesh.vertices[i].co+mesh.vertices[i].normal*.006 for i in used],[],[[mapping[i] for i in p.vertices] for p in hairfaces]);hm.update();hair=bpy.data.objects.new('Short_hair',hm);bpy.context.collection.objects.link(hair);hm.materials.append(dark);vg=hair.vertex_groups.new(name='head');vg.add(list(range(len(used))),1,'REPLACE');mod=hair.modifiers.new('Skin','ARMATURE');mod.object=rig;hair.parent=rig
for p in hm.polygons:p.use_smooth=True
# Analytic two-bone constraints bake into ordinary FBX bone curves; no runtime IK dependency.
for pb in rig.pose.bones:pb.rotation_mode='QUATERNION'
def global_point(name):return rig.pose.bones[name].matrix.translation.copy()
def aim(name,direction):
 pb=rig.pose.bones[name];restm=arm.bones[name].matrix_local
 rotation=restm.to_3x3().col[1].rotation_difference(direction.normalized()).to_matrix()@restm.to_3x3()
 desired=Matrix.Translation(pb.matrix.translation)@rotation.to_4x4();pb.matrix=desired;bpy.context.view_layer.update()
def ik(upper,lower,end,target,pole):
 a=global_point(upper);l1=(rest[lower][0]-rest[upper][0]).length;l2=(rest[end][0]-rest[lower][0]).length
 axis=target-a;d=max(abs(l1-l2)+.0001,min(axis.length,l1+l2-.0001));axis.normalize();along=(l1*l1-l2*l2+d*d)/(2*d)
 bend=(pole-axis*pole.dot(axis)).normalized();elbow=a+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
 aim(upper,elbow-a);aim(lower,a+axis*d-elbow)
def smooth(t):return t*t*(3-2*t)
def interp(t,keys):
 if t<=keys[0][0]:return Vector(keys[0][1])
 for (a,x),(b,y) in zip(keys,keys[1:]):
  if t<=b:return Vector(x).lerp(Vector(y),smooth((t-a)/(b-a)))
 return Vector(keys[-1][1])
FPS=60;RELEASE=2.40;DURATION=3.50
# Root travel slows into a front-foot block; follow-through keeps travelling forward.
def hermite(t,d,start,end):
 return (t*t*t-2*t*t+t)*start+(-2*t*t*t+3*t*t)*d+(t*t*t-t*t)*end
def root_at(t):
 if t<=1.6:return -4.4*(t/1.6)
 if t<=2.05:return -4.4-hermite((t-1.6)/.45,.9,2.75*.45,.8*.45)
 if t<=2.55:return -5.3-hermite((t-2.05)/.5,.28,.8*.5,.3*.5)
 return -5.58-hermite(min(1,(t-2.55)/.95),1.15,.3*.95,0)
phase_keys={
 'right_hand':[(1.45,(-.25,.10,1.1)),(1.75,(-.20,.20,1.62)),(2.0,(-.22,.30,1.95)),(2.16,(-.22,.37,1.85)),(2.30,(-.23,.08,2.03)),(2.40,(-.22,-.07,2.04)),(2.55,(-.20,-.47,1.65)),(2.72,(-.06,-.44,1.08)),(3.1,(.12,-.08,.91)),(3.5,(-.25,-.08,1.03))],
 'left_hand':[(1.45,(.25,-.12,1.2)),(1.75,(.22,-.10,1.75)),(2.0,(.24,-.34,1.98)),(2.18,(.25,-.40,1.87)),(2.40,(.24,-.26,1.24)),(2.60,(.28,.05,1.07)),(3.1,(.24,.12,1.22)),(3.5,(.25,-.12,1.08))]
}
footplant=None
rig.animation_data_create();action=bpy.data.actions.new('Offspin_Delivery');rig.animation_data.action=action
for frame in range(int(DURATION*FPS)+1):
 t=frame/FPS;bpy.context.scene.frame_set(frame+1)
 for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 root=root_at(t);rig.location=(0,root,0);bpy.context.view_layer.update()
 # Pelvis loading, torso side-on gather, forward trunk flexion after release.
 gather=max(0,min(1,(t-1.5)/.45));flex=max(0,min(1,(t-2.32)/.55))*(1-max(0,min(1,(t-3.1)/.4)))
 pelvis=rig.pose.bones['pelvis'];load=-.085*gather if t>=1.6 else -.08*min(1,t/.16)
 if 1.63<t<2.05:load+=.13*math.sin(math.pi*(t-1.63)/.42)**2
 pelvis.location=arm.bones['pelvis'].matrix_local.to_3x3().inverted()@Vector((0,0,load))
 unwind=1-max(0,min(1,(t-2.0)/.6))
 yaw=.72*gather*unwind
 pelvis.rotation_quaternion=__import__('mathutils').Quaternion(arm.bones['pelvis'].matrix_local.to_3x3().inverted()@Vector((0,0,1)),yaw*.42)
 rig.pose.bones['spine'].rotation_quaternion=__import__('mathutils').Quaternion(Vector((1,0,0)),.09*gather+.38*flex)
 rig.pose.bones['chest'].rotation_quaternion=__import__('mathutils').Quaternion(arm.bones['chest'].matrix_local.to_3x3().inverted()@Vector((0,0,1)),yaw*.58)
 rig.pose.bones['neck'].rotation_quaternion=__import__('mathutils').Quaternion(arm.bones['neck'].matrix_local.to_3x3().inverted()@Vector((0,0,1)),-yaw*.85)
 bpy.context.view_layer.update()
 for tag,sign in [('L',1),('R',-1)]:
  if t<1.6:
   phase=(t/.45+(0 if tag=='L' else .5))%1
   if phase<.55:
    stride=-.34+.68*phase/.55;lift=0
   else:
    progress=(phase-.55)/.45;stride=.34-.68*smooth(progress);lift=.22*math.sin(progress*math.pi)
   blend=min(1,t/.16);stride*=blend;lift*=blend
   foot=Vector((sign*.14,stride,.085+lift));hand=Vector((sign*.245,-stride*.8,1.10)).lerp(Vector((sign*.245,-.12,1.02)),1-blend)
  else:
   foot=interp(t,[(1.6,(sign*.14,0,.12)),(1.85,(sign*.13,-.18,.35 if tag=='L' else .16)),(2.05,(sign*.12,-.38,.085 if tag=='L' else .30)),(2.40,(sign*.12,-.12,.085 if tag=='L' else .34)),(2.7,(sign*.14,-.40,.13 if tag=='R' else .21)),(3.1,(sign*.14,-.22,.09)),(3.5,(sign*.14,0,.085))])
   if tag=='L' and 2.05<=t<=2.55:
    if footplant is None:footplant=Vector((foot.x,foot.y+root,foot.z))
    foot=footplant-Vector((0,root,0))
   hand=interp(t,phase_keys['left_hand' if tag=='L' else 'right_hand'])
  ik('thigh_'+tag,'shin_'+tag,'foot_'+tag,foot,Vector((0,-1,0)))
  aim('foot_'+tag,Vector((sign*.04,-1,-.02 if foot.z<.12 else -.35)))
  ik('upper_arm_'+tag,'forearm_'+tag,'hand_'+tag,hand,Vector((sign*.6,.25,0)))
  # Hands retain grip through the gather, then fingers open through release.
  grip=1 if t<=RELEASE else max(0,1-(t-RELEASE)/.16)
  for f in range(1,6):
   for s in range(1,4):
    pb=rig.pose.bones[f'finger_{tag}_{f}_{s}'];pb.rotation_quaternion=__import__('mathutils').Quaternion(Vector((1,0,0)),(.22 if f==1 else .45)*grip*(1 if tag=='R' else .35))
 bpy.context.view_layer.update()
 rig.keyframe_insert('location',frame=frame+1)
 for pb in rig.pose.bones:
  pb.keyframe_insert('location',frame=frame+1);pb.keyframe_insert('rotation_quaternion',frame=frame+1)
for fc in action.fcurves:
 for k in fc.keyframe_points:k.interpolation='LINEAR'
scene=bpy.context.scene;scene.frame_start=1;scene.frame_end=int(DURATION*FPS)+1;scene.render.fps=FPS
scene.timeline_markers.new('FRONT_FOOT_PLANT',frame=124);scene.timeline_markers.new('BALL_RELEASE',frame=int(RELEASE*FPS)+1);scene.timeline_markers.new('FOLLOW_THROUGH',frame=164)
# Bone-attached palm socket, exported for exact Unity ball attachment.
grip_socket=bpy.data.objects.new('BallGrip',None);bpy.context.collection.objects.link(grip_socket)
grip_socket.parent=rig;grip_socket.parent_type='BONE';grip_socket.parent_bone='hand_R'
grip_socket.location=(0,-arm.bones['hand_R'].length*.45+.055,-.015)
# Ball as a separate object; its parent-free keyframes are useful for visual release review.
ballmat=material('Cricket_ball',(.32,.012,.018),.4)
bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,radius=.036,location=(0,0,0));ball=bpy.context.object;ball.name='Preview_ball';ball.data.materials.append(ballmat)
for p in ball.data.polygons:p.use_smooth=True
release=None
for frame in range(scene.frame_start,scene.frame_end+1):
 scene.frame_set(frame);bpy.context.view_layer.update();t=(frame-1)/FPS
 palm=grip_socket.matrix_world.translation.copy()
 if t<=RELEASE:ball.location=palm;release=palm.copy()
 else:
  dt=t-RELEASE
  target=Vector((-.8,-21.08,.076));offset=target-release;flat=Vector((offset.x,offset.y,0));distance=flat.length;speed=75/3.6;g=9.81
  angle=math.atan((speed*speed-math.sqrt(speed**4-g*(g*distance*distance+2*offset.z*speed*speed)))/(g*distance))
  forward=flat.normalized()*speed*math.cos(angle);up=speed*math.sin(angle)
  first_time=distance/(speed*math.cos(angle))
  if dt<=first_time:ball.location=release+forward*dt+Vector((0,0,up*dt-.5*g*dt*dt))
  else:
   after=dt-first_time;bounce_up=-(up-g*first_time)*.55
   ball.location=target+forward*.88*after+Vector((0,0,bounce_up*after-.5*g*after*after))
   ball.location.z=max(.076,ball.location.z)
   ball.location.y=max(-28.85,ball.location.y)
 ball.keyframe_insert('location',frame=frame)
for fc in ball.animation_data.action.fcurves:
 for k in fc.keyframe_points:k.interpolation='LINEAR'
# Export only character/animation, not preview ball or render-stage scenery.
scene.frame_set(1);bpy.ops.object.select_all(action='DESELECT')
for o in scene.objects:
 if o.type=='ARMATURE' or (o.type in {'MESH','EMPTY'} and o.parent==rig):o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.fbx(filepath=str(OUT/'Bowler.fbx'),use_selection=True,object_types={'ARMATURE','MESH','EMPTY'},add_leaf_bones=False,bake_anim=True,bake_anim_use_all_actions=False,bake_anim_use_nla_strips=False,bake_anim_simplify_factor=0,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
# Stage for checking anatomy and action in Blender, editable and independently renderable.
scene.world.color=(.14,.17,.18)
bpy.ops.mesh.primitive_plane_add(size=30,location=(0,-5,-.005));plane=bpy.context.object;plane.name='Review_ground';plane.data.materials.append(material('Review_ground',(.16,.19,.15),.92))
for name,loc,power,size in [('Key',(4,-3,7),1400,5),('Fill',(-3,-2,4),750,4),('Rim',(2,4,5),1100,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.name=name;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,-4,1))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(4,2.5,2.5));camera=bpy.context.object;camera.name='Action_review_camera';camera.data.lens=43;scene.camera=camera
for frame in range(scene.frame_start,scene.frame_end+1):
 scene.frame_set(frame);t=(frame-1)/FPS;root=root_at(t);camera.location=(3.0,root+4.2,2.1);camera.rotation_euler=(Vector((0,root,.98))-camera.location).to_track_quat('-Z','Y').to_euler();camera.keyframe_insert('location',frame=frame);camera.keyframe_insert('rotation_euler',frame=frame)
scene.render.engine='BLENDER_EEVEE_NEXT';scene.eevee.taa_render_samples=16;scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.frame_set(145)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/Bowler.blend'),compress=True)
scene.render.filepath=str(ROOT/'build/blender-release.png')
if '--no-render' not in __import__('sys').argv:bpy.ops.render.render(write_still=True)
metadata={'fps':FPS,'duration_seconds':DURATION,'release_seconds':RELEASE,'release_frame':145,'front_foot_plant_seconds':2.05,'bones':len(arm.bones),'body_vertices':len(body.data.vertices),'reference':'Right-arm finger-spin reference study, hand-authored, not motion capture','root_motion':True}
(ROOT/'unity/Assets/Cricx/Models/Bowler.motion.json').write_text(json.dumps(metadata,indent=2))
print('BOWLER_READY',json.dumps(metadata))
