"""Author the Reforged cast in Blender: independent silhouettes and 35 action clips.
Run: blender -b -t 6 -P remaster/source/build_cast.py
All mesh parts, armatures, materials and animation keys are editable in source/*.blend.
"""
import os, sys, math
import bpy
from mathutils import Vector
sys.path.insert(0, os.path.dirname(__file__))
import build_assets as a

ivory = a.material('Aged porcelain armor', (.46,.48,.42), .68,.39)
red = a.material('Crimson enamel', (.25,.023,.017), .65,.3)
green = a.material('Verdigris bronze', (.04,.21,.16), .7,.4)
white = a.material('Soulglass', (.37,.7,.92), .2,.25,2)
bone_specs = []

def bone(name, head, tail, parent=None):
    bone_specs.append((name,head,tail,parent))

def rod(name, start, end, r, material, joint):
    mid=(Vector(start)+Vector(end))*.5
    obj=a.cyl(name,mid,r,(Vector(end)-Vector(start)).length,material,joint)
    obj.rotation_euler=(Vector(end)-Vector(start)).to_track_quat('Z','Y').to_euler()
    return obj

def plate(name, verts, faces, material, joint):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    return a.finish(obj,name,material,joint,.014)

def cone(name,loc,r,h,material,joint,tip=.0,axis=None):
    bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r,radius2=tip,depth=h,location=loc)
    obj=a.finish(bpy.context.object,name,material,joint,.012)
    if axis: obj.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
    return obj

def core(loc,r,material,joint,axis='Y'):
    a.cyl('Reactor socket',loc,r*1.3,.11,a.dark,joint,axis)
    a.cyl('Glowing reactor lens',(loc[0],loc[1]-.07,loc[2]),r,.08,material,joint,axis,32)
    for i in range(8):
        angle=i*math.tau/8
        a.cyl('Socket bolt',(loc[0]+math.cos(angle)*r*1.15,loc[1]-.08,loc[2]+math.sin(angle)*r*1.15),.018,.035,a.brass,joint,'Y',8)

