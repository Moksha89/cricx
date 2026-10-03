"""Create an original skinned cricket athlete, in metres. Blender 4.x."""
import bpy, math
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
materials={}
for name,color in [('kit',(0.018,0.12,0.14,1)),('trim',(0.025,0.32,0.34,1)),('skin',(0.48,0.27,0.16,1)),('hair',(0.025,0.018,0.014,1)),('shoe',(0.80,0.83,0.80,1)),('sole',(0.12,0.16,0.14,1))]:
 m=bpy.data.materials.new(name);m.diffuse_color=color;m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Roughness'].default_value=.75
 materials[name]=m
arm=bpy.data.armatures.new('CricketRig');rig=bpy.data.objects.new('CricketRig',arm);bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bones={}
def bone(name,a,b,parent=None):
 eb=arm.edit_bones.new(name);eb.head=a;eb.tail=b
 if parent:eb.parent=arm.edit_bones[parent]
 bones[name]=(Vector(a),Vector(b))
bone('pelvis',(0,0,.88),(0,0,1.02))
bone('spine',(0,0,1.02),(0,0,1.39),'pelvis')
bone('chest',(0,0,1.39),(0,0,1.53),'spine')
bone('neck',(0,0,1.53),(0,0,1.64),'chest')
bone('head',(0,0,1.64),(0,0,1.84),'neck')
for side,tag in [(-1,'R'),(1,'L')]:
 bone('upper_arm_'+tag,(side*.235,0,1.47),(side*.275,-.02,1.16),'chest')
 bone('forearm_'+tag,(side*.275,-.02,1.16),(side*.275,-.065,.88),'upper_arm_'+tag)
 bone('hand_'+tag,(side*.275,-.065,.88),(side*.275,-.08,.78),'forearm_'+tag)
 bone('thigh_'+tag,(side*.105,0,.91),(side*.12,-.025,.49),'pelvis')
 bone('shin_'+tag,(side*.12,-.025,.49),(side*.12,0,.10),'thigh_'+tag)
 bone('foot_'+tag,(side*.12,0,.10),(side*.12,-.19,.06),'shin_'+tag)
bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
parts=[]
def bind(obj,weights):
 for name,ids in weights.items():
  group=obj.vertex_groups.new(name=name)
  for vid,weight in ids:group.add([vid],weight,'REPLACE')
 mod=obj.modifiers.new('Cricket skin','ARMATURE');mod.object=rig
 obj.parent=rig
 parts.append(obj)
 for polygon in obj.data.polygons:polygon.use_smooth=True

def tube(name,rings,material,weight_fn,segments=20):
 # rings: x, y, z, horizontal radius, depth radius; continuous limb topology.
 verts=[];faces=[];weights={}
 for j,(x,y,z,rx,ry) in enumerate(rings):
  for i in range(segments):
   theta=i*math.tau/segments;verts.append((x+math.cos(theta)*rx,y+math.sin(theta)*ry,z))
   for bn,w in weight_fn(j,z).items():weights.setdefault(bn,[]).append((len(verts)-1,w))
 for j in range(len(rings)-1):
  for i in range(segments):
   a=j*segments+i;b=j*segments+(i+1)%segments;faces.append((a,b,b+segments,a+segments))
 faces.append(tuple(range(segments-1,-1,-1)));faces.append(tuple((len(rings)-1)*segments+i for i in range(segments)))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.data.materials.append(materials[material]);bind(obj,weights)

def oval(name,loc,scale,material,bn):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=loc)
 obj=bpy.context.object;obj.name=name;obj.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 obj.data.materials.append(materials[material]);bind(obj,{bn:[(i,1) for i in range(len(obj.data.vertices))]})

