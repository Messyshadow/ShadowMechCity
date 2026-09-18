"""Original Blender assets for Shadow Mech City. Run with Blender 4.2+ -b -P.
All meshes, rigid skinning, animation clips and inventory renders are authored here.
No downloaded game assets or third-party code.
"""
import bpy, math, os, random, numpy as np
from mathutils import Vector
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'models')
random.seed(73)
os.makedirs(OUT, exist_ok=True)

def material(name, color, metal=0.0, rough=.4, glow=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough
    if metal > .4 and glow == 0:
        # Embedded original PBR surface: directional brushing, oxidation and fine pitting.
        rng=np.random.default_rng(sum(ord(c) for c in name)); n=512
        y,x=np.mgrid[0:n,0:n]
        grain=rng.random((n,n))*.12
        streak=np.sin(y*.63+np.sin(x*.027)*2)*.035
        mottling=(np.sin(x*.019+y*.027)+np.sin(x*.053-y*.013))*.07
        value=np.clip(.79+grain+streak+mottling,.42,1)
        pixels=np.ones((n,n,4),dtype=np.float32)
        pixels[:,:,:3]=np.array(color,dtype=np.float32)[None,None,:]**(1/2.2)*value[:,:,None]
        for _ in range(90):
            yy=int(rng.integers(0,n));xx=int(rng.integers(0,n));length=int(rng.integers(3,90))
            pixels[yy,xx:min(n,xx+length),:3]*=1.2
        img=bpy.data.images.new(name+' / patina',width=n,height=n,alpha=True)
        img.pixels.foreach_set(pixels.ravel());img.pack()
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img
        m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    if glow:
        p.inputs['Emission Color'].default_value=(*color,1); p.inputs['Emission Strength'].default_value=glow
    return m

def reset():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for a in list(bpy.data.actions): bpy.data.actions.remove(a)

reset()
steel=material('Blued forged steel',(.055,.091,.12),.8,.32)
edge=material('Brushed titanium',(.28,.36,.4),.85,.27)
dark=material('Black ceramic',(.017,.024,.032),.45,.43)
brass=material('Weathered brass',(.48,.24,.075),.75,.32)
yellow=material('Safety ochre',(.92,.46,.055),.4,.36)
cloth=material('Oxide red fabric',(.26,.035,.025),.05,.8)
cyan=material('Ion cyan',(.02,.68,.88),.25,.22,3)
orange=material('Furnace amber',(1,.19,.018),.2,.3,3)
violet=material('Void plasma',(.39,.055,.86),.2,.3,3)
stone=material('Basalt',(.115,.14,.18),.2,.85)
objects=[]; bindings=[]

def finish(o,name,mat,bone=None,bevel=.04):
    o.name=name; o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('Machined edges','BEVEL'); mod.width=bevel; mod.segments=2
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for poly in o.data.polygons: poly.use_smooth=False
    objects.append(o)
    if bone: bindings.append((o,bone))
    return o

def box(name,loc,size,mat=steel,bone=None,bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object
    o.dimensions=size; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat,bone,bevel)

def cyl(name,loc,r,depth,mat=brass,bone=None,axis='Z',verts=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=loc)
    o=bpy.context.object
    if axis=='Y': o.rotation_euler.x=math.pi/2
    if axis=='X': o.rotation_euler.y=math.pi/2
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return finish(o,name,mat,bone,.018)

def sphere(name,loc,size,mat,bone=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1,location=loc)
    o=bpy.context.object; o.scale=size; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat,bone,0)

def torus(name,loc,major,minor,mat=brass,axis='Z'):
    bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=loc,major_radius=major,minor_radius=minor)
    o=bpy.context.object
    if axis=='Y': o.rotation_euler.x=math.pi/2
    return finish(o,name,mat,None,0)

def export(name,animated=False):
    if not animated:
        bpy.ops.object.select_all(action='DESELECT')
        mesh_objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
        for o in mesh_objects:o.select_set(True)
        if mesh_objects:
            bpy.context.view_layer.objects.active=mesh_objects[0];bpy.ops.object.join();bpy.context.object.name=name
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'source',name+'.blend'))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB',
        export_animations=animated,export_animation_mode='NLA_TRACKS',export_nla_strips=True,
        export_force_sampling=True,export_apply=False,export_yup=True)
    print('BUILT',name,flush=True)