def humanoid(kind):
    armor={'hero':ivory,'merchant':a.brass,'sentry':a.steel,'gunner':green,'guardian':ivory,'titan':red,'knight':a.edge,'king':a.dark}.get(kind,a.steel)
    glow=a.cyan if kind=='hero' else white if kind in ('knight','guardian') else a.violet if kind=='king' else a.orange
    heavy=kind in ('titan','guardian'); king=kind=='king'
    width=.86 if heavy else .57; shoulder=.59 if heavy else .40
    bone('root',(0,0,.90),(0,0,1.03));bone('torso',(0,0,1.03),(0,0,1.64),'root');bone('head',(0,0,1.64),(0,0,2.1),'torso')
    a.box('Pelvic exoskeleton',(0,0,.91),(width*.78,.32,.24),a.dark,'root',.06)
    a.box('Ribcage',(0,.025,1.31),(width,.38,.62),a.dark,'torso',.09)
    # Tapered, overlapping armor rather than a cuboid chest.
    for sign in [-1,1]:
        o=a.box('Overlapping pectoral',(sign*width*.25,-.17,1.45),(width*.52,.17,.27),armor,'torso',.055);o.rotation_euler.y=sign*-.13
        o=a.box('Abdominal plate',(sign*.12,-.205,1.18),(.23,.095,.2),armor,'torso',.04);o.rotation_euler.y=sign*.16
        a.box('Belt pouch',(sign*.25,-.18,.92),(.14,.14,.18),a.brass,'root',.025)
        rod('Spinal piston',(sign*.15,.24,1.02),(sign*.15,.24,1.56),.038,a.edge,'torso')
    core((0,-.27,1.41),.12 if not heavy else .21,glow,'torso')
    a.cyl('Neck joint',(0,0,1.70),.085,.16,a.edge,'head')
    if kind=='guardian':
        a.box('Faceless sentinel mask',(0,-.02,1.91),(.39,.33,.43),ivory,'head',.075)
        a.box('Vertical soul slit',(0,-.195,1.93),(.035,.035,.30),glow,'head',.007)
        for x in [-.28,.28]:cone('Mask crest',(x,0,2.14),.10,.52,a.brass,'head')
    else:
        a.sphere('Helmet shell',(0,0,1.91),(.235,.225,.28),armor,'head')
        a.box('Angular faceplate',(0,-.19,1.88),(.35,.15,.25),a.dark,'head',.05)
        a.box('Narrow luminous visor',(0,-.279,1.97),(.34,.028,.045),glow,'head',.007)
        for x in [-.08,.08]:a.cyl('Respirator filter',(x,-.272,1.83),.055,.06,a.edge,'head','Y')
    if kind=='hero':
        a.box('Scarf collar',(0,0,1.68),(.51,.43,.12),a.cloth,'torso',.04)
        bone('scarf',(0,.2,1.65),(0,.45,1.20),'torso')
        plate('Long torn scarf',[(-.20,.21,1.64),(.16,.21,1.64),(.23,.41,.62),(.02,.46,.75),(-.14,.42,.55)],[(0,1,2,3,4)],a.cloth,'scarf')
        rod('Back-mounted scabbard',(-.22,.28,.63),(.28,.28,1.73),.055,a.dark,'torso')
        a.box('Right shoulder insignia',(.43,-.16,1.63),(.12,.025,.11),a.brass,'armR',.008)
    for side,sign in [('L',-1),('R',1)]:
        x=sign*(.26 if heavy else .18)
        bone('thigh'+side,(x,0,.94),(x,0,.51),'root');bone('shin'+side,(x,0,.51),(x,-.02,.09),'thigh'+side)
        a.sphere('Hip ball',(x,0,.88),(.115,.115,.14),a.brass,'thigh'+side)
        a.box('Thigh shell',(x,.01,.71),(.27 if heavy else .22,.29,.34),armor,'thigh'+side,.055)
        rod('Leg hydraulic ram',(x+sign*.11,.08,.84),(x+sign*.11,.08,.53),.027,a.edge,'thigh'+side)
        a.cyl('Knee actuator',(x,0,.48),.105,.28,a.brass,'shin'+side,'Y')
        a.box('Knee shield',(x,-.19,.51),(.23,.10,.20),armor,'shin'+side,.05)
        a.box('Shin armor',(x,0,.29),(.255 if heavy else .20,.27,.32),armor,'shin'+side,.05)
        a.box('Magnetized boot',(x,-.09,.095),(.32 if heavy else .26,.47,.19),a.dark,'shin'+side,.055)
        a.box('Toe cap',(x,-.29,.11),(.31 if heavy else .25,.1,.13),a.edge,'shin'+side,.03)
        ax=shoulder*sign
        bone('arm'+side,(ax,0,1.60),(ax,0,1.18),'torso');bone('fore'+side,(ax,0,1.18),(ax,-.015,.79),'arm'+side)
        a.sphere('Shoulder bearing',(ax,0,1.54),(.16,.16,.16),a.brass,'arm'+side)
        a.box('Curved pauldron',(ax,0,1.64),(.43 if heavy else .29,.42,.22),armor,'arm'+side,.075)
        a.box('Upper arm sleeve',(ax,0,1.36),(.25 if heavy else .17,.23,.29),a.dark,'arm'+side,.045)
        a.cyl('Elbow bearing',(ax,0,1.16),.095,.24,a.edge,'fore'+side,'Y')
        a.box('Braced forearm',(ax,-.015,.99),(.28 if heavy else .21,.27,.29),armor,'fore'+side,.05)
        a.box('Palm',(ax,-.02,.78),(.20,.22,.14),a.dark,'fore'+side,.025)
        for j in range(3):a.box('Finger armor',(ax-.065+j*.065,-.14,.78),(.052,.055,.12),a.edge,'fore'+side,.008)
    if kind=='merchant':
        a.box('Apron',(0,-.23,1.05),(.6,.065,.77),a.cloth,'root',.025)
        a.box('Salvage backpack',(0,.35,1.40),(.72,.39,.83),a.brass,'torso',.09)
        for x in [-.24,0,.24]:a.cyl('Spare flask',(x,.51,1.93),.075,.39,green,'torso')
        a.cyl('Wide-brim cap',(0,0,2.12),.36,.055,a.dark,'head')
        a.cyl('Cap crown',(0,.025,2.20),.22,.16,a.brass,'head')
    elif kind=='sentry':
        rod('Long pike',(.40,0,.32),(.40,0,2.25),.045,a.brass,'foreR')
        cone('Pike point',(.40,0,2.44),.12,.4,a.edge,'foreR')
        a.box('Buckler',(-.47,-.10,1.10),(.36,.17,.49),red,'foreL',.06)
    elif kind=='gunner':
        for x in [-.18,.18]:a.cyl('Pressure canister',(x,.32,1.4),.12,.68,a.brass,'torso')
        a.box('Cannon grip',(.4,-.05,.96),(.30,.33,.38),a.steel,'foreR',.07)
        for x in [.34,.46]:a.cyl('Twin gun muzzle',(x,-.06,.60),.07,.54,a.dark,'foreR')
    elif kind=='titan':
        for x in [-.33,.33]:
            a.cyl('Smokestack',(x,.29,1.88),.13,.73,a.dark,'torso')
            a.cyl('Chimney rim',(x,.29,2.26),.16,.08,a.brass,'torso')
        a.box('Siege hammer',(.59,-.06,.69),(.65,.65,.62),a.dark,'foreR',.1)
        for x in [.32,.86]:a.box('Heated hammer face',(x,-.07,.69),(.075,.68,.58),a.orange,'foreR',.04)
        a.cyl('Boiler back',(0,.42,1.28),.34,.78,a.brass,'torso')
    elif kind=='guardian':
        a.box('Tower shield',(-.69,-.19,1.10),(.53,.21,1.24),ivory,'foreL',.08)
        a.box('Shield rune',(-.69,-.315,1.14),(.06,.04,.83),glow,'foreL',.015)
        rod('Ceremonial staff',(.59,0,.10),(.59,0,2.20),.055,a.brass,'foreR')
        core((.59,-.03,2.36),.22,glow,'foreR')
    elif kind in ('king','knight'):
        for i in range(5 if king else 3):
            x=(i-(2 if king else 1))*.105
            cone('Royal crown',(x,0,2.25+(.12 if king and i==2 else 0)),.045,.37,a.brass,'head')
        bone('cape',(0,.20,1.64),(0,.27,.67),'torso')
        plate('Armored cloak',[(-.36,.23,1.60),(.36,.23,1.6),(.55,.48,.15),(0,.51,.32),(-.55,.48,.15)],[(0,1,2,3,4)],a.cloth if kind=='knight' else a.dark,'cape')
        # Ready stance points the blade forward/up, with its tip above the floor.
        sword=a.box('Greatsword',(.40,-.52,1.37),(.20,.12,1.20),a.edge,'foreR',.035);sword.rotation_euler.x=.55
        fuller=a.box('Sword luminous fuller',(.40,-.59,1.37),(.047,.015,1.05),glow,'foreR',.005);fuller.rotation_euler.x=.55
        a.box('Sword guard',(.40,-.23,.86),(.57,.18,.09),a.brass,'foreR',.025)
        if king:
            bone('halo',(0,.35,1.9),(0,.35,2.20),'torso')
            for i in range(9):
                t=i*math.tau/9
                a.box('Floating crown shard',(math.cos(t)*.73,.39,1.74+math.sin(t)*.73),(.10,.12,.29),a.violet,'halo',.025)
        else:a.box('Knight shield',(-.48,-.14,1.03),(.40,.19,.75),a.brass,'foreL',.075)

