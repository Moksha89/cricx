"""Create editable practice nets and render the actual authored bowling action."""
from pathlib import Path
import bpy, math, json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/blender/Bowler.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['BowlerRig']
# Remove studio stage; replace with a dimensioned outdoor lane.
for obj in list(scene.objects):
 if obj.name=='Review_ground' or obj.type=='LIGHT':bpy.data.objects.remove(obj,do_unlink=True)
collection=bpy.data.collections.new('Practice_nets');scene.collection.children.link(collection)
def collect(obj):
 for c in list(obj.users_collection):c.objects.unlink(obj)
 collection.objects.link(obj);return obj
def mat(name,color,rough=.8):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough;return m
grass=mat('Grass',(.10,.19,.035));pitch=mat('WornPitch',(.40,.27,.135));netmat=mat('GreenMesh',(.018,.075,.034),.92);metal=mat('ForestMetal',(.025,.065,.048),.48);wood=mat('Wood',(.50,.32,.13),.7);white=mat('Crease',(.80,.79,.70),.9);cloth=mat('PracticeScreen',(.012,.055,.037),.95)
for m,scale,strength in [(grass,110,.06),(pitch,75,.035),(wood,12,.02)]:
 nodes=m.node_tree.nodes;links=m.node_tree.links;noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=scale
 bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.4;bump.inputs['Distance'].default_value=strength;links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],nodes.get('Principled BSDF').inputs['Normal'])
def box(name,pos,size,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);obj=collect(bpy.context.object);obj.name=name;obj.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);obj.data.materials.append(m)
 bevel=obj.modifiers.new('Rounded edges','BEVEL');bevel.width=.003;bevel.segments=2;return obj
def cylinder(name,pos,r,h,m):
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=h,location=pos);obj=collect(bpy.context.object);obj.name=name;obj.data.materials.append(m)
 for p in obj.data.polygons:p.use_smooth=True
 return obj
box('Grass_ground',(0,-12,-.04),(55,65,.08),grass)
box('Worn_pitch',(0,-12.5,.02),(3.05,35,.04),pitch)
for y in [-5.58,-25.70]:
 for x in [-.0953,0,.0953]:cylinder('Wood_stump',(x,y,.04+.7112/2),.019,.7112,wood)
 for x in [-.0535,.0535]:box('Wood_bail',(x,y,.757),(.107,.035,.012),wood)
 direction=-1 if y>-10 else 1
 box('Popping_crease',(0,y+direction*1.22,.043),(3.66,.045,.006),white)
 box('Bowling_crease',(0,y,.043),(2.64,.045,.006),white)
 for x in [-1.32,1.32]:box('Return_crease',(x,y,.043),(.045,2.44,.006),white)
for x in [-2.6,2.6]:
 for y in [3,-1,-5,-9,-13,-17,-21,-25,-29]:cylinder('Metal_post',(x,y,1.65),.03,3.3,metal)
# All strands in one curve datablock: authored, lightly sagging rope geometry.
curve=bpy.data.curves.new('Green_net_strands','CURVE');curve.dimensions='3D';curve.resolution_u=1;curve.bevel_depth=.0018;curve.bevel_resolution=1
obj=bpy.data.objects.new('Green_mesh_nets',curve);collection.objects.link(obj);curve.materials.append(netmat)
def rope(points):
 s=curve.splines.new('POLY');s.points.add(len(points)-1)
 for p,co in zip(s.points,points):p.co=(*co,1)
for x in [-2.6,2.6]:
 for i in range(28):
  z=.04+i*.12;rope([(x,3-j*.25,z-.04*math.sin(math.pi*((3-j*.25+1)%4)/4)**2) for j in range(129)])
 for j in range(268):
  y=3-j*.12;rope([(x,y,.04+i*.24) for i in range(14)])
for i in range(45):
 x=-2.6+i*5.2/44;rope([(x,3-j*.25,3.3-.09*math.sin(math.pi*(x+2.6)/5.2)**2*math.sin(math.pi*((3-j*.25+1)%4)/4)**2) for j in range(129)])
for j in range(268):
 y=3-j*.12;rope([(-2.6+i*.26,y,3.3-.09*math.sin(math.pi*i/20)**2) for i in range(21)])
for i in range(28):rope([(-2.6+j*.26,-29,.04+i*.12) for j in range(21)])
for j in range(45):rope([(-2.6+j*5.2/44,-29,.04+i*.24) for i in range(14)])
box('Far_practice_screen',(0,-29,.84),(5.15,.015,1.6),cloth)
for x in [-2.58,2.58]:box('Side_practice_screen',(x,-19,.85),(.015,4,1.6),cloth)
# Convert net curve to a static FBX mesh, preserving the editable curve in the .blend source.
bpy.ops.object.select_all(action='DESELECT')
for o in collection.objects:o.select_set(True)
bpy.context.view_layer.objects.active=obj
bpy.ops.object.convert(target='MESH')
# Export wicket origin at zero for Unity, then return objects to Blender stage coordinates.
for o in collection.objects:o.location.y+=5.58
bpy.ops.export_scene.fbx(filepath=str(ROOT/'unity/Assets/Cricx/Models/Nets.fbx'),use_selection=True,object_types={'MESH'},bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
for o in collection.objects:o.location.y-=5.58
world=bpy.data.worlds.new('Outdoor_daylight');scene.world=world;world.use_nodes=True;nodes=world.node_tree.nodes;links=world.node_tree.links
sky=nodes.new('ShaderNodeTexSky');sky.sky_type='NISHITA';sky.sun_elevation=math.radians(35);sky.sun_rotation=math.radians(120);sky.sun_disc=False;nodes.get('Background').inputs['Strength'].default_value=.55;links.new(sky.outputs['Color'],nodes.get('Background').inputs['Color'])
bpy.ops.object.light_add(type='SUN',location=(0,0,6));sun=bpy.context.object;sun.name='Warm_daylight';sun.rotation_euler=(math.radians(30),math.radians(-25),math.radians(-30));sun.data.energy=1.6;sun.data.angle=math.radians(8)
# Place the bowler beside the near wicket, not through the stumps.
placement=bpy.data.objects.new('Bowler_placement',None);scene.collection.objects.link(placement);placement.location.x=.8
rig.parent=placement;bpy.data.objects['Preview_ball'].parent=placement
# 3/4 rear view keeps feet and raised bowling hand in frame.
cam=scene.camera;cam.animation_data_clear();cam.data.lens=38
for frame in range(1,scene.frame_end+1):
 scene.frame_set(frame);root=rig.location.y;cam.location=(-1.3,root+4.6,2.15);cam.rotation_euler=(Vector((.8,root,1.05))-cam.location).to_track_quat('-Z','Y').to_euler();cam.keyframe_insert('location',frame=frame);cam.keyframe_insert('rotation_euler',frame=frame)
scene.render.resolution_x=960;scene.render.resolution_y=540;scene.eevee.taa_render_samples=8;scene.frame_set(145)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/blender/BowlingStudy.blend'),compress=True)
scene.render.filepath=str(ROOT/'build/blender-nets-release.png');bpy.ops.render.render(write_still=True)
print('NETS_READY: 20.12 m wickets, 3.05 m pitch, green side/end/roof nets; Blender stage and Unity FBX exported')