tube('Shirt',[(0,0,.98,.155,.10),(0,0,1.06,.16,.105),(0,0,1.18,.178,.115),(0,0,1.33,.208,.12),(0,0,1.44,.23,.105),(0,0,1.51,.17,.082),(0,0,1.55,.078,.07)],'kit',lambda j,z:{'spine':1} if z<1.30 else {'chest':1})
tube('Collar',[(0,0,1.51,.082,.073),(0,0,1.55,.08,.07)],'trim',lambda j,z:{'neck':1})
oval('Pelvis',(0,0,.95),(.165,.11,.105),'kit','pelvis')
for side,tag in [(-1,'R'),(1,'L')]:
 tube('Trouser_'+tag,[(side*.12,0,.10,.046,.051),(side*.12,0,.20,.050,.060),(side*.12,-.025,.39,.065,.068),(side*.12,-.025,.49,.067,.076),(side*.112,0,.65,.088,.090),(side*.105,0,.82,.095,.105),(side*.105,0,.97,.091,.102)],'kit',lambda j,z:{'shin_'+tag:1} if z<.40 else ({'shin_'+tag:.5,'thigh_'+tag:.5} if z<.58 else {'thigh_'+tag:1}))
 tube('Arm_'+tag,[(side*.275,-.065,.87,.032,.029),(side*.275,-.05,.99,.044,.041),(side*.275,-.02,1.13,.048,.045),(side*.275,-.02,1.20,.052,.05),(side*.257,0,1.33,.064,.064),(side*.235,0,1.47,.072,.075)],'skin',lambda j,z:{'forearm_'+tag:1} if z<1.12 else ({'forearm_'+tag:.5,'upper_arm_'+tag:.5} if z<1.24 else {'upper_arm_'+tag:1}))
 tube('Sleeve_'+tag,[(side*.255,0,1.30,.071,.069),(side*.248,0,1.37,.077,.076),(side*.235,0,1.49,.080,.079)],'kit',lambda j,z:{'upper_arm_'+tag:1})
 oval('Hand_'+tag,(side*.275,-.065,.825),(.039,.034,.065),'skin','hand_'+tag)
 for f in range(4):oval('Finger_'+tag+str(f),(side*.249+f*.017,-.073,.772),(.009,.012,.037),'skin','hand_'+tag)
 oval('Shoe_'+tag,(side*.12,-.075,.070),(.075,.145,.055),'shoe','foot_'+tag)
 oval('Sole_'+tag,(side*.12,-.075,.027),(.075,.143,.019),'sole','foot_'+tag)
 oval('Heel_'+tag,(side*.12,.030,.072),(.068,.067,.055),'shoe','foot_'+tag)
 # Original sleeve shoulder stripe.
 oval('Shoulder_trim_'+tag,(side*.228,0,1.48),(.04,.08,.013),'trim','upper_arm_'+tag)
oval('Neck',(0,0,1.59),(.06,.061,.085),'skin','neck')
oval('Head',(0,-.005,1.735),(.083,.092,.122),'skin','head')
oval('Jaw',(0,-.022,1.675),(.071,.078,.054),'skin','head')
oval('Hair',(0,.01,1.807),(.085,.086,.065),'hair','head')
for side in [-1,1]:
 oval('Ear',(side*.083,-.003,1.73),(.016,.017,.028),'skin','head')
 oval('Brow',(side*.034,-.084,1.768),(.027,.010,.007),'hair','head')
 oval('Eye',(side*.034,-.084,1.750),(.016,.010,.008),'hair','head')
oval('Nose',(0,-.094,1.724),(.013,.020,.029),'skin','head')
oval('Mouth',(0,-.088,1.683),(.027,.008,.004),'hair','head')
# Merge meshes while preserving material indices and skin weights.
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
hero=bpy.context.object;hero.name='CricketAthlete'
# Export original mesh and armature only, no embedded photo assets.
bpy.ops.object.select_all(action='DESELECT');hero.select_set(True);rig.select_set(True)
bpy.ops.export_scene.gltf(filepath='/workspace/cricx/assets/characters/bowler.glb',export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
print('Original skinned athlete exported',len(hero.data.vertices),'vertices',len(arm.bones),'bones')