def beast(kind):
    croc=kind=='crocodile';dragon=kind=='dragon'
    armor=green if croc else a.dark if dragon else a.steel
    glow=a.cyan if croc else a.violet if dragon else a.orange
    body_z=.79 if croc else 1.17; length=1.8 if croc else 1.1
    bone('root',(0,0,body_z),(0,0,body_z+.2));bone('torso',(0,0,body_z+.1),(0,-.3,body_z+.4),'root')
    bone('head',(0,-length*.45,body_z),(0,-length*.9,body_z+.2),'torso')
    bone('jaw',(0,-length*.55,body_z-.1),(0,-length*1.02,body_z-.1),'head')
    a.sphere('Armored animal chassis',(0,0,body_z),(.45,length*.65,.38),armor,'torso')
    for i in range(7):
        y=-length*.45+i*length*.15
        a.box('Overlapping dorsal plate',(0,y,body_z+.28),(.71,.24,.16),a.brass if i%2 else armor,'torso',.05)
        cone('Dorsal spine',(0,y,body_z+.45),.09,.27,glow,'torso')
    a.box('Predator cranium',(0,-length*.66,body_z+.04),(.5,.59,.33),armor,'head',.085)
    a.box('Long snout',(0,-length*(.94 if croc else .85),body_z),(.41,.73 if croc else .43,.21),armor,'head',.06)
    a.box('Hinged jaw',(0,-length*.91,body_z-.19),(.40,.65 if croc else .43,.13),a.brass,'jaw',.04)
    for sign in [-1,1]:
        a.sphere('Predator eye',(sign*.24,-length*.71,body_z+.2),(.053,.095,.037),glow,'head')
        for j in range(6):cone('Interlocking tooth',(sign*.17,-length*.76-j*.09,body_z-.12),.035,.16,ivory,'head')
    for side,sign in [('L',-1),('R',1)]:
        for front in [False,True]:
            y=-length*.30 if front else length*.37
            top=('arm' if front else 'thigh')+side;low=('fore' if front else 'shin')+side
            bone(top,(sign*.35,y,body_z),(sign*.61,y,.47),'torso' if front else 'root')
            bone(low,(sign*.61,y,.47),(sign*.58,y-.10,.08),top)
            rod('Animal upper leg',(sign*.35,y,body_z),(sign*.61,y,.47),.14,armor,top)
            a.sphere('Animal knee',(sign*.61,y,.43),(.16,.16,.16),a.brass,low)
            rod('Animal lower leg',(sign*.61,y,.44),(sign*.58,y-.08,.12),.11,armor,low)
            a.box('Clawed paw',(sign*.58,y-.18,.09),(.27,.41,.18),a.dark,low,.04)
            for j in range(3):cone('Steel talon',(sign*.58-.085+j*.085,y-.43,.10),.045,.23,ivory,low,axis=(0,-1,0))
    for i in range(4):
        name='tail'+str(i);start=(0,length*.53+i*.39,body_z-i*.08);end=(0,length*.53+(i+1)*.39,body_z-(i+1)*.08)
        bone(name,start,end,'torso' if i==0 else 'tail'+str(i-1))
        rod('Segmented tail',start,end,.19-i*.037,armor,name)
        cone('Tail crest',(0,start[1]+.12,start[2]+.15),.075,.24,a.brass,name)
    if dragon:
        for side,sign in [('L',-1),('R',1)]:
            bone('wing'+side,(sign*.3,.0,1.45),(sign*1.5,.1,1.9),'torso')
            rod('Dragon wing spar',(sign*.3,0,1.4),(sign*1.65,.0,2.35),.06,a.brass,'wing'+side)
            verts=[(sign*.35,.05,1.4),(sign*1.6,.05,2.35),(sign*1.95,.60,.70),(sign*1.05,.75,.94),(sign*.55,.60,.65)]
            plate('Faceted wing membrane',verts,[(0,1,3),(1,2,3),(0,3,4)],a.dark,'wing'+side)
            for tip in verts[1:]:rod('Wing luminous vein',verts[0],tip,.018,a.violet,'wing'+side)
        for x in [-.2,.2]:cone('Dragon horn',(x,-.52,1.71),.09,.6,a.brass,'head',axis=(x,-.1,1))
    elif not croc:
        # Mining beast: huge drilling shoulders and orange furnace belly.
        for sign in [-1,1]:
            a.sphere('Mining shoulder',(sign*.48,-.28,1.29),(.29,.32,.35),a.brass,'armL' if sign<0 else 'armR')
            for i in range(4):cone('Auger blade',(sign*.46,-.61-i*.10,1.27),.22-i*.04,.17,a.edge,'head',axis=(0,-1,0))
        core((0,-.62,1.32),.15,glow,'head')

