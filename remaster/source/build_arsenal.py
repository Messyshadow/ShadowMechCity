"""Blender-authored legacy weapon families and four distinct articulated companions."""
import sys, os, math
import bpy
sys.path.insert(0, os.path.dirname(__file__))
import build_assets as a

def weapons():
    a.begin()
    a.box('Shadow short blade',(0,0,.58),(.18,.10,.94),a.edge)
    a.box('Violet fuller',(0,-.06,.62),(.045,.03,.79),a.violet,bevel=.004)
    a.box('Finger guard',(0,0,.18),(.35,.18,.09),a.brass)
    a.cyl('Wrapped handle',(0,0,-.01),.065,.34,a.dark)
    a.export('dual')
    a.begin()
    a.cyl('Telescopic shaft',(0,0,.85),.055,2.0,a.brass)
    for z in [.2,.5,.8]:a.cyl('Grip band',(0,0,z),.078,.08,a.dark)
    a.box('Pike blade',(0,0,2.0),(.20,.09,.55),a.edge)
    a.box('Cutting edge',(0,-.055,2.05),(.06,.025,.46),a.cyan,bevel=.005)
    for x in [-.18,.18]:a.box('Split prongs',(x,0,1.75),(.08,.12,.48),a.edge)
    a.export('spear')
    a.begin()
    a.box('Crossbow receiver',(0,0,.44),(.18,.21,.87),a.dark)
    a.box('Bolt guide',(0,-.12,.62),(.09,.06,.91),a.edge)
    for side in [-1,1]:
        limb=a.box('Spring limbs',(side*.3,0,.86),(.57,.09,.13),a.brass);limb.rotation_euler.y=side*.24
        a.cyl('Tension spool',(side*.57,0,.90),.105,.10,a.edge,axis='Y')
    a.box('Taut bowstring',(0,.06,.74),(1.08,.025,.025),a.cyan,bevel=.004)
    a.box('Bolt magazine',(0,.19,.38),(.31,.19,.37),a.brass)
    a.export('crossbow')

def companion(kind):
    a.begin();spec=[('root',(0,0,.5),(0,0,.7),None),('head',(0,-.3,.7),(0,-.3,1.0),'root')]
    air=kind in ('bee','wisp');heavy=kind=='mole';color=a.orange if heavy else a.violet if kind=='bee' else a.cyan
    a.sphere('Armored chassis',(0,0,.66),(.43 if heavy else .30,.55 if not air else .30,.27),a.steel,'root')
    a.sphere('Optical assembly',(0,-.4,.82),(.25,.30,.22),a.brass,'head')
    a.box('Optical visor',(0,-.68,.85),(.34,.045,.07),color,'head',.01)
    a.cyl('Core housing',(0,0,.95),.14,.12,a.dark,'root')
    a.cyl('Signal core',(0,0,1.01),.095,.08,color,'root')
    if not air:
        for side,sign in [('L',-1),('R',1)]:
            for end,y in [('Front',-.32),('Rear',.33)]:
                joint=side+end;spec.append((joint,(sign*.25,y,.6),(sign*.25,y,.15),'root'))
                a.cyl('Hip bearing',(sign*.29,y,.54),.11,.13,a.brass,joint,axis='X')
                a.box('Articulated leg',(sign*.32,y,.32),(.14,.17,.44),a.edge,joint)
                a.box('Clawed foot',(sign*.32,y-.07,.10),(.23,.32,.14),a.dark,joint)
        if heavy:
            a.box('Bulwark shield',(0,-.85,.61),(.99,.16,.86),a.brass,'head',.09)
            a.box('Shield light',(0,-.945,.61),(.67,.035,.09),color,'head',.008)
        else:
            for x in [-.15,.15]:a.box('Guard canine',(x,-.72,.68),(.055,.16,.12),a.edge,'head',.01)
            a.box('Rear exhaust',(0,.60,.68),(.19,.30,.14),a.brass,'root')
    else:
        for side,sign in [('L',-1),('R',1)]:
            joint='wing'+side;spec.append((joint,(sign*.22,0,.7),(sign*.70,0,.7),'root'))
            a.box('Wing arm',(sign*.5,0,.76),(.70,.10,.08),a.brass,joint)
            a.cyl('Rotor housing',(sign*.68,0,.80),.22,.08,a.dark,joint)
            for j in range(3):
                vane=a.box('Rotor vane',(sign*.68,0,.86),(.42,.035,.025),color,joint,.004);vane.rotation_euler.z=j*math.pi/3
        if kind=='bee':
            for x in [-.12,.12]:a.cyl('Railgun barrel',(x,-.25,.42),.055,.58,a.brass,'root',axis='Y')
        else:
            a.sphere('Repair orb',(0,-.05,.32),(.20,.20,.21),a.cyan,'root')
    bpy.ops.object.armature_add();arm=bpy.context.object;arm.name='Armature'
    bpy.ops.object.mode_set(mode='EDIT');arm.data.edit_bones.remove(arm.data.edit_bones[0])
    for name,head,tail,parent in spec:
        bone=arm.data.edit_bones.new(name);bone.head=head;bone.tail=tail
        if parent:bone.parent=arm.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    for obj,joint in a.bindings:
        group=obj.vertex_groups.new(name=joint);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        mod=obj.modifiers.new('Robot articulation','ARMATURE');mod.object=arm;obj.parent=arm
    arm.animation_data_create()
    for clip in ['idle','run','attack','hurt','death']:
        action=bpy.data.actions.new(clip);arm.animation_data.action=action
        for frame in range(1,26,2):
            t=(frame-1)/24;s=math.sin(t*math.tau)
            for bone in arm.pose.bones:
                bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
                if 'Front' in bone.name or 'Rear' in bone.name:bone.rotation_euler.x=s*(.7 if clip=='run' else .04)*(1 if bone.name in ['LFront','RRear'] else -1)
                if bone.name.startswith('wing'):bone.rotation_euler.y=s*.18
                if bone.name=='head' and clip=='attack':bone.rotation_euler.x=-math.sin(t*math.pi)*.5
                if bone.name=='root':
                    bone.location.y=s*.025
                    if clip=='hurt':bone.rotation_euler.x=math.sin(t*math.pi)*.2
                    if clip=='death':bone.rotation_euler.y=t*1.5;bone.location.y=-t*.3
                bone.keyframe_insert('rotation_euler',frame=frame);bone.keyframe_insert('location',frame=frame)
        track=arm.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,action);track.mute=True
    arm.animation_data.action=None
    for track in arm.animation_data.nla_tracks:track.mute=False
    bpy.context.scene.render.fps=24;bpy.context.scene.frame_set(1);a.export('ally_'+kind,True)

if __name__=='__main__':
    weapons()
    for kind in ['hound','mole','bee','wisp']:companion(kind)
    print('ARSENAL ASSETS COMPLETE',flush=True)