def begin():
    reset(); objects.clear(); bindings.clear()

def rig_character(kind):
    begin()
    is_boss=kind in ('titan','king','knight','dragon','crocodile','guardian','behemoth')
    glow=violet if kind in ('king','dragon','knight') else orange if kind!='hero' else cyan
    armor=brass if kind=='merchant' else steel
    # Every piece receives a bone weight, including the weapon sockets.
    box('pelvis',(0,0,.83),(.51,.36,.27),dark,'root')
    box('armored cuirass',(0,0,1.22),(.66,.42,.65),armor,'torso',.09)
    box('front breastplate',(0,-.25,1.29),(.47,.12,.39),edge,'torso')
    cyl('core housing',(0,-.335,1.28),.15,.065,brass,'torso','Y')
    cyl('reactor',(0,-.377,1.28),.105,.04,glow,'torso','Y')
    box('backpack',(0,.3,1.25),(.42,.25,.43),dark,'torso')
    for x in [-.15,.15]: cyl('exhaust',(x,.32,1.6),.055,.32,brass,'torso')
    cyl('neck',(0,0,1.64),.09,.16,edge,'head')
    sphere('helmet',(0,0,1.83),(.25,.23,.26),armor,'head')
    box('visor surround',(0,-.2,1.85),(.44,.105,.155),dark,'head')
    box('visor',(0,-.261,1.855),(.345,.03,.065),glow,'head',.015)
    for x in [-.24,.24]: cyl('ear actuator',(x,0,1.83),.11,.085,brass,'head','X')
    for side,x in [('L',-.2),('R',.2)]:
        thigh='thigh'+side; shin='shin'+side
        cyl('hip bearing',(x,0,.82),.115,.24,brass,thigh,'Y')
        box('thigh plate',(x,0,.64),(.24,.31,.34),armor,thigh)
        cyl('knee',(x,0,.45),.105,.33,edge,shin,'Y')
        box('greave',(x,0,.28),(.24,.28,.34),armor,shin)
        box('shin lamp',(x,-.16,.28),(.05,.03,.2),glow,shin,.009)
        box('boot',(x,-.075,.095),(.3,.47,.18),dark,shin)
    for side,x in [('L',-.43),('R',.43)]:
        arm='arm'+side; fore='fore'+side
        sphere('shoulder',(x,0,1.46),(.22,.24,.22),brass,arm)
        box('pauldron',(x,0,1.53),(.37,.43,.22),armor,arm,.07)
        box('upper arm',(x,0,1.24),(.2,.25,.35),edge,arm)
        cyl('elbow',(x,0,1.05),.1,.3,brass,fore,'Y')
        box('vambrace',(x,-.025,.91),(.25,.3,.29),armor,fore)
        box('fist',(x,-.02,.71),(.24,.28,.17),dark,fore)
    if kind=='hero':
        box('scarf collar',(0,0,1.62),(.56,.43,.10),cloth,'torso')
        o=box('scarf tail',(-.32,.23,1.08),(.25,.06,.87),cloth,'torso'); o.rotation_euler.y=-.15
    if kind=='merchant':
        box('trader apron',(0,-.27,.91),(.58,.06,.66),cloth,'root')
        box('pack chest',(0,.42,1.33),(.75,.42,.62),brass,'torso')
        for x in [-.21,0,.21]: cyl('spare cartridge',(x,-.35,.87),.045,.2,yellow,'root')
        box('hat brim',(0,0,2.04),(.7,.6,.08),dark,'head')
    if kind in ('gunner','drone'):
        box('gun barrel',(.43,-.08,.55),(.22,.32,.65),dark,'foreR')
        cyl('gun glow',(.43,-.08,.21),.11,.08,glow,'foreR')
    if is_boss:
        for x in [-.45,.45]:
            box('heavy reactor shoulder',(x,.02,1.67),(.52,.59,.32),armor,'armL' if x<0 else 'armR',.07)
            for i in range(3): box('shoulder vent',(x-.15+i*.15,-.29,1.69),(.055,.035,.18),glow,'armL' if x<0 else 'armR',.008)
        for x in [-.14,.14]: cyl('crown spire',(x,0,2.14),.075,.37,brass,'head')
        box('siege gauntlet',(.43,-.02,.85),(.45,.47,.47),brass,'foreR',.08)
        if kind in ('king','knight','guardian'):
            box('blade',(.43,0,.03),(.1,.15,1.08),edge,'foreR')
            box('blade energy',(.49,-.081,.03),(.035,.018,1),glow,'foreR',.006)
        if kind in ('dragon','crocodile','behemoth'):
            for x in [-1,1]:
                o=box('wing spar',(x*.68,.15,1.52),(.95,.14,.15),brass,'torso');o.rotation_euler.y=x*.6
                o=box('wing armor',(x*.9,.16,1.1),(.68,.09,.65),dark,'torso');o.rotation_euler.y=x*.4
    bpy.ops.object.armature_add(); arm=bpy.context.object; arm.name='Armature'
    bpy.ops.object.mode_set(mode='EDIT'); arm.data.edit_bones.remove(arm.data.edit_bones[0])
    specs=[('root',(0,0,.82),(0,0,1),None),('torso',(0,0,1),(0,0,1.6),'root'),('head',(0,0,1.63),(0,0,1.97),'torso')]
    for side,x in [('L',-.2),('R',.2)]:
        specs.extend([('thigh'+side,(x,0,.84),(x,0,.45),'root'),('shin'+side,(x,0,.45),(x,0,.07),'thigh'+side)])
    for side,x in [('L',-.43),('R',.43)]:
        specs.extend([('arm'+side,(x,0,1.5),(x,0,1.06),'torso'),('fore'+side,(x,0,1.06),(x,0,.69),'arm'+side)])
    for name,head,tail,parent in specs:
        b=arm.data.edit_bones.new(name); b.head=head;b.tail=tail
        if parent:b.parent=arm.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    for o,bone in bindings:
        v=o.vertex_groups.new(name=bone);v.add(list(range(len(o.data.vertices))),1,'REPLACE')
        mod=o.modifiers.new('Rigid weighted armor','ARMATURE');mod.object=arm;o.parent=arm
    # Join skin sections: retain material slots, reduce runtime draw and skeleton overhead.
    bpy.ops.object.select_all(action='DESELECT')
    for o,_ in bindings:o.select_set(True)
    bpy.context.view_layer.objects.active=bindings[0][0];bpy.ops.object.join();bpy.context.object.name='ArmorSkin'
    arm.animation_data_create()
    for clip in ['idle','run','jump','fall','attack1','attack2','attack3','shoot','climb','dash','hurt','death','skill']:
        action=bpy.data.actions.new(clip);arm.animation_data.action=action
        for frame in [1,7,13,19,25]:
            t=(frame-1)/24; s=math.sin(t*math.tau)
            for b in arm.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
            b=arm.pose.bones
            if clip=='idle': b['torso'].rotation_euler.y=s*.025
            if clip in ('run','climb'):
                amp=.65 if clip=='run' else .85
                for side,sign in [('L',1),('R',-1)]:
                    b['thigh'+side].rotation_euler.x=sign*s*amp
                    b['shin'+side].rotation_euler.x=max(0,-sign*s)*.9
                    b['arm'+side].rotation_euler.x=-sign*s*amp
                    if clip=='climb':b['arm'+side].rotation_euler.x+=2.3
                b['root'].location.y=abs(s)*.07
            elif clip in ('jump','fall','dash'):
                b['thighL'].rotation_euler.x=.6;b['thighR'].rotation_euler.x=-.5
                b['shinL'].rotation_euler.x=.8;b['armR'].rotation_euler.x=-.8
                if clip=='dash':b['torso'].rotation_euler.x=.5
            elif clip.startswith('attack') or clip=='skill':
                n=int(clip[-1]) if clip[-1].isdigit() else 3
                swing=math.sin(t*math.pi)
                b['armR'].rotation_euler.x=-.5-swing*(2.2 if n==1 else -2.4)
                b['foreR'].rotation_euler.x=-.3-swing*.5
                b['torso'].rotation_euler.z=swing*(.65 if n%2 else -.65)
                b['armL'].rotation_euler.x=.5+swing
                if n==3:b['root'].location.y=swing*.18
            elif clip=='shoot':
                b['armR'].rotation_euler.x=-1.6;b['foreR'].rotation_euler.x=-.4
                b['torso'].rotation_euler.x=.12*math.sin(t*math.pi)
            elif clip=='hurt':b['torso'].rotation_euler.x=-.3*math.sin(t*math.pi)
            elif clip=='death':b['root'].rotation_euler.x=-t*1.5;b['root'].location.y=-t*.5
            for bone in arm.pose.bones:
                bone.keyframe_insert('rotation_euler',frame=frame);bone.keyframe_insert('location',frame=frame)
        track=arm.animation_data.nla_tracks.new();track.name=clip
        track.strips.new(clip,1,action);track.mute=True
    arm.animation_data.action=None
    for tr in arm.animation_data.nla_tracks:tr.mute=False
    bpy.context.scene.frame_set(1)
    export(kind,True)