def drone():
    bone('root',(0,0,.85),(0,0,1));bone('torso',(0,0,1),(0,0,1.4),'root');bone('head',(0,-.1,1.2),(0,-.2,1.5),'torso')
    a.sphere('Suspended gyroscope',(0,0,1.2),(.39,.28,.36),a.steel,'torso')
    core((0,-.29,1.24),.19,a.orange,'head')
    for side,sign in [('L',-1),('R',1)]:
        bone('wing'+side,(sign*.22,0,1.31),(sign*.80,0,1.35),'torso')
        a.box('Rotor nacelle',(sign*.65,0,1.32),(.57,.34,.14),a.brass,'wing'+side,.05)
        a.cyl('Turbofan',(sign*.70,0,1.38),.23,.075,a.dark,'wing'+side)
        for j in range(4):
            o=a.box('Rotor blade',(sign*.70,0,1.44),(.40,.045,.025),a.edge,'wing'+side,.007);o.rotation_euler.z=j*math.pi/4
        rod('Suspended gun',(sign*.21,-.02,1),(sign*.21,-.19,.55),.06,a.dark,'torso')

CLIPS=['idle','run','jump','fall','attack1','attack2','attack3','shoot','climb','dash','hurt','death','skill',
       'blade_1','blade_2','blade_3','hammer_1','hammer_2','hammer_3','gauntlet_1','gauntlet_2','gauntlet_3','gauntlet_4',
       'air_blade','air_hammer','air_gauntlet','uppercut','reload','stairs','swim','wall_slide','slam','roar','bite','tail_sweep','cast']
