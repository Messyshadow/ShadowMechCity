"""Original, reusable Blender architecture for the seven regions."""
import os, sys, math
import bpy
sys.path.insert(0,os.path.dirname(__file__))
import build_assets as a

def arch(name,radius,mat,center=3.5):
    for i in range(17):
        angle=math.pi*i/16
        o=a.box(name,(math.cos(angle)*radius,0,center+math.sin(angle)*radius),(.47,.62,.44),mat,bevel=.055)
        o.rotation_euler.y=math.pi/2-angle

for kind in ['gantry','rock_wall','culvert','gothic_arch','station_clock','void_ring','banner','lamp']:
    a.begin()
    if kind=='gantry':
        for x in [-3.8,3.8]:
            a.box('Steel stanchion',(x,0,3.8),(.35,.5,7.6),a.steel)
            for z in [.12,3.0,7.4]:a.box('Bolted collar',(x,0,z),(.53,.62,.19),a.brass)
        a.box('Overhead beam',(0,0,7.6),(8.2,.6,.48),a.steel)
        for x in [-3,-2,-1,0,1,2,3]:
            o=a.box('Truss diagonal',(x,0,6.95),(1.5,.12,.12),a.brass);o.rotation_euler.y=.55 if x%2 else -.55
        a.box('Service cable',(0,-.31,7.31),(7.6,.05,.055),a.dark)
    elif kind=='rock_wall':
        for i in range(16):
            x=(i%4-1.5)*1.6;z=(i//4)*1.5
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,.0,z))
            o=bpy.context.object;o.scale=(1.3,.9,1.3);o.rotation_euler=(i*.7,i*.4,i*.9)
            bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
            a.finish(o,'Fractured basalt',a.stone)
    elif kind in ('culvert','gothic_arch'):
        r=2.2 if kind=='culvert' else 2.7;h=2.4 if kind=='culvert' else 4.2
        for x in [-r,r]:
            a.box('Masonry pier',(x,0,h*.5),(.5,.7,h),a.stone)
            for z in [.1,h*.45,h-.1]:a.box('Capital',(x,0,z),(.68,.86,.18),a.edge)
        arch('Voussoir',r,a.stone,h)
        if kind=='gothic_arch':
            a.box('Window lancet',(0,.13,3.7),(.085,.07,5.2),a.brass)
            for x in [-1,1]:a.box('Window mullion',(x,.13,3.4),(.055,.07,4.6),a.brass)
            for z in [1.3,3.1,4.7]:a.box('Window brace',(0,.12,z),(3.4,.06,.07),a.brass)
    elif kind in ('station_clock','void_ring'):
        a.torus('Outer machine rim',(0,0,0),1.45,.095,a.brass,'Y')
        a.torus('Inner ring',(0,.04,0),1.24,.035,a.edge,'Y')
        for i in range(12):
            t=i*math.tau/12
            o=a.box('Dial index',(math.cos(t)*1.29,-.08,math.sin(t)*1.29),(.06,.04,.19),a.cyan if kind=='station_clock' else a.violet);o.rotation_euler.y=math.pi/2-t
        if kind=='station_clock':
            a.cyl('Dial',(0,.1,0),1.25,.07,a.dark,axis='Y',verts=48)
            a.box('Hour hand',(.2,-.12,.28),(.06,.04,.85),a.brass).rotation_euler.y=.6
            a.box('Minute hand',(-.36,-.11,.1),(.85,.04,.045),a.edge)
        else:
            for i in range(6):
                t=i*math.tau/6;o=a.box('Orbit shard',(math.cos(t)*1.7,0,math.sin(t)*1.7),(.3,.22,.4),a.dark);o.rotation_euler.y=-t
    elif kind=='banner':
        a.box('Crossbar',(0,0,0),(1.6,.09,.08),a.brass)
        a.box('Hanging cloth',(0,.02,-1.1),(1.25,.04,2.2),a.cloth)
        a.box('Emblem stripe',(0,-.02,-1.1),(.16,.02,1.7),a.brass)
        a.cyl('Emblem',(0,-.05,-.75),.31,.03,a.brass,axis='Y')
        a.cyl('Emblem center',(0,-.072,-.75),.21,.02,a.dark,axis='Y')
    else:
        a.box('Wall mount',(0,.1,0),(.24,.25,.48),a.dark)
        a.cyl('Lamp cap',(0,-.15,.2),.22,.09,a.brass)
        a.cyl('Lamp glass',(0,-.15,-.02),.14,.4,a.orange)
        a.cyl('Lamp base',(0,-.15,-.25),.20,.08,a.brass)
        for x in [-.17,.17]:a.box('Glass guard',(x,-.15,-.02),(.045,.26,.45),a.dark)
    a.export(kind)
print('REGIONAL ARCHITECTURE BUILD COMPLETE',flush=True)