def prop(name):
    begin()
    if name=='platform':
        box('structural slab',(0,0,-.24),(4,2.8,.48),steel)
        box('walking surface',(0,0,-.035),(4.02,2.83,.07),edge,.0 if False else None)
        for x in [-1.7,-.85,0,.85,1.7]:
            box('deck inset',(x,0,.009),(.74,2.45,.025),dark,bevel=.008)
            for y in [-1.16,1.16]:cyl('rivets',(x,y,.03),.045,.03,brass)
        box('front lip',(0,-1.43,-.15),(4.07,.15,.21),brass)
        for x in [-1.8+i*.4 for i in range(10)]:
            o=box('hazard edge',(x,-1.514,-.15),(.18,.015,.17),yellow,bevel=.002);o.rotation_euler.y=.3
        for x in [-1.55,1.55]:
            box('support bracket',(x,0,-.58),(.16,2.35,.5),dark)
    elif name=='tower':
        box('industrial masonry',(0,0,4),(3,3,8),stone,bevel=.08)
        for z in [0,2,4,6,8]:box('steel band',(0,0,z),(3.18,3.18,.18),edge)
        for x in [-1.44,1.44]:box('pillar',(x,-1.55,4),(.16,.2,8),brass)
        for z in [1,3,5,7]:
            box('window recess',(0,-1.52,z),(1.75,.08,1.1),dark)
            for x in [-.53,0,.53]:box('lit slit',(x,-1.58,z),(.12,.04,.7),orange)
        for x in [-.8,.8]:cyl('chimney',(x,.4,8.8),.32,2,steel)
    elif name=='gear':
        cyl('gear body',(0,0,0),1.05,.26,brass,axis='Y',verts=32)
        cyl('gear inset',(0,-.16,0),.76,.08,dark,axis='Y',verts=32)
        torus('ring',(0,-.23,0),.63,.07,edge,'Y')
        cyl('hub',(0,-.22,0),.22,.42,edge,axis='Y')
        for i in range(16):
            a=i*math.tau/16;o=box('tooth',(math.cos(a)*1.08,0,math.sin(a)*1.08),(.3,.3,.22),brass);o.rotation_euler.y=-a
        for i in range(6):
            a=i*math.tau/6;o=box('spoke',(math.cos(a)*.45,-.21,math.sin(a)*.45),(.64,.07,.11),brass);o.rotation_euler.y=-a
    elif name=='pipe':
        cyl('pipe',(0,0,2),.26,4,steel)
        for z in [0,.25,2,3.75,4]:
            cyl('flange',(0,0,z),.34,.11,brass)
            for i in range(8):
                a=i*math.tau/8;cyl('flange bolt',(.29*math.cos(a),.29*math.sin(a),z+.06),.025,.07,edge)
    elif name=='ladder':
        for x in [-.47,.47]:box('ladder rail',(x,0,2),(.1,.13,4),brass)
        for i in range(12):cyl('rung',(0,-.035,.15+i*.335),.045,1.05,yellow,axis='X')
        for z in [.4,3.6]:box('mount',(0,.1,z),(1.3,.3,.12),steel)
    elif name=='lift':
        cyl('elevator deck',(0,0,-.16),1.65,.32,steel,verts=48)
        torus('safety ring',(0,0,.01),1.5,.07,yellow)
        torus('energy ring',(0,0,.025),1.32,.045,cyan)
        cyl('center',(0,0,.001),.75,.03,dark,verts=32)
        for i in range(8):
            a=i*math.tau/8;o=box('deck seam',(math.cos(a)*.98,math.sin(a)*.98,.012),(.4,.04,.03),brass);o.rotation_euler.z=a
    elif name=='console':
        cyl('terminal base',(0,0,.1),.55,.2,steel)
        box('terminal pillar',(0,0,.85),(.65,.45,1.5),steel,.0 if False else None,.09)
        box('screen surround',(0,-.25,1.17),(.53,.12,.6),brass)
        box('screen',(0,-.325,1.2),(.42,.03,.41),cyan)
        for x in [-.15,0,.15]:cyl('button',(x,-.33,.83),.035,.035,orange,axis='Y')
        torus('antenna',(0,0,1.9),.32,.045,cyan,'Y')
    elif name=='arch':
        for x in [-1.6,1.6]:
            box('door pillar',(x,0,2.2),(.5,.9,4.4),steel)
            box('door rail',(x,-.5,2.2),(.09,.06,3.8),cyan)
            for z in [.2,4.2]:box('capital',(x,0,z),(.8,1.1,.35),brass)
        box('lintel',(0,0,4.4),(3.9,1,.6),steel)
        box('lintel light',(0,-.54,4.4),(2.5,.03,.075),cyan)
    elif name=='blade':
        box('sword blade',(0,0,.72),(.12,.2,1.35),edge)
        box('edge light',(.065,-.11,.76),(.025,.025,1.2),cyan,bevel=.004)
        box('hilt',(0,0,.05),(.12,.14,.4),dark)
        box('crossguard',(0,0,.25),(.47,.2,.085),brass)
    elif name=='hammer':
        cyl('shaft',(0,0,.55),.07,1.15,brass)
        box('hammer head',(0,0,1.13),(.86,.5,.46),steel,.0 if False else None,.08)
        for x in [-.41,.41]:box('striking face',(x,0,1.13),(.06,.55,.5),orange)
    elif name=='cannon':
        cyl('cannon body',(0,0,.65),.18,.9,steel)
        for z in [.3,.5,.9,1.1]:cyl('barrel band',(0,0,z),.22,.07,brass)
        cyl('bore',(0,0,1.12),.12,.03,cyan)
        box('stock',(0,0,.14),(.24,.3,.3),dark)
    elif name=='gauntlet':
        box('power fist',(0,0,.4),(.55,.52,.65),steel,.0 if False else None,.1)
        for x in [-.18,-.06,.06,.18]:box('knuckle',(x,-.29,.57),(.1,.14,.23),brass)
        cyl('overdrive core',(0,-.3,.29),.14,.05,orange,axis='Y')
    elif name=='amulet':
        torus('amulet chain',(0,0,.85),.35,.035,brass,'Y')
        sphere('bloodstone',(0,-.035,.36),(.2,.09,.28),orange)
        torus('amulet frame',(0,0,.36),.24,.04,brass,'Y')
    elif name=='armor':
        box('chestplate',(0,0,.6),(.85,.35,1),steel,bevel=.15)
        box('plate trim',(0,-.2,.67),(.57,.08,.54),brass)
        cyl('core',(0,-.27,.67),.17,.06,cyan,axis='Y')
    elif name=='boots':
        for x in [-.23,.23]:
            box('boot',(x,-.1,.17),(.35,.65,.3),steel,bevel=.07)
            box('ankle',(x,.06,.49),(.31,.35,.44),brass)
    elif name=='helmet':
        sphere('helmet',(0,0,.48),(.44,.38,.48),steel)
        box('visor',(0,-.37,.51),(.63,.06,.12),cyan)
    elif name=='ring':
        torus('ring',(0,0,.45),.35,.075,brass,'Y');sphere('gem',(0,-.05,.81),(.14,.09,.13),violet)
    elif name=='potion':
        cyl('vial',(0,0,.45),.22,.65,cyan)
        for z in [.12,.76]:cyl('vial cap',(0,0,z),.25,.13,brass)
    elif name=='reactor':
        cyl('pressure vessel',(0,0,2.5),1.25,5,steel,verts=32)
        for z in [.1,1.1,2.5,3.9,4.9]:torus('pressure band',(0,0,z),1.28,.12,brass)
        for i in range(10):
            a=i*math.tau/10
            box('cooling fin',(math.cos(a)*1.28,math.sin(a)*1.28,2.5),(.12,.12,3.1),edge)
        cyl('inspection hatch',(0,-1.3,2.3),.6,.19,brass,axis='Y',verts=32)
        cyl('firebox',(0,-1.42,2.3),.45,.04,orange,axis='Y',verts=32)
        for x in [-.28,0,.28]:box('hatch bars',(x,-1.48,2.3),(.07,.08,.78),dark)
        for x in [-.65,.65]:cyl('exhaust stack',(x,0,5.7),.26,1.8,steel)
    elif name=='buttress':
        box('stone base',(0,0,.3),(2,2,.6),stone)
        box('fluted pillar',(0,0,3),(.9,1,5.4),stone)
        for z in [.8,4.8,5.5]:box('carved capital',(0,0,z),(1.3,1.4,.28),edge)
        for x in [-.4,.4]:cyl('flute',(x,-.5,3),.085,4,brass)
        bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=.72,radius2=0,depth=2,location=(0,0,6.6));finish(bpy.context.object,'spire',steel)
        cyl('rune light',(0,-.59,3.1),.18,.08,violet,axis='Y')
    elif name=='crystals':
        for i in range(7):
            x=random.uniform(-1,1);y=random.uniform(-.7,.7);h=random.uniform(.65,2.2)
            bpy.ops.mesh.primitive_cone_add(vertices=5,radius1=.25,radius2=.05,depth=h,location=(x,y,h*.5))
            o=finish(bpy.context.object,'mineral shard',violet,None,.01);o.rotation_euler.y=random.uniform(-.35,.35)
        for i in range(5):sphere('rock',(random.uniform(-1,1),random.uniform(-.7,.7),.12),(.45,.35,.25),stone)
    elif name=='turbine':
        torus('culvert',(0,0,1.8),1.7,.22,steel,'Y')
        torus('brass flange',(0,-.18,1.8),1.5,.09,brass,'Y')
        cyl('shaft',(0,0,1.8),.3,.7,edge,axis='Y')
        for i in range(9):
            a=i*math.tau/9;o=box('turbine blade',(math.cos(a)*.9,-.05,1.8+math.sin(a)*.9),(1.1,.18,.32),brass);o.rotation_euler.y=-a-.4
        for x in [-1.2,1.2]:box('base leg',(x,0,.3),(.25,.6,.6),steel)
    export(name)
    if name in ('blade','hammer','cannon','gauntlet','amulet','armor','boots','helmet','ring','potion'):
        render_icon(name)

def render_icon(name):
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
    scene.render.resolution_x=256;scene.render.resolution_y=256;scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.world.color=(.2,.2,.2)
    bpy.ops.object.camera_add(location=(2.5,-4,2.5));cam=bpy.context.object
    cam.rotation_euler=(Vector((0,0,.65))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=2;scene.camera=cam
    for loc,power,color in [((1,-3,4),500,(.55,.8,1)),((-2,0,2),650,(1,.42,.12))]:
        bpy.ops.object.light_add(type='AREA',location=loc);bpy.context.object.data.energy=power
        bpy.context.object.data.color=color;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=3
    scene.render.filepath=os.path.join(ROOT,'assets','icons',name+'.png');bpy.ops.render.render(write_still=True)

for name in ['hero','merchant','sentry','gunner','drone','titan','king','knight','dragon','crocodile','guardian','behemoth']:
    rig_character(name)
for name in ['platform','tower','gear','pipe','ladder','lift','console','arch','blade','hammer','cannon','gauntlet','amulet','armor','boots','helmet','ring','potion','reactor','buttress','crystals','turbine']:
    prop(name)
print('ASSET BUILD COMPLETE',flush=True)