HERO_CLIPS=['dual_1','dual_2','dual_3','dual_4','air_dual','spear_1','spear_2','spear_3','air_spear','crossbow_shoot']

def animate(arm,kind):
    animal=kind in ('crocodile','dragon','behemoth')
    arm.animation_data_create()
    for clip in CLIPS+(HERO_CLIPS if kind=='hero' else []):
        action=bpy.data.actions.new(clip);arm.animation_data.action=action
        # 25 fps, one-second source clips; runtime adjusts to the attack duration.
        for frame in range(1,26,2):
            t=(frame-1)/24;s=math.sin(math.tau*t);hit=math.sin(math.pi*min(1,t/.57)) if t<.57 else .0
            hit=max(0,hit); settle=math.sin(math.pi*t)
            for b in arm.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
            b=arm.pose.bones
            def rot(name,x=0,y=0,z=0):
                if name in b:b[name].rotation_euler=(x,y,z)
            rot('torso',.01*s,.025*s,0)
            if clip in ('run','stairs','climb','swim'):
                for side,sign in [('L',1),('R',-1)]:
                    rot('thigh'+side,sign*s*(.60 if not animal else .42))
                    rot('shin'+side,max(0,-sign*s)*.85)
                    rot('arm'+side,-sign*s*.58+(2.35 if clip=='climb' else 0))
                    rot('fore'+side,-.3-abs(s)*.25)
                b['root'].location.y=abs(s)*.04
                if clip=='swim':rot('root',-.8)
            elif clip in ('jump','fall','dash','wall_slide'):
                rot('thighL',.7);rot('thighR',-.5);rot('shinL',.9);rot('foreL',-.5);rot('armR',-.7)
                rot('torso',.48 if clip=='dash' else -.12)
                if clip=='wall_slide':rot('armL',2.1);rot('armR',1.9)
            elif clip.startswith('dual') or clip=='air_dual':
                n=int(clip[-1]) if clip[-1].isdigit() else 3
                for side,sign in [('R',1),('L',-1)]:
                    swing=hit if n%2 else settle
                    rot('arm'+side,-.65-swing*(2.1 if sign==1 else 1.7),0,sign*.9*swing)
                    rot('fore'+side,-.65);rot('torso',.15,0,(1 if n%2 else -1)*settle*.65)
            elif clip.startswith('spear') or clip=='air_spear':
                rot('armR',-1.1-hit*.5);rot('foreR',-.8+hit*.75);rot('armL',-1.05-hit*.6);rot('foreL',-.95+hit*.7)
                rot('torso',.18+hit*.25,0,-hit*.35);rot('thighL',-.4*hit);rot('thighR',.35*hit)
                b['root'].location.y=hit*.12
            elif clip=='crossbow_shoot':
                rot('armR',-1.55);rot('foreR',-.22);rot('armL',-1.48);rot('foreL',-.45);rot('torso',-.17*hit)
            elif clip.startswith('gauntlet') or clip in ('uppercut','air_gauntlet'):
                n=int(clip[-1]) if clip[-1].isdigit() else 3
                left=n%2==0;side='L' if left else 'R';other='R' if left else 'L'
                rot('arm'+side,-.5-hit*1.6,0,(-1 if left else 1)*hit*.22)
                rot('fore'+side,-1.15+hit*.95);rot('arm'+other,-.75);rot('fore'+other,-1.15)
                rot('torso',-.15+hit*.32,0,hit*(.55 if left else -.55))
                if clip=='uppercut' or n==4:rot('arm'+side,-.5-hit*2.6);b['root'].location.y=hit*.16
            elif clip.startswith('hammer') or clip in ('slam','air_hammer'):
                rot('armR',-.35-2.65*hit);rot('armL',-.15-2.0*hit);rot('foreR',-.7*hit)
                rot('torso',-.23+settle*.65);rot('thighL',-.35*settle);rot('thighR',.3*settle)
                b['root'].location.y=-settle*.12
            elif clip.startswith('blade') or clip.startswith('attack') or clip in ('skill','air_blade'):
                n=int(clip[-1]) if clip[-1].isdigit() else 3
                rot('armR',-.3-hit*(2.4 if n%2 else -1.7),0,hit*.5)
                rot('foreR',-.45-hit*.6);rot('torso',.13*hit,0,hit*(.75 if n%2 else -.75));rot('armL',.3+hit*.6)
            elif clip=='shoot':rot('armR',-1.5);rot('foreR',-.2);rot('armL',-1.15);rot('foreL',-.9);rot('torso',-.13*hit)
            elif clip=='reload':rot('armR',-.8);rot('foreR',-1.0);rot('armL',-1.1+.35*s);rot('foreL',-1.3+.3*s);rot('head',.18)
            elif clip in ('roar','cast'):rot('armL',-1.0,0,-.7*settle);rot('armR',-1.0,0,.7*settle);rot('head',-.25*settle)
            elif clip=='bite':rot('head',-.28*hit);rot('jaw',.6*settle)
            elif clip=='tail_sweep':rot('torso',0,0,1.1*settle)
            elif clip=='hurt':rot('torso',-.32*settle)
            elif clip=='death':rot('root',-t*1.50);b['root'].location.y=-.62*t
            for side,sign in [('L',1),('R',-1)]:rot('wing'+side,0,sign*(.25+s*.27),0)
            for i in range(4):rot('tail'+str(i),0,0,math.sin(t*math.tau-i*.6)*(.43 if clip=='tail_sweep' else .10))
            rot('scarf',.06*s,0,.09*s);rot('cape',.06*s);rot('halo',0,0,t*math.tau/9)
            if animal and clip in ('attack1','attack2','attack3','skill'):rot('head',-.4*hit);rot('jaw',.60*hit)
            for joint in arm.pose.bones:joint.keyframe_insert('rotation_euler',frame=frame);joint.keyframe_insert('location',frame=frame)
        # Include final frame, to keep clips exactly one second and loop seams stable.
        bpy.context.scene.frame_set(1)
        for joint in arm.pose.bones:joint.keyframe_insert('rotation_euler',frame=25);joint.keyframe_insert('location',frame=25)
        if clip=='death':
            b['root'].rotation_euler.x=-1.5;b['root'].location.y=-.62
            b['root'].keyframe_insert('rotation_euler',frame=25);b['root'].keyframe_insert('location',frame=25)
        track=arm.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action);track.mute=True
    arm.animation_data.action=None
    for track in arm.animation_data.nla_tracks:track.mute=False

def build(kind):
    a.begin();bone_specs.clear()
    if kind=='drone':drone()
    elif kind in ('behemoth','dragon','crocodile'):beast(kind)
    else:humanoid(kind)
    bpy.ops.object.armature_add();arm=bpy.context.object;arm.name='Armature'
    bpy.ops.object.mode_set(mode='EDIT');arm.data.edit_bones.remove(arm.data.edit_bones[0])
    for name,head,tail,parent in bone_specs:
        b=arm.data.edit_bones.new(name);b.head=head;b.tail=tail
        if parent:b.parent=arm.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    for obj,joint in a.bindings:
        group=obj.vertex_groups.new(name=joint);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        mod=obj.modifiers.new('Articulated armor skin','ARMATURE');mod.object=arm;obj.parent=arm
    bpy.ops.object.select_all(action='DESELECT')
    for obj,_ in a.bindings:obj.select_set(True)
    bpy.context.view_layer.objects.active=a.bindings[0][0];bpy.ops.object.join();bpy.context.object.name=kind+'_ArmorSkin'
    animate(arm,kind);bpy.context.scene.render.fps=24;bpy.context.scene.frame_set(1)
    a.export(kind,True)

if __name__=='__main__':
    requested=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    for kind in requested or ['hero','merchant','sentry','gunner','drone','titan','guardian','behemoth','crocodile','dragon','knight','king']:build(kind)
    print('DISTINCT CAST BUILD COMPLETE',flush=True)
